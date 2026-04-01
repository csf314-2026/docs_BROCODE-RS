import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login_page.dart';

// --- Imports for our new modules ---
import '../services/csv_upload_service.dart';
import '../widgets/admin_format_card.dart';
import '../widgets/admin_upload_button.dart';

class AdminDashboard extends StatefulWidget {
  final User user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool isUploading = false;
  String statusMessage = "";
  final CsvUploadService _csvService = CsvUploadService();

  Future<void> _handleUpload(String type) async {
    setState(() {
      isUploading = true;
      statusMessage = "Parsing $type file...";
    });

    // Delegate logic to the Service Layer
    String resultMessage = await _csvService.uploadCSV(type, widget.user.email!);

    // If result is empty, the user canceled the file picker
    if (resultMessage.isEmpty && mounted) {
      setState(() {
        isUploading = false;
        statusMessage = "";
      });
      return;
    }

    if (mounted) {
      setState(() {
        statusMessage = resultMessage;
        isUploading = false;
      });
    }
  }

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
                const AdminFormatCard(
                  title: "Users File Format", 
                  icon: Icons.people, 
                  color: Colors.blue, 
                  details: "Columns: email, role, courses\n\nExample:\n"
                           "student@bits.ac.in, student, \"CSF111, MATHF111\"\n"
                           "prof@bits.ac.in, admin, "
                ),
                const AdminFormatCard(
                  title: "Courses File Format", 
                  icon: Icons.book, 
                  color: Colors.green, 
                  details: "Columns: course_id, course_name, professor_email\n\nExample:\n"
                           "CSF111, Computer Programming, prof@bits.ac.in\n"
                           "MATHF111, Mathematics I, mathprof@bits.ac.in"
                ),
                const AdminFormatCard(
                  title: "Quizzes File Format", 
                  icon: Icons.access_time, 
                  color: Colors.orange, 
                  details: "Columns: title, course_id, date, time, duration\n\nExample:\n"
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
                    AdminUploadButton(
                      label: "Upload Users", 
                      icon: Icons.people, 
                      color: Colors.blue,
                      isUploading: isUploading,
                      onPressed: () => _handleUpload('users')
                    ),
                    AdminUploadButton(
                      label: "Upload Courses", 
                      icon: Icons.book, 
                      color: Colors.green,
                      isUploading: isUploading,
                      onPressed: () => _handleUpload('courses')
                    ),
                    AdminUploadButton(
                      label: "Upload Quizzes", 
                      icon: Icons.access_time, 
                      color: Colors.orange,
                      isUploading: isUploading,
                      onPressed: () => _handleUpload('quizzes')
                    ),
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
}