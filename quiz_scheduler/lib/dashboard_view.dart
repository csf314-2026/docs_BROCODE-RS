import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardView extends StatefulWidget {
  final User user;
  const DashboardView({super.key, required this.user});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedCourseFilter; 

  // --- 1. COLOR LOGIC ---
  Color getDayColor(int maxStudentLoad, DateTime day) {
    // A. Past Days = Grey
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    if (day.isBefore(today)) return Colors.grey.shade300;

    // B. Future Days Logic
    if (maxStudentLoad == 0) return Colors.green.shade400; // Safe
    if (maxStudentLoad <= 2) return Colors.amber.shade400; // Warning
    return Colors.red.shade400; // Danger
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER & FILTER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Student Workload Heatmap", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("Colors indicate the worst-case quiz load for students.", style: TextStyle(color: Colors.black54)),
                ],
              ),
              
              // COURSE FILTER
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .where('Professor', arrayContains: widget.user.email)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  var courses = snapshot.data!.docs;
                  List<DropdownMenuItem<String?>> items = [
                    const DropdownMenuItem(value: null, child: Text("Select a Course")), 
                  ];

                  for (var doc in courses) {
                    var data = doc.data() as Map<String, dynamic>;
                    items.add(DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['course_name'] ?? doc.id),
                    ));
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedCourseFilter,
                        hint: const Text("Select Course to View"),
                        items: items,
                        onChanged: (val) => setState(() => _selectedCourseFilter = val),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- HEATMAP ---
          Expanded(
            child: _selectedCourseFilter == null 
              ? _buildEmptyState() 
              : _buildHeatmap(),
          ),
          
          // --- LEGEND ---
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.green.shade400, "Safe (0)"),
              const SizedBox(width: 15),
              _buildLegendItem(Colors.amber.shade400, "Busy (1-2)"),
              const SizedBox(width: 15),
              _buildLegendItem(Colors.red.shade400, "Conflict (>2)"),
              const SizedBox(width: 15),
              _buildLegendItem(Colors.grey.shade300, "Past"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "Please select a course to analyze student workload.",
        style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // --- COMPLEX LOGIC BUILDER ---
  Widget _buildHeatmap() {
    // 1. Listen to ALL Quizzes (To calculate global load)
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
      builder: (context, quizSnapshot) {
        if (!quizSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        // 2. Listen to STUDENTS of the Selected Course
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('courses', arrayContains: _selectedCourseFilter)
              .snapshots(),
          builder: (context, studentSnapshot) {
            if (!studentSnapshot.hasData) return const Center(child: CircularProgressIndicator());

            // --- 3. THE CALCULATION CORE ---
            // Map<Date, MaxLoad>
            Map<DateTime, int> dailyMaxLoad = {};

            // A. Parse all quizzes into a searchable format
            // Map<CourseID, List<DateTime>>
            Map<String, List<DateTime>> courseSchedules = {};
            
            for (var doc in quizSnapshot.data!.docs) {
              String cId = doc['course_id'];
              Timestamp t = doc['date_&_time'];
              DateTime d = t.toDate();
              DateTime dateKey = DateTime(d.year, d.month, d.day);
              
              if (!courseSchedules.containsKey(cId)) {
                courseSchedules[cId] = [];
              }
              courseSchedules[cId]!.add(dateKey);
            }

            // B. Iterate Students to find the "Worst Case" for each day
            var students = studentSnapshot.data!.docs;
            
            // We scan a reasonable range (e.g., this month + next 2 months) 
            // to populate the calendar. 
            // Optimization: Just iterating the quizzes found is faster.
            
            // Initialize map with 0 load for days where quizzes exist
            for(var dates in courseSchedules.values) {
              for(var d in dates) {
                dailyMaxLoad[d] = 0; 
              }
            }

            // For every student in THIS course...
            for (var student in students) {
              List<dynamic> studentCourses = student['courses'] ?? [];

              // Calculate THIS student's load for every day
              Map<DateTime, int> studentLoad = {};

              for (var enrolledCourse in studentCourses) {
                 if (courseSchedules.containsKey(enrolledCourse)) {
                   for (var quizDate in courseSchedules[enrolledCourse]!) {
                     studentLoad[quizDate] = (studentLoad[quizDate] ?? 0) + 1;
                   }
                 }
              }

              // Update the Global "Worst Case" Map
              studentLoad.forEach((date, load) {
                if (load > (dailyMaxLoad[date] ?? 0)) {
                  dailyMaxLoad[date] = load;
                }
              });
            }

            // --- 4. RENDER CALENDAR ---
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
                      int maxLoad = dailyMaxLoad[normalized] ?? 0;
                      
                      return Container(
                        margin: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: getDayColor(maxLoad, normalized),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${day.day}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                      );
                    },
                    todayBuilder: (context, day, _) {
                       // Ensure today is also colored by logic, but with a circle border
                       DateTime normalized = DateTime(day.year, day.month, day.day);
                       int maxLoad = dailyMaxLoad[normalized] ?? 0;
                       return Container(
                        margin: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: getDayColor(maxLoad, normalized),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0B3C5D), width: 2)
                        ),
                        child: Text('${day.day}', style: const TextStyle(fontWeight: FontWeight.bold)),
                       );
                    }
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}