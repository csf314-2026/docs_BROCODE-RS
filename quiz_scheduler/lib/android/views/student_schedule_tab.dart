import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../widgets/empty_state_widget.dart';

class StudentScheduleTab extends StatefulWidget {
  final User user;
  const StudentScheduleTab({super.key, required this.user});

  @override
  State<StudentScheduleTab> createState() => _StudentScheduleTabState();
}

class _StudentScheduleTabState extends State<StudentScheduleTab> {
  bool _showUpcoming = true;
  bool _hasSubscribedToTopics = false;

  void _showAlarmDialog(String quizTitle, String courseId, DateTime quizTime) {
    double alarmOffsetMinutes = 15; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.alarm, color: Colors.orange),
                  SizedBox(width: 10),
                  Text("Set Quiz Reminder", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Remind me before $quizTitle ($courseId) starts:", style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 20),
                  Text(
                    "${alarmOffsetMinutes.toInt()} minutes before", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0B3C5D))
                  ),
                  Slider(
                    value: alarmOffsetMinutes,
                    min: 5, max: 120, divisions: 23, 
                    activeColor: const Color(0xFF0B3C5D),
                    onChanged: (val) => setStateDialog(() => alarmOffsetMinutes = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B3C5D), foregroundColor: Colors.white),
                  onPressed: () async {
                    DateTime alarmTime = quizTime.subtract(Duration(minutes: alarmOffsetMinutes.toInt()));
                    
                    if (alarmTime.isBefore(DateTime.now())) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot set an alarm in the past!"), backgroundColor: Colors.red));
                      return;
                    }

                    if (Platform.isAndroid) {
                      final AndroidIntent intent = AndroidIntent(
                        action: 'android.intent.action.SET_ALARM',
                        arguments: <String, dynamic>{
                          'android.intent.extra.alarm.HOUR': alarmTime.hour,
                          'android.intent.extra.alarm.MINUTES': alarmTime.minute,
                          'android.intent.extra.alarm.MESSAGE': 'Quiz: $quizTitle',
                          'android.intent.extra.alarm.SKIP_UI': true, 
                        },
                      );
                      
                      try {
                        await intent.launch();
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Alarm set for ${DateFormat('h:mm a').format(alarmTime)} in your Clock app!"), backgroundColor: Colors.green));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not open Clock app: $e"), backgroundColor: Colors.red));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("System alarms are only supported on Android."), backgroundColor: Colors.orange));
                    }
                  },
                  child: const Text("Set Alarm"),
                ),
              ],
            );
          }
        );
      }
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
                        "$title : $courseName : $courseId",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isUpcoming ? Colors.black87 : Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                if (isUpcoming)
                  IconButton(
                    icon: const Icon(Icons.add_alarm, color: Colors.orange),
                    tooltip: "Set Reminder",
                    onPressed: () => _showAlarmDialog(title, courseId, date),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Wrap(
              spacing: 15, runSpacing: 10, 
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("My Schedule", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B3C5D))),
          const Text("View your registered assessments.", style: TextStyle(color: Colors.black54, fontSize: 14)),
          const SizedBox(height: 16),
          
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

          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(widget.user.email).snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const EmptyStateWidget(message: "Profile not found in database. Contact Admin.", icon: Icons.error_outline);
                }

                List<dynamic> myCourses = userSnapshot.data!['courses'] ?? [];
                
                if (myCourses.isNotEmpty && !_hasSubscribedToTopics) {
                  for (String course in myCourses) {
                    FirebaseMessaging.instance.subscribeToTopic('course_$course');
                  }
                  _hasSubscribedToTopics = true; 
                }

                if (myCourses.isEmpty) return const EmptyStateWidget(message: "You are not enrolled in any courses yet.", icon: Icons.school);

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
                      return EmptyStateWidget(
                        message: _showUpcoming ? "Hooray! No upcoming quizzes right now." : "No past quizzes found.", 
                        icon: _showUpcoming ? Icons.celebration : Icons.history
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
}

// Private helper widget for the chips
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