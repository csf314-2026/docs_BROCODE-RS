import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border; // <--- FIX IS HERE
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

  // --- 1. GENERIC UPLOAD FUNCTION ---
  Future<void> _uploadExcel(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          isUploading = true;
          statusMessage = "Parsing $type file...";
        });

        var bytes = result.files.single.bytes;
        var excel = Excel.decodeBytes(bytes!);
        String sheetName = excel.tables.keys.first;
        var table = excel.tables[sheetName];

        if (table == null) throw "No data found in sheet";

        int count = 0;
        // Skip header row (rowIndex 0), start from 1
        for (int i = 1; i < table.maxRows; i++) {
          var row = table.rows[i];
          if (row.isEmpty) continue;

          if (type == 'users') await _processUserRow(row);
          if (type == 'courses') await _processCourseRow(row);
          if (type == 'quizzes') await _processQuizRow(row);
          
          count++;
        }

        setState(() {
          statusMessage = "✅ Successfully uploaded $count $type!";
          isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = "❌ Error: $e";
        isUploading = false;
      });
    }
  }

  // --- 2. ROW PROCESSORS ---
  Future<void> _processUserRow(List<Data?> row) async {
    if (row.isEmpty) return;
    String email = row[0]?.value.toString().trim() ?? "";
    String role = (row.length > 1) ? row[1]?.value.toString().trim() ?? "student" : "student";
    String coursesRaw = (row.length > 2) ? row[2]?.value.toString().trim() ?? "" : "";

    if (email.isEmpty) return;

    List<String> courseList = coursesRaw.isNotEmpty 
        ? coursesRaw.split(',').map((e) => e.trim()).toList() 
        : [];

    await FirebaseFirestore.instance.collection('users').doc(email).set({
      'role': role,
      'courses': courseList,
    }, SetOptions(merge: true));
  }

  Future<void> _processCourseRow(List<Data?> row) async {
    if (row.length < 3) return;
    String id = row[0]?.value.toString().trim() ?? "";
    String name = row[1]?.value.toString().trim() ?? "";
    String profEmail = row[2]?.value.toString().trim() ?? "";

    if (id.isEmpty) return;

    await FirebaseFirestore.instance.collection('courses').doc(id).set({
      'course_name': name,
      'Professor': FieldValue.arrayUnion([profEmail]),
    }, SetOptions(merge: true));
  }

  Future<void> _processQuizRow(List<Data?> row) async {
    if (row.length < 4) return;
    String title = row[0]?.value.toString().trim() ?? "Quiz";
    String courseId = row[1]?.value.toString().trim() ?? "";
    String dateStr = row[2]?.value.toString().trim() ?? "";
    String timeStr = row[3]?.value.toString().trim() ?? "";
    String durationStr = (row.length > 4) ? row[4]?.value.toString().trim() ?? "60" : "60";

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
                const Text("Upload Excel files (.xlsx) to populate the database.", 
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 30),

                // --- INSTRUCTIONS ---
                _buildFormatCard("Users File Format", Icons.people, Colors.blue, 
                  "Columns: email, role, courses\n\nExample:\n"
                  "A2: student@bits.ac.in\n"
                  "B2: student\n"
                  "C2: CSF111, MATHF111"
                ),
                _buildFormatCard("Courses File Format", Icons.book, Colors.green, 
                  "Columns: course_id, course_name, professor_email\n\nExample:\n"
                  "A2: CSF111\n"
                  "B2: Computer Programming\n"
                  "C2: prof@bits.ac.in"
                ),
                _buildFormatCard("Quizzes File Format", Icons.access_time, Colors.orange, 
                  "Columns: title, course_id, date, time, duration\n\nExample:\n"
                  "A2: Midsem Exam\n"
                  "B2: CSF111\n"
                  "C2: 2026-03-15\n"
                  "D2: 14:00\n"
                  "E2: 90"
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
                      // The error was happening here with Border.all
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
        onPressed: isUploading ? null : () => _uploadExcel(type),
      ),
    );
  }
}