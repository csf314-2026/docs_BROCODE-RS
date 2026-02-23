import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Color getHeatmapColor(int count) {
    if (count == 0) return Colors.green.shade50;
    if (count == 1) return Colors.green.shade300;
    if (count == 2) return Colors.amber.shade300;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Student Workload Heatmap",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Visualizing scheduled quizzes.",
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Text("Something went wrong");
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                Map<DateTime, int> quizCounts = {};
                for (var doc in snapshot.data!.docs) {
                  try {
                    Timestamp t = doc['date_&_time']; 
                    DateTime d = t.toDate();
                    DateTime normalized = DateTime(d.year, d.month, d.day);
                    quizCounts[normalized] = (quizCounts[normalized] ?? 0) + 1;
                  } catch (e) {
                    // Ignore bad data
                  }
                }

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2023),
                      lastDay: DateTime.utc(2030),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, _) {
                          DateTime normalized = DateTime(day.year, day.month, day.day);
                          int count = quizCounts[normalized] ?? 0;
                          return Container(
                            margin: const EdgeInsets.all(4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: getHeatmapColor(count),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${day.day}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: count > 1 ? Colors.white : Colors.black87)),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}