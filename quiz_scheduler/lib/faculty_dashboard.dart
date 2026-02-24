import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_view.dart';
import 'schedule_quiz_view.dart';
import 'view_quizzes_view.dart';
import 'login_page.dart';

class FacultyDashboard extends StatefulWidget {
  final User user;
  const FacultyDashboard({super.key, required this.user});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  int _selectedIndex = 0;

  // === RESPONSIVE LOGIC ===
  // If width > 900, we consider it "Desktop/Wide"
  bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 900;

  @override
  Widget build(BuildContext context) {
    String displayName = widget.user.displayName ?? "Faculty";
    String firstName = displayName.split(" ")[0];
    String? photoUrl = widget.user.photoURL;

    // 1. CONTENT SWITCHER
    Widget content;
    switch (_selectedIndex) {
      case 0:
        // Pass user to DashboardView for the "My Courses" filter
        content = DashboardView(user: widget.user); 
        break;
      case 1:
        content = ScheduleQuizView(user: widget.user);
        break;
      case 2:
        content = ViewQuizzesView(user: widget.user);
        break;
      default:
        content = DashboardView(user: widget.user);
    }

    // 2. BUILD UI
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      
      // === APP BAR ===
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        // Hide Hamburger on Desktop (Sidebar is visible)
        leading: isDesktop(context) 
            ? null 
            : Builder(builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF0B3C5D)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              )),
        title: const Text("BITS Goa | Quiz Scheduler",
            style: TextStyle(color: Color(0xFF0B3C5D), fontWeight: FontWeight.bold)),
        actions: [
          // User Avatar
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF0B3C5D),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(firstName.isNotEmpty ? firstName[0] : "U", style: const TextStyle(color: Colors.white))
                  : null,
            ),
          ),
          // Logout Button
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

      // === DRAWER (Mobile Only) ===
      drawer: isDesktop(context) ? null : Drawer(
        child: _SidebarContent(
          selectedIndex: _selectedIndex,
          onItemTapped: (index) {
            setState(() => _selectedIndex = index);
            Navigator.pop(context); // Close drawer
          },
        ),
      ),

      // === BODY ===
      body: Row(
        children: [
          // SIDEBAR (Desktop Only)
          if (isDesktop(context))
            Container(
              width: 260,
              color: const Color(0xFF0B3C5D),
              child: _SidebarContent(
                selectedIndex: _selectedIndex,
                onItemTapped: (index) => setState(() => _selectedIndex = index),
              ),
            ),

          // MAIN CONTENT AREA
          Expanded(
            child: content,
          ),
        ],
      ),
    );
  }
}

// === EXTRACTED SIDEBAR WIDGETS ===
class _SidebarContent extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const _SidebarContent({required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B3C5D),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _SidebarItem(
            icon: Icons.dashboard,
            text: "Dashboard",
            isActive: selectedIndex == 0,
            onTap: () => onItemTapped(0),
          ),
          _SidebarItem(
            icon: Icons.edit_calendar,
            text: "Schedule Quiz",
            isActive: selectedIndex == 1,
            onTap: () => onItemTapped(1),
          ),
          _SidebarItem(
            icon: Icons.list_alt,
            text: "My Quizzes",
            isActive: selectedIndex == 2,
            onTap: () => onItemTapped(2),
          ),
        ],
      ),
    );
  }
}

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