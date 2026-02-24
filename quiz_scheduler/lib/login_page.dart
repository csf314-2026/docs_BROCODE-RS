import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'faculty_dashboard.dart';
import 'student_dashboard.dart';
import 'admin_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;

  // BITS Pilani Official Blue Color
  final Color bitsBlue = const Color(0xFF003366);

  // --- STANDARD LOGIN LOGIC ---
  Future<void> handleLogin() async {
    setState(() => isLoading = true);

    try {
      User? user = await AuthService().signInWithGoogle();

      if (user != null && mounted) {
        String email = user.email!;

        // 1. Check Professor
        var professorQuery = await FirebaseFirestore.instance
            .collection('courses')
            .where('Professor', arrayContains: email)
            .limit(1)
            .get();

        if (!mounted) return;

        if (professorQuery.docs.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => FacultyDashboard(user: user)),
          );
        }
        // 2. Check Student
        else if (email.endsWith('@goa.bits-pilani.ac.in')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StudentDashboard(user: user)),
          );
        } else {
          await FirebaseAuth.instance.signOut();
          _showError("Access Denied: Only BITS Goa accounts allowed.");
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- ADMIN LOGIN LOGIC ---
  Future<void> handleAdminLogin() async {
    setState(() => isLoading = true);

    try {
      User? user = await AuthService().signInWithGoogle();

      if (user != null && mounted) {
        DocumentSnapshot accessDoc = await FirebaseFirestore.instance
            .collection('app_settings')
            .doc('access_control')
            .get();

        List<dynamic> admins = [];
        if (accessDoc.exists) {
          admins = accessDoc['admin_emails'] ?? [];
        }

        if (admins.contains(user.email)) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminDashboard(user: user)),
          );
        } else {
          await FirebaseAuth.instance.signOut();
          _showError("Access Denied: You are not an Admin.");
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Very light grey background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- CARD CONTAINER ---
              Container(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                ), // Max width for desktop look
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      // 1. LOGO & HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // BITS Logo from URL
                          Image.network(
                            "https://quantaaws.bits-goa.ac.in/pluginfile.php/1/core_admin/logo/0x200/1662896397/logo.png", // Official Wiki Logo
                            height: 80,
                            width: 80,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback if internet fails
                              return Icon(
                                Icons.school,
                                size: 80,
                                color: bitsBlue,
                              );
                            },
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "BITS Pilani",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: bitsBlue,
                                  fontFamily: 'Serif',
                                ),
                              ),
                              Text(
                                "K K Birla Goa Campus",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                      const Divider(),
                      const SizedBox(height: 30),

                      // 2. APP NAME
                      const Text(
                        "Evals-BPGC",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "view-schedule-analyze",
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 1.5,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 3. LOGIN SECTION (Right side of your screenshot style)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Log in using your account on:",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // GOOGLE BUTTON (Styled like screenshot)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFEEEEEE,
                            ), // Light Grey
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                          onPressed: isLoading ? null : handleLogin,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Google "G" Icon
                                    Image.network(
                                      "https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg",
                                      height: 20,
                                      errorBuilder: (c, o, s) =>
                                          const Icon(Icons.login, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      "Google",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 4. ADMIN LOGIN (Subtle Link)
                      TextButton(
                        onPressed: isLoading ? null : handleAdminLogin,
                        child: Text(
                          "Admin Login",
                          style: TextStyle(
                            color: bitsBlue,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "© 2026 BITS Pilani, K K Birla Goa Campus",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
