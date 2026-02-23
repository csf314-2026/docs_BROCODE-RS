import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_view.dart';
import 'schedule_quiz_view.dart';
import 'view_quizzes_view.dart'; // 1. IMPORT THE NEW FILE

class FacultyDashboard extends StatefulWidget {
  final User user;
  const FacultyDashboard({super.key, required this.user});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  int _selectedIndex = 0; 

  @override
  Widget build(BuildContext context) {
    String displayName = widget.user.displayName ?? "Faculty";
    String firstName = displayName.split(" ")[0];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        // ... (Keep your existing AppBar code) ...
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text("BITS Goa | Quiz Scheduler",
            style: TextStyle(color: Color(0xFF0B3C5D), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF0B3C5D)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF0B3C5D),
              child: Text(firstName.isNotEmpty ? firstName[0] : "U", style: const TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 250,
            color: const Color(0xFF0B3C5D),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // 2. DASHBOARD ITEM
                _SidebarItem(
                  icon: Icons.dashboard,
                  text: "Dashboard",
                  isActive: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),

                // 3. NEW "VIEW QUIZZES" ITEM
                _SidebarItem(
                  icon: Icons.list_alt,
                  text: "My Quizzes",
                  isActive: _selectedIndex == 2, // New Index
                  onTap: () => setState(() => _selectedIndex = 2),
                ),

                // 4. SCHEDULE QUIZ ITEM
                _SidebarItem(
                  icon: Icons.edit_calendar,
                  text: "Schedule Quiz",
                  isActive: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ],
            ),
          ),
          
          // MAIN CONTENT SWITCHER
          Expanded(
            child: _buildBody(), 
          ),
        ],
      ),
    );
  }

  // 5. BODY SWITCHER LOGIC
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardView();
      case 1:
        return ScheduleQuizView(user: widget.user);
      case 2:
        return ViewQuizzesView(user: widget.user); // New View
      default:
        return const DashboardView();
    }
  }
}

// ... (Keep your _SidebarItem class at the bottom) ...
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem(
      {required this.icon, required this.text, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}