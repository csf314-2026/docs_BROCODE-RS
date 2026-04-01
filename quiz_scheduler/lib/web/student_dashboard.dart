import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../login_page.dart';

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

    bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(isMobile ? "Student Dashboard" : "BITS Goa | Student Dashboard",
            style: const TextStyle(color: Color(0xFF0B3C5D), fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF0B3C5D),
              radius: 16,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(firstName.isNotEmpty ? firstName[0] : "S", style: const TextStyle(color: Colors.white, fontSize: 14))
                  : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 24),
            tooltip: "Logout",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            },
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderTitle(isMobile),
                      const SizedBox(height: 16),
                      _buildToggleContainer(),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeaderTitle(isMobile),
                      _buildToggleContainer(),
                    ],
                  ),
                  
                SizedBox(height: isMobile ? 20 : 30),

                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(widget.user.email).snapshots(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.hasError) return const Text("Error loading student profile.");
                      if (userSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return _buildEmptyState("Profile not found in database. Contact Admin.", Icons.error_outline, isMobile);
                      }

                      List<dynamic> myCourses = userSnapshot.data!['courses'] ?? [];

                      if (myCourses.isEmpty) {
                        return _buildEmptyState("You are not enrolled in any courses yet.", Icons.school, isMobile);
                      }

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
                            
                            if (myCourses.contains(courseId)) {
                              DateTime quizTime = (doc['date_&_time'] as Timestamp).toDate();
                              if (quizTime.isAfter(now)) {
                                upcomingQuizzes.add(doc);
                              } else {
                                pastQuizzes.add(doc);
                              }
                            }
                          }

                          pastQuizzes = pastQuizzes.reversed.toList();
                          List<QueryDocumentSnapshot> displayedQuizzes = _showUpcoming ? upcomingQuizzes : pastQuizzes;

                          if (displayedQuizzes.isEmpty) {
                            return _buildEmptyState(
                              _showUpcoming ? "Hooray! No upcoming quizzes right now." : "No past quizzes found.", 
                              _showUpcoming ? Icons.celebration : Icons.history,
                              isMobile
                            );
                          }

                          return ListView.builder(
                            itemCount: displayedQuizzes.length,
                            itemBuilder: (context, index) {
                              var data = displayedQuizzes[index].data() as Map<String, dynamic>;
                              return _buildQuizCard(data, isUpcoming: _showUpcoming, isMobile: isMobile);
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

  Widget _buildHeaderTitle(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("My Schedule", style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF0B3C5D))),
        Text("View your registered course assessments.", style: TextStyle(color: Colors.black54, fontSize: isMobile ? 14 : 16)),
      ],
    );
  }

  Widget _buildToggleContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, 
        children: [
          _buildToggleButton("Upcoming", true),
          _buildToggleButton("Past", false),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isUpcomingButton) {
    bool isSelected = _showUpcoming == isUpcomingButton;
    return GestureDetector(
      onTap: () => setState(() => _showUpcoming = isUpcomingButton),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B3C5D) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> data, {required bool isUpcoming, required bool isMobile}) {
    // Current Data
    Timestamp? ts = data['date_&_time'];
    DateTime date = ts != null ? ts.toDate() : DateTime.now();
    String formattedDate = DateFormat('EEE, MMM d, y').format(date);
    String formattedTime = DateFormat('h:mm a').format(date);
    
    String title = data['title'] ?? "Quiz";
    String courseName = data['course_name'] ?? "Unknown Course";
    String courseId = data['course_id'] ?? "---";
    int duration = data['duration'] ?? 60;

    // --- NEW: MODIFICATION UI LOGIC ---
    bool isModified = data['is_modified'] ?? false;
    String? oldTitle = isModified ? data['previous_title'] : null;
    String? oldDate;
    String? oldTime;
    String? oldDur;

    if (isModified && data['previous_date_&_time'] != null) {
      DateTime oD = (data['previous_date_&_time'] as Timestamp).toDate();
      oldDate = DateFormat('EEE, MMM d, y').format(oD);
      oldTime = DateFormat('h:mm a').format(oD);
      oldDur = "${data['previous_duration']} mins";
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
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
                  child: Icon(Icons.menu_book, color: isUpcoming ? const Color(0xFF0B3C5D) : Colors.grey, size: isMobile ? 24 : 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show crossed-out old title if changed
                      if (isModified && oldTitle != null && oldTitle != title)
                        Text(
                          oldTitle, 
                          style: TextStyle(
                            color: Colors.red.shade300, 
                            decoration: TextDecoration.lineThrough, 
                            fontSize: 13, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      Text(
                        "$title : $courseName",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 18, color: isUpcoming ? Colors.black87 : Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        courseId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: isMobile ? 13 : 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isMobile ? 10 : 15),
            const Divider(),
            SizedBox(height: isMobile ? 10 : 15),

            Wrap(
              spacing: 15, 
              runSpacing: 10, 
              children: [
                _InfoChip(
                  icon: Icons.calendar_today, 
                  label: formattedDate, 
                  oldLabel: (oldDate != null && oldDate != formattedDate) ? oldDate : null
                ),
                _InfoChip(
                  icon: Icons.access_time, 
                  label: formattedTime, 
                  oldLabel: (oldTime != null && oldTime != formattedTime) ? oldTime : null
                ),
                _InfoChip(
                  icon: Icons.timer, 
                  label: "$duration mins", 
                  oldLabel: (oldDur != null && oldDur != "$duration mins") ? oldDur : null
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isMobile ? 50 : 70, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? oldLabel; // Support for strikethrough labels

  const _InfoChip({required this.icon, required this.label, this.oldLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min, 
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        if (oldLabel != null) ...[
          Text(
            oldLabel!, 
            style: TextStyle(
              color: Colors.red.shade300, 
              decoration: TextDecoration.lineThrough, 
              fontSize: 12
            )
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
        ],
        Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}