import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ViewQuizzesView extends StatelessWidget {
  final User user;
  const ViewQuizzesView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("My Course Quizzes",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Upcoming assessments for courses you teach.",
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),

          // 1. Get Courses Taught by Professor
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .where('Professor', arrayContains: user.email)
                  .snapshots(),
              builder: (context, courseSnapshot) {
                if (courseSnapshot.hasError) return const Text("Error loading courses");
                if (courseSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<String> myCourseIds = courseSnapshot.data!.docs
                    .map((doc) => doc.id)
                    .toList();

                if (myCourseIds.isEmpty) {
                  return _buildEmptyState("You are not listed as a professor for any courses.");
                }

                // 2. Get Quizzes for these courses
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('quizzes')
                      .where('course_id', whereIn: myCourseIds)
                      .orderBy('date_&_time', descending: false)
                      .snapshots(),
                  builder: (context, quizSnapshot) {
                    if (quizSnapshot.hasError) return Text("Error: ${quizSnapshot.error}");
                    if (quizSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var quizzes = quizSnapshot.data!.docs;

                    if (quizzes.isEmpty) {
                      return _buildEmptyState("No quizzes scheduled yet.");
                    }

                    return ListView.builder(
                      itemCount: quizzes.length,
                      itemBuilder: (context, index) {
                        var data = quizzes[index].data() as Map<String, dynamic>;
                        return _buildQuizCard(data, quizzes[index].id);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> data, String quizId) {
    // Parse Date & Time
    Timestamp? ts = data['date_&_time'];
    DateTime date = ts != null ? ts.toDate() : DateTime.now();
    String formattedDate = DateFormat('EEE, MMM d, y').format(date);
    String formattedTime = DateFormat('h:mm a').format(date);
    
    // Parse Details (with fallbacks for older data)
    String title = data['title'] ?? "Quiz";
    String courseName = data['course_name'] ?? "Unknown Course";
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
            // HEADER ROW: Icon + "Title : Name : ID" + Delete Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B3C5D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assignment, color: Color(0xFF0B3C5D), size: 24),
                ),
                const SizedBox(width: 12),
                
                // MAIN TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$title : $courseName : $courseId",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),

                // DELETE BUTTON
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    FirebaseFirestore.instance.collection('quizzes').doc(quizId).delete();
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),

            // INFO ROW: Date | Time | Duration
            Row(
              children: [
                _InfoChip(icon: Icons.calendar_today, label: formattedDate),
                const SizedBox(width: 20),
                _InfoChip(icon: Icons.access_time, label: formattedTime),
                const SizedBox(width: 20),
                _InfoChip(icon: Icons.timer, label: "$duration mins"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
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