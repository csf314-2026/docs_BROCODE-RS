import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3C5D), // Institutional blue
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // =========================
                  // App Logo / Icon
                  // =========================
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.event_note,
                      size: 70,
                      color: Color(0xFF0B3C5D),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =========================
                  // App Title
                  // =========================
                  const Text(
                    "Quiz Scheduler",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
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

                  // =========================
                  // Info Card
                  // =========================
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white24,
                      ),
                    ),
                    child: const Column(
                      children: [

                        Text(
                          "Centralized Quiz Scheduling System",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          "Avoid evaluation clashes • Visualize workload • Plan better",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // =========================
                  // Google Sign In Button
                  // =========================
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        // TODO: Google Auth Logic (Firebase SSO)
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          // Image.network(
                          //   "https://developers.google.com/identity/images/g-logo.png",
                          //   height: 24,
                          // ),

                          const SizedBox(width: 12),

                          const Text(
                            "Continue with Google",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =========================
                  // Domain Restriction Hint
                  // =========================
                  const Text(
                    "Use your @bits-goa.ac.in account",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // =========================
                  // Footer
                  // =========================
                  const Text(
                    "Faculty • Students • Admin",
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
      ),
    );
  }
}
