import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'login_page.dart';

class MobileStudentDashboard extends StatefulWidget {
  final User user;
  const MobileStudentDashboard({super.key, required this.user});

  @override
  State<MobileStudentDashboard> createState() => _MobileStudentDashboardState();
}

class _MobileStudentDashboardState extends State<MobileStudentDashboard> {
  int _currentIndex = 0; // Tracks which tab is active
  bool _showUpcoming = true;

  @override
  Widget build(BuildContext context) {
    String displayName = widget.user.displayName ?? "Student";
    String firstName = displayName.split(" ")[0];
    String? photoUrl = widget.user.photoURL;

    // The list of screens for the BottomNavigationBar
    final List<Widget> screens = [
      _buildScheduleScreen(),
      _buildPlaceholderScreen("Grades & Reports (Coming Soon)", Icons.bar_chart),
      _buildPlaceholderScreen("App Settings", Icons.settings),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      
      // === APP BAR (Mobile Optimized) ===
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text("BITS Goa Evals", style: TextStyle(color: Color(0xFF0B3C5D), fontWeight: FontWeight.bold, fontSize: 18)),
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
        ],
      ),

      // === BODY (Changes based on selected tab) ===
      body: screens[_currentIndex],

      // === BOTTOM NAVIGATION BAR ===
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF0B3C5D),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Schedule"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Grades"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: SCHEDULE VIEW (Ported from Website, stripped of Desktop logic)
  // =========================================================================
  Widget _buildScheduleScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mobile specific vertical header
          const Text("My Schedule", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B3C5D))),
          const Text("View your registered assessments.", style: TextStyle(color: Colors.black54, fontSize: 14)),
          const SizedBox(height: 16),
          
          // Toggle Container
          Container(
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton("Upcoming", true),
                _buildToggleButton("Past", false),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Data List
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(widget.user.email).snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return _buildEmptyState("Profile not found in database. Contact Admin.", Icons.error_outline);
                }

                List<dynamic> myCourses = userSnapshot.data!['courses'] ?? [];
                if (myCourses.isEmpty) return _buildEmptyState("You are not enrolled in any courses yet.", Icons.school);

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('quizzes').orderBy('date_&_time').snapshots(),
                  builder: (context, quizSnapshot) {
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
    );
  }

  // =========================================================================
  // OTHER TABS: PLACEHOLDERS FOR FUTURE FEATURES
  // =========================================================================
  Widget _buildPlaceholderScreen(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

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

  Widget _buildQuizCard(Map<String, dynamic> data, {required bool isUpcoming}) {
    Timestamp? ts = data['date_&_time'];
    DateTime date = ts != null ? ts.toDate() : DateTime.now();
    String formattedDate = DateFormat('EEE, MMM d, y').format(date); 
    String formattedTime = DateFormat('h:mm a').format(date);
    
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUpcoming ? const Color(0xFF0B3C5D).withOpacity(0.1) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.menu_book, color: isUpcoming ? const Color(0xFF0B3C5D) : Colors.grey, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$title : $courseName",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isUpcoming ? Colors.black87 : Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        courseId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),

            Wrap(
              spacing: 15, 
              runSpacing: 10, 
              children: [
                _InfoChip(icon: Icons.calendar_today, label: formattedDate),
                _InfoChip(icon: Icons.access_time, label: formattedTime),
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
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
      mainAxisSize: MainAxisSize.min, 
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}