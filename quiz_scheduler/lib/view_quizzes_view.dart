import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Add intl dependency for formatting

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

          // 1. First, get the courses THIS professor teaches
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

                // Get list of Course IDs (e.g., ['CSF111', 'MATHF111'])
                List<String> myCourseIds = courseSnapshot.data!.docs
                    .map((doc) => doc.id)
                    .toList();

                if (myCourseIds.isEmpty) {
                  return _buildEmptyState("You are not listed as a professor for any courses.");
                }

                // 2. Now, fetch quizzes ONLY for these courses
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('quizzes')
                      .where('course_id', whereIn: myCourseIds) // Filter by my courses
                      .orderBy('date_&_time', descending: false) // Show upcoming first
                      .snapshots(),
                  builder: (context, quizSnapshot) {
                    if (quizSnapshot.hasError) return Text("Error: ${quizSnapshot.error}");
                    if (quizSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var quizzes = quizSnapshot.data!.docs;

                    if (quizzes.isEmpty) {
                      return _buildEmptyState("No quizzes scheduled for your courses yet.");
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
    // Parse Date
    Timestamp? ts = data['date_&_time'];
    DateTime date = ts != null ? ts.toDate() : DateTime.now();
    String formattedDate = DateFormat('EEE, MMM d, y').format(date);
    String formattedTime = DateFormat('h:mm a').format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B3C5D).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.assignment, color: Color(0xFF0B3C5D)),
        ),
        title: Text(
          data['course_id'] ?? "Unknown Course",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text("$formattedDate at $formattedTime", style: TextStyle(color: Colors.grey[600])),
              const SizedBox(width: 15),
              Icon(Icons.timer, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text("${data['duration'] ?? 60} mins", style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () {
            // Optional: Add Delete functionality directly here
            FirebaseFirestore.instance.collection('quizzes').doc(quizId).delete();
          },
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