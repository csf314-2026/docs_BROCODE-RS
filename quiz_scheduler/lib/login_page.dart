import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'faculty_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  bool isLoading = false;

  // ==========================================================
  // GOOGLE LOGIN HANDLER
  // ==========================================================
  Future<void> handleLogin() async {

    setState(() => isLoading = true);

    try {

      var user =
          await AuthService().signInWithGoogle();

      if (user != null) {

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const FacultyDashboard(),
          ),
        );
      }

    } catch (e) {

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Access Denied"),
          content: const Text(
            "Only @goa.bits-pilani.ac.in faculty "
            "or authorized admins can log in.",
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );

    } finally {
      setState(() => isLoading = false);
    }
  }

  // ==========================================================
  // UI
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3C5D),

      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [

                // ==========================
                // APP LOGO / ICON
                // ==========================
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.event_note,
                    size: 70,
                    color: Color(0xFF0B3C5D),
                  ),
                ),

                const SizedBox(height: 30),

                // ==========================
                // TITLE
                // ==========================
                const Text(
                  "Quiz Scheduler",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "BITS Pilani • KK Birla Goa Campus",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 50),

                // ==========================
                // INFO CARD
                // ==========================
                Container(
                  padding:
                      const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white24,
                    ),
                  ),
                  child: const Column(
                    children: [

                      Text(
                        "Centralized Quiz Scheduling System",
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        "Avoid evaluation clashes • Visualize workload • Plan better",
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // ==========================
                // GOOGLE LOGIN BUTTON
                // ==========================
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.white,
                      foregroundColor:
                          Colors.black87,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(12),
                      ),
                      elevation: 4,
                    ),

                    onPressed:
                        isLoading
                            ? null
                            : handleLogin,

                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [

                              Image.asset(
                                "google_logo.png",
                                height: 24,
                              ),

                              const SizedBox(
                                  width: 12),

                              const Text(
                                "Continue with Google",
                                style:
                                    TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==========================
                // DOMAIN HINT
                // ==========================
                const Text(
                  "Use your @goa.bits-pilani.ac.in account",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  "Faculty • Admin Access",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
