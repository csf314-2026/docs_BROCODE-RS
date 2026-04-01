import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'edit_quiz_dialog.dart'; // Import our new dialog widget

class FacultyQuizCard extends StatelessWidget {
  final String quizId;
  final Map<String, dynamic> data;
  final bool isUpcoming;
  final bool isMobile;

  const FacultyQuizCard({
    super.key,
    required this.quizId,
    required this.data,
    required this.isUpcoming,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
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
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUpcoming ? const Color(0xFF0B3C5D).withOpacity(0.1) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.assignment, color: isUpcoming ? const Color(0xFF0B3C5D) : Colors.grey, size: 24),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$title : $courseName : $courseId", 
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: isMobile ? 15 : 16, 
                          color: isUpcoming ? Colors.black87 : Colors.grey.shade700
                        )
                      ),
                    ],
                  ),
                ),

                // Edit/Delete Buttons (Only for Upcoming)
                if (isUpcoming) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tooltip: "Modify",
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => EditQuizDialog(quizId: quizId, currentData: data),
                      );
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    tooltip: "Delete",
                    onPressed: () async {
                      bool confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Quiz?"),
                          content: const Text("This action cannot be undone."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                          ],
                        )
                      ) ?? false;
                      
                      if (confirm) {
                        FirebaseFirestore.instance.collection('quizzes').doc(quizId).delete();
                      }
                    },
                  ),
                ]
              ],
            ),
            
            SizedBox(height: isMobile ? 10 : 15),
            const Divider(),
            SizedBox(height: isMobile ? 10 : 15),

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
        Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}