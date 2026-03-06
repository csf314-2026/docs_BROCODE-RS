import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'login_page.dart';

class StudentDashboard extends StatefulWidget {
  final User user;
  const StudentDashboard({super.key, required this.user});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool _showUpcoming = true;

  @override
  Widget build(BuildContext context) {
    String displayName = widget.user.displayName ?? "Student";
    String firstName = displayName.split(" ")[0];
    String? photoUrl = widget.user.photoURL;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      
      // === APP BAR ===
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text("BITS Goa | Student Dashboard",
            style: TextStyle(color: Color(0xFF0B3C5D), fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF0B3C5D),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(firstName.isNotEmpty ? firstName[0] : "S", style: const TextStyle(color: Colors.white))
                  : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Logout",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      // === BODY ===
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900), // Keeps it readable on desktop
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER & TOGGLE ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("My Schedule", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0B3C5D))),
                        Text("View your registered course assessments.", style: TextStyle(color: Colors.black54, fontSize: 16)),
                      ],
                    ),
                    
                    // Toggle Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _buildToggleButton("Upcoming", true),
                          _buildToggleButton("Past", false),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 30),

                // --- DATA FETCHING ---
                Expanded(
                  // 1. Get the Student's enrolled courses from 'users' collection
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(widget.user.email).snapshots(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.hasError) return const Text("Error loading student profile.");
                      if (userSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return _buildEmptyState("Profile not found in database. Contact Admin.", Icons.error_outline);
                      }

                      List<dynamic> myCourses = userSnapshot.data!['courses'] ?? [];

                      if (myCourses.isEmpty) {
                        return _buildEmptyState("You are not enrolled in any courses yet.", Icons.school);
                      }

                      // 2. Get all quizzes and filter locally 
                      // (Safer than 'whereIn' which is limited to 10 courses)
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('quizzes').orderBy('date_&_time').snapshots(),
                        builder: (context, quizSnapshot) {
                          if (quizSnapshot.hasError) return const Text("Error loading quizzes.");
                          if (quizSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                          DateTime now = DateTime.now();
                          List<QueryDocumentSnapshot> upcomingQuizzes = [];
                          List<QueryDocumentSnapshot> pastQuizzes = [];

                          for (var doc in quizSnapshot.data!.docs) {
                            String courseId = doc['course_id'];
                            
                            // Only process if the student is in this course
                            if (myCourses.contains(courseId)) {
                              DateTime quizTime = (doc['date_&_time'] as Timestamp).toDate();
                              if (quizTime.isAfter(now)) {
                                upcomingQuizzes.add(doc);
                              } else {
                                pastQuizzes.add(doc);
                              }
                            }
                          }

                          // Sort Past Quizzes so most recent is at the top
                          pastQuizzes = pastQuizzes.reversed.toList();

                          List<QueryDocumentSnapshot> displayedQuizzes = _showUpcoming ? upcomingQuizzes : pastQuizzes;

                          if (displayedQuizzes.isEmpty) {
                            return _buildEmptyState(
                              _showUpcoming ? "Hooray! No upcoming quizzes right now." : "No past quizzes found.", 
                              _showUpcoming ? Icons.celebration : Icons.history
                            );
                          }

                          return ListView.builder(
                            itemCount: displayedQuizzes.length,
                            itemBuilder: (context, index) {
                              var data = displayedQuizzes[index].data() as Map<String, dynamic>;
                              return _buildQuizCard(data, isUpcoming: _showUpcoming);
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
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildToggleButton(String label, bool isUpcomingButton) {
    bool isSelected = _showUpcoming == isUpcomingButton;
    return GestureDetector(
      onTap: () => setState(() => _showUpcoming = isUpcomingButton),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B3C5D) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> data, {required bool isUpcoming}) {
    Timestamp? ts = data['date_&_time'];
    DateTime date = ts != null ? ts.toDate() : DateTime.now();
    String formattedDate = DateFormat('EEEE, MMMM d, y').format(date);
    String formattedTime = DateFormat('h:mm a').format(date);
    
    String title = data['title'] ?? "Quiz";
    String courseName = data['course_name'] ?? "Unknown Course";
    String courseId = data['course_id'] ?? "---";
    int duration = data['duration'] ?? 60;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUpcoming ? const Color(0xFF0B3C5D).withOpacity(0.1) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.menu_book, color: isUpcoming ? const Color(0xFF0B3C5D) : Colors.grey, size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$title : $courseName",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isUpcoming ? Colors.black87 : Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        courseId,
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 15),

            Row(
              children: [
                _InfoChip(icon: Icons.calendar_today, label: formattedDate),
                const SizedBox(width: 25),
                _InfoChip(icon: Icons.access_time, label: formattedTime),
                const SizedBox(width: 25),
                _InfoChip(icon: Icons.timer, label: "$duration mins"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
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
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}