import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart'; 
import 'login_page.dart';

class AdminDashboard extends StatefulWidget {
  final User user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool isUploading = false;
  String statusMessage = "";

  // --- NEW FIX: Safe Cell Extractor for dynamic CSV data ---
  String _safeGetCellValue(dynamic cell, {String defaultValue = ""}) {
    if (cell == null) return defaultValue;
    String value = cell.toString().trim();
    return value.isEmpty ? defaultValue : value;
  }

  // --- 1. GENERIC UPLOAD FUNCTION (Now using CSV) ---
  Future<void> _uploadCSV(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, 
        withData: true,
      );

      if (result != null) {
        setState(() {
          isUploading = true;
          statusMessage = "Parsing $type file...";
        });

        String fileName = result.files.single.name.toLowerCase();
        // Check for CSV extension instead of XLSX
        if (!fileName.endsWith('.csv')) {
          setState(() {
            statusMessage = "❌ Error: Please select a valid .csv file.";
            isUploading = false;
          });
          return;
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
            if (type == 'quizzes') await _processQuizRow(row);
            
            count++;
          } catch (rowError) {
            skipped++;
            continue; 
          }
        }

        setState(() {
          statusMessage = skipped > 0 
              ? "✅ Uploaded $count $type! (Skipped $skipped corrupted rows)"
              : "✅ Successfully uploaded $count $type!";
          isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = "❌ System Error: $e";
        isUploading = false;
      });
    }
  }

  // --- 2. ROW PROCESSORS ---
  Future<void> _processUserRow(List<dynamic> row) async {
    if (row.isEmpty) return;
    
    // Safely extract values
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

  Future<void> _processQuizRow(List<dynamic> row) async {
    if (row.length < 4) return;

    String title = _safeGetCellValue(row.isNotEmpty ? row[0] : null, defaultValue: "Quiz");
    String courseId = _safeGetCellValue(row.length > 1 ? row[1] : null);
    String dateStr = _safeGetCellValue(row.length > 2 ? row[2] : null);
    String timeStr = _safeGetCellValue(row.length > 3 ? row[3] : null);
    String durationStr = _safeGetCellValue(row.length > 4 ? row[4] : null, defaultValue: "60");

    if (courseId.isEmpty) return;

    DateTime date;
    try { date = DateTime.parse(dateStr); } catch(e) { date = DateTime.now(); }

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
      'created_by': widget.user.email,
    });
  }

  // --- 3. UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Bulk Data Upload", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0B3C5D))),
                const SizedBox(height: 10),
                const Text("Upload CSV files (.csv) to populate the database.", 
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 30),

                // --- INSTRUCTIONS ---
                _buildFormatCard("Users File Format", Icons.people, Colors.blue, 
                  "Columns: email, role, courses\n\nExample:\n"
                  "student@bits.ac.in, student, \"CSF111, MATHF111\"\n"
                  "prof@bits.ac.in, admin, "
                ),
                _buildFormatCard("Courses File Format", Icons.book, Colors.green, 
                  "Columns: course_id, course_name, professor_email\n\nExample:\n"
                  "CSF111, Computer Programming, prof@bits.ac.in\n"
                  "MATHF111, Mathematics I, mathprof@bits.ac.in"
                ),
                _buildFormatCard("Quizzes File Format", Icons.access_time, Colors.orange, 
                  "Columns: title, course_id, date, time, duration\n\nExample:\n"
                  "Midsem Exam, CSF111, 2026-03-15, 14:00, 90\n"
                  "Quiz 1, MATHF111, 2026-04-10, 09:00, 30"
                ),

                const SizedBox(height: 40),

                // --- ACTION BUTTONS ---
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildUploadButton("Upload Users", Icons.people, 'users', Colors.blue),
                    _buildUploadButton("Upload Courses", Icons.book, 'courses', Colors.green),
                    _buildUploadButton("Upload Quizzes", Icons.access_time, 'quizzes', Colors.orange),
                  ],
                ),

                const SizedBox(height: 40),
                
                // --- STATUS MESSAGE ---
                if (isUploading) 
                  const Center(child: CircularProgressIndicator())
                else if (statusMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: statusMessage.startsWith("✅") ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusMessage.startsWith("✅") ? Colors.green : Colors.red),
                    ),
                    child: Text(statusMessage, textAlign: TextAlign.center, 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, 
                        color: statusMessage.startsWith("✅") ? Colors.green.shade800 : Colors.red.shade800)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormatCard(String title, IconData icon, Color color, String details) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            color: Colors.grey.shade50,
            child: Text(details, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(String label, IconData icon, String type, Color color) {
    return SizedBox(
      width: 220,
      height: 50,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: isUploading ? null : () => _uploadCSV(type),
      ),
    );
  }
}