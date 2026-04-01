import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarHeatmap extends StatelessWidget {
  final String? selectedCourseId;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime selected, DateTime focused) onDaySelected;

  const CalendarHeatmap({
    super.key,
    required this.selectedCourseId,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  // --- STYLING LOGIC ---
  Color _getDayColor(int maxStudentLoad, DateTime day) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    if (day.isBefore(today)) return Colors.grey.shade300;
    if (maxStudentLoad == 0) return Colors.green.shade400; 
    if (maxStudentLoad <= 2) return Colors.amber.shade400; 
    return Colors.red.shade400; 
  }

  // --- NEW: BOUNDARY LOGIC ---
  BoxBorder? _getEventBorder(DateTime day, Map<DateTime, String> eventMap) {
    DateTime normalized = DateTime(day.year, day.month, day.day);
    String? type = eventMap[normalized];
    
    if (type == 'midsem' || type == 'endsem') {
      return Border.all(color: Colors.red, width: 2.5);
    } else if (type == 'holiday') {
      return Border.all(color: const Color(0xFF0B3C5D), width: 2.5);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
      builder: (context, quizSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('events').snapshots(),
          builder: (context, eventSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('courses', arrayContains: selectedCourseId).snapshots(),
              builder: (context, studentSnapshot) {
                if (!quizSnapshot.hasData || !studentSnapshot.hasData || !eventSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 1. Process Heatmap Data
                Map<DateTime, int> dailyMaxLoad = {};
                Map<String, List<DateTime>> courseSchedules = {};
                for (var doc in quizSnapshot.data!.docs) {
                  DateTime d = (doc['date_&_time'] as Timestamp).toDate();
                  String cId = doc['course_id'];
                  DateTime dateKey = DateTime(d.year, d.month, d.day);
                  if (!courseSchedules.containsKey(cId)) courseSchedules[cId] = [];
                  courseSchedules[cId]!.add(dateKey);
                }

                for (var student in studentSnapshot.data!.docs) {
                  List<dynamic> studentCourses = student['courses'] ?? [];
                  Map<DateTime, int> studentLoad = {};
                  for (var enrolledCourse in studentCourses) {
                    if (courseSchedules.containsKey(enrolledCourse)) {
                      for (var quizDate in courseSchedules[enrolledCourse]!) {
                        studentLoad[quizDate] = (studentLoad[quizDate] ?? 0) + 1;
                      }
                    }
                  }
                  studentLoad.forEach((date, load) {
                    if (load > (dailyMaxLoad[date] ?? 0)) dailyMaxLoad[date] = load;
                  });
                }

                // 2. NEW: Process Events Data for Boundaries
                Map<DateTime, String> eventMap = {};
                for (var doc in eventSnapshot.data!.docs) {
                  DateTime start = (doc['date_start'] as Timestamp).toDate();
                  DateTime end = (doc['date_end'] as Timestamp).toDate();
                  String type = doc['type']; // holiday, midsem, endsem
                  
                  // Fill all dates in the range
                  for (int i = 0; i <= end.difference(start).inDays; i++) {
                    DateTime d = start.add(Duration(days: i));
                    eventMap[DateTime(d.year, d.month, d.day)] = type;
                  }
                }

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2023),
                      lastDay: DateTime.utc(2030),
                      focusedDay: focusedDay,
                      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                      onDaySelected: onDaySelected,
                      rowHeight: 45,
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, _) {
                          DateTime normalized = DateTime(day.year, day.month, day.day);
                          return Container(
                            margin: const EdgeInsets.all(4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _getDayColor(dailyMaxLoad[normalized] ?? 0, normalized),
                              borderRadius: BorderRadius.circular(8),
                              border: _getEventBorder(day, eventMap), // NEW BOUNDARY
                            ),
                            child: Text('${day.day}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        },
                        selectedBuilder: (context, day, _) {
                          DateTime normalized = DateTime(day.year, day.month, day.day);
                          return Container(
                            margin: const EdgeInsets.all(4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _getDayColor(dailyMaxLoad[normalized] ?? 0, normalized),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF0B3C5D), width: 3.5), // Active Selection
                            ),
                            child: Text('${day.day}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}