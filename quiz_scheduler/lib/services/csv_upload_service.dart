import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

class CsvUploadService {
  // --- Safe Cell Extractor for dynamic CSV data ---
  String _safeGetCellValue(dynamic cell, {String defaultValue = ""}) {
    if (cell == null) return defaultValue;
    String value = cell.toString().trim();
    return value.isEmpty ? defaultValue : value;
  }

  // --- GENERIC UPLOAD FUNCTION ---
  // Returns a status message string to display in the UI.
  Future<String> uploadCSV(String type, String adminEmail) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null) return ""; // User canceled the picker

      String fileName = result.files.single.name.toLowerCase();
      
      if (!fileName.endsWith('.csv')) {
        return "❌ Error: Please select a valid .csv file.";
      }

      var bytes = result.files.single.bytes;
      if (bytes == null) throw "Could not read file data. Try again.";

      // Decode the bytes to a string, then parse the CSV
      final String csvString = utf8.decode(bytes);
      final List<List<dynamic>> table = const CsvToListConverter().convert(csvString);

      if (table.isEmpty) throw "No data found in file";

      int count = 0;
      int skipped = 0;

      // Skip header row (rowIndex 0), start from 1
      for (int i = 1; i < table.length; i++) {
        try {
          var row = table[i];
          // Skip completely empty rows
          if (row.every((element) => element.toString().trim().isEmpty)) continue;

          if (type == 'users') await _processUserRow(row);
          if (type == 'courses') await _processCourseRow(row);
          if (type == 'quizzes') await _processQuizRow(row, adminEmail);

          count++;
        } catch (rowError) {
          skipped++;
          continue;
        }
      }

      return skipped > 0
          ? "✅ Uploaded $count $type! (Skipped $skipped corrupted rows)"
          : "✅ Successfully uploaded $count $type!";
          
    } catch (e) {
      return "❌ System Error: $e";
    }
  }

  // --- ROW PROCESSORS ---
  Future<void> _processUserRow(List<dynamic> row) async {
    if (row.isEmpty) return;

    String email = _safeGetCellValue(row.isNotEmpty ? row[0] : null);
    String role = _safeGetCellValue(row.length > 1 ? row[1] : null, defaultValue: "student");
    String coursesRaw = _safeGetCellValue(row.length > 2 ? row[2] : null);

    if (email.isEmpty) return;

    List<String> courseList = coursesRaw.isNotEmpty
        ? coursesRaw.split(',').map((e) => e.trim()).toList()
        : [];

    await FirebaseFirestore.instance.collection('users').doc(email).set({
      'role': role,
      'courses': courseList,
    }, SetOptions(merge: true));
  }

  Future<void> _processCourseRow(List<dynamic> row) async {
    if (row.length < 3) return;

    String id = _safeGetCellValue(row.isNotEmpty ? row[0] : null);
    String name = _safeGetCellValue(row.length > 1 ? row[1] : null);
    String profEmail = _safeGetCellValue(row.length > 2 ? row[2] : null);

    if (id.isEmpty) return;

    await FirebaseFirestore.instance.collection('courses').doc(id).set({
      'course_name': name,
      'Professor': FieldValue.arrayUnion([profEmail]),
    }, SetOptions(merge: true));
  }

  Future<void> _processQuizRow(List<dynamic> row, String adminEmail) async {
    if (row.length < 4) return;

    String title = _safeGetCellValue(row.isNotEmpty ? row[0] : null, defaultValue: "Quiz");
    String courseId = _safeGetCellValue(row.length > 1 ? row[1] : null);
    String dateStr = _safeGetCellValue(row.length > 2 ? row[2] : null);
    String timeStr = _safeGetCellValue(row.length > 3 ? row[3] : null);
    String durationStr = _safeGetCellValue(row.length > 4 ? row[4] : null, defaultValue: "60");

    if (courseId.isEmpty) return;

    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (e) {
      date = DateTime.now();
    }

    TimeOfDay time = const TimeOfDay(hour: 12, minute: 0);
    if (timeStr.contains(":")) {
      var parts = timeStr.split(":");
      time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    DateTime finalDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    var courseDoc = await FirebaseFirestore.instance.collection('courses').doc(courseId).get();
    String courseName = courseDoc.exists ? (courseDoc['course_name'] ?? courseId) : courseId;

    await FirebaseFirestore.instance.collection('quizzes').add({
      'title': title,
      'course_id': courseId,
      'course_name': courseName,
      'date_&_time': Timestamp.fromDate(finalDateTime),
      'duration': int.tryParse(durationStr) ?? 60,
      'created_by': adminEmail,
    });
  }
}