import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'faculty_dashboard.dart';
import 'student_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;

  Future<void> handleLogin() async {
    setState(() => isLoading = true);

    try {
      // 1. Google Login
      User? user = await AuthService().signInWithGoogle();

      if (user != null && mounted) {
        String email = user.email!;

        // ---------------------------------------------------------
        // CHECK 1: IS PROFESSOR? (Database Check)
        // ---------------------------------------------------------
        // We query the 'courses' collection to see if this email is in ANY 'Professor' array.
        var professorQuery = await FirebaseFirestore.instance
            .collection('courses')
            .where('Professor', arrayContains: email)
            .limit(1) // We only need one match
            .get();

        if (!mounted) return;

        if (professorQuery.docs.isNotEmpty) {
          // ✅ ACCESS GRANTED: FACULTY
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => FacultyDashboard(user: user)),
          );
        } 
        // ---------------------------------------------------------
        // CHECK 2: IS STUDENT? (Domain Check)
        // ---------------------------------------------------------
        else if (email.endsWith('@goa.bits-pilani.ac.in')) {
          // ✅ ACCESS GRANTED: STUDENT
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StudentDashboard(user: user)),
          );
        } 
        // ---------------------------------------------------------
        // CHECK 3: ACCESS DENIED
        // ---------------------------------------------------------
        else {
          // ❌ ACCESS DENIED
          await FirebaseAuth.instance.signOut(); // Log them out immediately
          if (!mounted) return;
          
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Access Denied"),
              content: const Text("Only BITS Goa students and registered faculty can access this app."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("OK")
                )
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Login Failed"),
          content: Text(e.toString()),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3C5D),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  height: 120, width: 120,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.event_note, size: 70, color: Color(0xFF0B3C5D)),
                ),
                const SizedBox(height: 30),
                const Text("Quiz Scheduler", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 50),

                // Login Button
                SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isLoading ? null : handleLogin,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login), 
                              SizedBox(width: 12),
                              Text("Continue with Google", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Use your @goa.bits-pilani.ac.in account",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}