import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/empty_state_widget.dart';

class StudentCoursesTab extends StatelessWidget {
  final User user;
  const StudentCoursesTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("My Courses", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B3C5D))),
          const Text("View your registered courses.", style: TextStyle(color: Colors.black54, fontSize: 14)),
          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.email).snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const EmptyStateWidget(message: "Profile not found in database. Contact Admin.", icon: Icons.error_outline);
                }

                List<dynamic> myCourses = userSnapshot.data!['courses'] ?? [];
                if (myCourses.isEmpty) {
                  return const EmptyStateWidget(message: "You are not enrolled in any courses yet.", icon: Icons.school);
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('courses').snapshots(),
                  builder: (context, courseSnapshot) {
                    if (courseSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    List<QueryDocumentSnapshot> enrolledCourses = [];
                    for (var doc in courseSnapshot.data!.docs) {
                      if (myCourses.contains(doc.id)) {
                        enrolledCourses.add(doc);
                      }
                    }

                    if (enrolledCourses.isEmpty) {
                      return const EmptyStateWidget(message: "Your enrolled courses could not be found.", icon: Icons.book_outlined);
                    }

                    return ListView.builder(
                      itemCount: enrolledCourses.length,
                      itemBuilder: (context, index) {
                        var data = enrolledCourses[index].data() as Map<String, dynamic>;
                        String courseId = enrolledCourses[index].id;
                        String courseName = data['course_name'] ?? "Unknown Course";
                        
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.book, color: Colors.blueAccent, size: 24),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                                      const SizedBox(height: 4),
                                      Text(courseId, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
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
}