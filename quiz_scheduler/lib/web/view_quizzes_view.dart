import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Imports for our new modules ---
import '../widgets/faculty_quiz_card.dart';

class ViewQuizzesView extends StatefulWidget {
  final User user;
  const ViewQuizzesView({super.key, required this.user});

  @override
  State<ViewQuizzesView> createState() => _ViewQuizzesViewState();
}

class _ViewQuizzesViewState extends State<ViewQuizzesView> {
  bool _showUpcoming = true; 

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER & TOGGLE ---
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

          // --- FETCH & FILTER DATA ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .where('Professor', arrayContains: widget.user.email)
                  .snapshots(),
              builder: (context, courseSnapshot) {
                if (courseSnapshot.hasError) return const Text("Error loading courses");
                if (courseSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                List<String> myCourseIds = courseSnapshot.data!.docs.map((doc) => doc.id).toList();

                if (myCourseIds.isEmpty) {
                  return _buildEmptyState("You are not listed as a professor for any courses.", Icons.school, isMobile);
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('quizzes')
                      .where('course_id', whereIn: myCourseIds)
                      .orderBy('date_&_time', descending: false)
                      .snapshots(),
                  builder: (context, quizSnapshot) {
                    if (quizSnapshot.hasError) return Text("Error: ${quizSnapshot.error}");
                    if (quizSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    var allQuizzes = quizSnapshot.data!.docs;
                    
                    DateTime now = DateTime.now();
                    List<QueryDocumentSnapshot> upcomingQuizzes = [];
                    List<QueryDocumentSnapshot> pastQuizzes = [];

                    for (var doc in allQuizzes) {
                      DateTime quizTime = (doc['date_&_time'] as Timestamp).toDate();
                      if (quizTime.isAfter(now)) {
                        upcomingQuizzes.add(doc);
                      } else {
                        pastQuizzes.add(doc);
                      }
                    }

                    pastQuizzes = pastQuizzes.reversed.toList();
                    List<QueryDocumentSnapshot> displayedQuizzes = _showUpcoming ? upcomingQuizzes : pastQuizzes;

                    if (displayedQuizzes.isEmpty) {
                      return _buildEmptyState(
                        _showUpcoming ? "No upcoming quizzes scheduled." : "No past quizzes found.", 
                        _showUpcoming ? Icons.event_available : Icons.history,
                        isMobile
                      );
                    }

                    return ListView.builder(
                      itemCount: displayedQuizzes.length,
                      itemBuilder: (context, index) {
                        var data = displayedQuizzes[index].data() as Map<String, dynamic>;
                        return FacultyQuizCard(
                          quizId: displayedQuizzes[index].id,
                          data: data,
                          isUpcoming: _showUpcoming,
                          isMobile: isMobile,
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

  // --- UI HELPERS ---

  Widget _buildHeaderTitle(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("My Quizzes", style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text("Manage your scheduled assessments.", style: TextStyle(color: Colors.black54, fontSize: isMobile ? 14 : 16)),
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

  Widget _buildEmptyState(String message, IconData icon, bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isMobile ? 50 : 60, color: Colors.grey[300]),
            const SizedBox(height: 15),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: isMobile ? 14 : 16)),
          ],
        ),
      ),
    );
  }
}