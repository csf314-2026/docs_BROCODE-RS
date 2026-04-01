import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login_page.dart';

// --- Imports for our new modules ---
import 'views/settings_view.dart';
import 'views/student_schedule_tab.dart';
import 'views/student_courses_tab.dart';

class MobileStudentDashboard extends StatefulWidget {
  final User user;
  const MobileStudentDashboard({super.key, required this.user});

  @override
  State<MobileStudentDashboard> createState() => _MobileStudentDashboardState();
}

class _MobileStudentDashboardState extends State<MobileStudentDashboard> {
  int _currentIndex = 0; 

  @override
  Widget build(BuildContext context) {
    String displayName = widget.user.displayName ?? "Student";
    String firstName = displayName.split(" ")[0];
    String? photoUrl = widget.user.photoURL;

    // The list of screens for the BottomNavigationBar
    final List<Widget> screens = [
      StudentScheduleTab(user: widget.user),
      StudentCoursesTab(user: widget.user), 
      SettingsView(user: widget.user), 
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      
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

      body: screens[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF0B3C5D),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Schedule"),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: "Courses"), 
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}