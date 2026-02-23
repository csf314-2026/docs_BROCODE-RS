import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'login_page.dart';

class StudentDashboard extends StatefulWidget {
  final User user;
  const StudentDashboard({super.key, required this.user});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  Widget build(BuildContext context) {
    String displayName = widget.user.displayName ?? "Student";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text("Student Dashboard", 
            style: TextStyle(color: Color(0xFF0B3C5D), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF0B3C5D)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, $displayName 👋", 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Your upcoming assessments:", 
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 20),
            
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                // 1. Get User Enrolled Courses
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.user.email)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const Center(child: Text("User profile not found."));
                  }

                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  List<dynamic> enrolledCourses = userData['courses'] ?? [];

                  if (enrolledCourses.isEmpty) {
                    return const Center(child: Text("You are not enrolled in any courses."));
                  }

                  // 2. Fetch Quizzes
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('quizzes')
                        .where('course_id', whereIn: enrolledCourses)
                        .orderBy('date_&_time', descending: false)
                        .snapshots(),
                    builder: (context, quizSnapshot) {
                      if (quizSnapshot.hasError) return Text("Error: ${quizSnapshot.error}");
                      if (quizSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var quizzes = quizSnapshot.data!.docs;

                      if (quizzes.isEmpty) {
                        return const Center(child: Text("No upcoming quizzes! 🎉"));
                      }

                      return ListView.builder(
                        itemCount: quizzes.length,
                        itemBuilder: (context, index) {
                          var data = quizzes[index].data() as Map<String, dynamic>;
                          return _buildQuizCard(data);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> data) {
    // Parse Date
    Timestamp? ts = data['date_&_time'];
    DateTime date = ts != null ? ts.toDate() : DateTime.now();
    String formattedDate = DateFormat('EEE, MMM d, y').format(date);
    String formattedTime = DateFormat('h:mm a').format(date);
    
    // Parse Details (Handle older data gracefully)
    String title = data['title'] ?? "Quiz";
    String courseName = data['course_name'] ?? "Unknown Subject";
    String courseId = data['course_id'] ?? "---";
    int duration = data['duration'] ?? 60;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER: Quiz1 : Computer Programming : CSF001
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.assignment, color: Color(0xFF0B3C5D), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$title : $courseName : $courseId",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // DETAILS: Date, Time, Duration
            Row(
              children: [
                _InfoChip(icon: Icons.calendar_today, label: formattedDate),
                const SizedBox(width: 15),
                _InfoChip(icon: Icons.access_time, label: formattedTime),
                const SizedBox(width: 15),
                _InfoChip(icon: Icons.timer, label: "$duration mins"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}