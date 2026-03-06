import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_view.dart';
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
  bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 900;

  @override
  Widget build(BuildContext context) {
    String displayName = widget.user.displayName ?? "Faculty";
    String firstName = displayName.split(" ")[0];
    String? photoUrl = widget.user.photoURL;

    // 1. CONTENT SWITCHER (Only 2 Tabs Now)
    Widget content;
    switch (_selectedIndex) {
      case 0:
        content = DashboardView(user: widget.user); // Heatmap + Schedule Form
        break;
      case 1:
        content = ViewQuizzesView(user: widget.user); // My Quizzes List
        break;
      default:
        content = DashboardView(user: widget.user);
    }

    // 2. BUILD UI
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: isDesktop(context) 
            ? null 
            : Builder(builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF0B3C5D)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              )),
        title: const Text("BITS Goa | Quiz Scheduler",
            style: TextStyle(color: Color(0xFF0B3C5D), fontWeight: FontWeight.bold)),
        actions: [
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

      drawer: isDesktop(context) ? null : Drawer(
        child: _SidebarContent(
          selectedIndex: _selectedIndex,
          onItemTapped: (index) {
            setState(() => _selectedIndex = index);
            Navigator.pop(context);
          },
        ),
      ),

      body: Row(
        children: [
          if (isDesktop(context))
            Container(
              width: 260,
              color: const Color(0xFF0B3C5D),
              child: _SidebarContent(
                selectedIndex: _selectedIndex,
                onItemTapped: (index) => setState(() => _selectedIndex = index),
              ),
            ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

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
            icon: Icons.edit_calendar,
            text: "Schedule Quiz",
            isActive: selectedIndex == 0,
            onTap: () => onItemTapped(0),
          ),
          _SidebarItem(
            icon: Icons.list_alt,
            text: "My Quizzes",
            isActive: selectedIndex == 1,
            onTap: () => onItemTapped(1),
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