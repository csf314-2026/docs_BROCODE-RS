import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DashboardView extends StatefulWidget {
  final User user;
  const DashboardView({super.key, required this.user});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  
  String? _selectedCourseId; 
  String? _selectedCourseName;

  // Form State
  final TextEditingController _titleController = TextEditingController();
  TimeOfDay? _selectedTime;
  double _durationMinutes = 60;
  bool _isSubmitting = false;

  // Track selected free slots
  List<DateTime> _selectedSlotStarts = [];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // --- COLOR LOGIC ---
  Color getDayColor(int maxStudentLoad, DateTime day) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    if (day.isBefore(today)) return Colors.grey.shade300;
    if (maxStudentLoad == 0) return Colors.green.shade400; 
    if (maxStudentLoad <= 2) return Colors.amber.shade400; 
    return Colors.red.shade400; 
  }

  // --- HANDLE SLOT SELECTION ---
  void _handleSlotSelection(DateTime slot, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedSlotStarts.add(slot);
      } else {
        _selectedSlotStarts.remove(slot);
      }

      if (_selectedSlotStarts.isNotEmpty) {
        _selectedSlotStarts.sort();
        
        bool isContiguous = true;
        for (int i = 0; i < _selectedSlotStarts.length - 1; i++) {
          if (_selectedSlotStarts[i + 1].difference(_selectedSlotStarts[i]).inHours != 1) {
            isContiguous = false; 
            break;
          }
        }

        if (!isContiguous) {
          if (isSelected) {
            _selectedSlotStarts = [slot];
          } else {
            _selectedSlotStarts.clear();
          }
        }
      }

      if (_selectedSlotStarts.isNotEmpty) {
        _selectedTime = TimeOfDay.fromDateTime(_selectedSlotStarts.first);
        _durationMinutes = (_selectedSlotStarts.length * 60.0).clamp(15.0, 240.0);
      } else {
        _selectedTime = null;
        _durationMinutes = 60;
      }
    });
  }

  // --- SUBMIT & ADVANCED CONFLICT LOGIC ---
  Future<void> submitQuiz() async {
    if (_selectedCourseId == null || _selectedTime == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields."), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      DateTime proposedStart = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, _selectedTime!.hour, _selectedTime!.minute);
      DateTime proposedEnd = proposedStart.add(Duration(minutes: _durationMinutes.toInt()));

      // =================================================================
      // 1. GLOBAL STUDENT CONFLICT CHECK
      // =================================================================
      
      // Step A: Initialize conflict scope with the current course (in case it has 0 students)
      Set<String> overlappingCourses = {_selectedCourseId!};

      // Step B: Find all students enrolled in this specific course
      var studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('courses', arrayContains: _selectedCourseId)
          .get();

      // Step C: Build a list of every single course these students are taking
      for (var student in studentsSnapshot.docs) {
        List<dynamic> studentCourses = student['courses'] ?? [];
        for (var c in studentCourses) {
          overlappingCourses.add(c.toString());
        }
      }

      // Step D: Fetch all quizzes happening on the selected day
      DateTime startOfDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      var dayQuizzesSnapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('date_&_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date_&_time', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      bool hasConflict = false;
      String conflictMessage = "";

      // Step E: Check if any of today's quizzes belong to our students' courses AND overlap in time
      for (var doc in dayQuizzesSnapshot.docs) {
        String quizCourseId = doc['course_id'];

        // Only check for time overlap if the quiz belongs to a course our students are taking
        if (overlappingCourses.contains(quizCourseId)) {
          DateTime existingStart = (doc['date_&_time'] as Timestamp).toDate();
          int existingDuration = doc['duration'] ?? 60;
          DateTime existingEnd = existingStart.add(Duration(minutes: existingDuration));

          // Mathematical Overlap Logic: (Start A < End B) AND (End A > Start B)
          if (proposedStart.isBefore(existingEnd) && proposedEnd.isAfter(existingStart)) {
            hasConflict = true;
            String startStr = DateFormat('h:mm a').format(existingStart); // e.g., 9:00 AM
            String endStr = DateFormat('h:mm a').format(existingEnd);     // e.g., 10:00 AM
            
            conflictMessage = "$quizCourseId has a quiz from $startStr to $endStr.";
            break; // Stop checking after the first conflict is found
          }
        }
      }

      // Step F: Block scheduling if a conflict is found
      if (hasConflict) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 10), Text("Student Conflict Detected")]),
            content: Text("Cannot schedule. Students in your course have a scheduling conflict:\n\n$conflictMessage\n\nPlease choose a different time slot."),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
          )
        );
        setState(() => _isSubmitting = false);
        return; // Abort saving
      }

      // =================================================================
      // 2. SAVE TO DATABASE (If no conflicts)
      // =================================================================
      await FirebaseFirestore.instance.collection('quizzes').add({
        'title': _titleController.text.trim(), 
        'course_id': _selectedCourseId,
        'course_name': _selectedCourseName ?? _selectedCourseId, 
        'date_&_time': Timestamp.fromDate(proposedStart),
        'duration': _durationMinutes.toInt(),
        'created_by': widget.user.email,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz Scheduled Successfully!"), backgroundColor: Colors.green));
      
      setState(() {
        _titleController.clear();
        _selectedTime = null;
        _durationMinutes = 60;
        _selectedSlotStarts.clear();
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Schedule Quiz", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("Select a course and date to view free slots.", style: TextStyle(color: Colors.black54)),
                ],
              ),
              
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('courses').where('Professor', arrayContains: widget.user.email).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  var courses = snapshot.data!.docs;
                  List<DropdownMenuItem<String?>> items = [
                    const DropdownMenuItem(value: null, child: Text("Select a Course")), 
                  ];

                  for (var doc in courses) {
                    var data = doc.data() as Map<String, dynamic>;
                    String name = data['course_name'] ?? doc.id;
                    items.add(DropdownMenuItem(
                      value: doc.id,
                      child: Text(name),
                      onTap: () => _selectedCourseName = name,
                    ));
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedCourseId,
                        hint: const Text("Select Course"),
                        items: items,
                        onChanged: (val) => setState(() {
                          _selectedCourseId = val;
                          _selectedSlotStarts.clear();
                        }),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: _selectedCourseId == null 
              ? const Center(child: Text("Please select a course to continue.", style: TextStyle(color: Colors.grey, fontSize: 16)))
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildHeatmap(),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 5,
                      child: _buildSchedulingPanel(),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
      builder: (context, quizSnapshot) {
        if (!quizSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('courses', arrayContains: _selectedCourseId).snapshots(),
          builder: (context, studentSnapshot) {
            if (!studentSnapshot.hasData) return const Center(child: CircularProgressIndicator());

            Map<DateTime, int> dailyMaxLoad = {};
            Map<String, List<DateTime>> courseSchedules = {};
            
            for (var doc in quizSnapshot.data!.docs) {
              String cId = doc['course_id'];
              DateTime d = (doc['date_&_time'] as Timestamp).toDate();
              DateTime dateKey = DateTime(d.year, d.month, d.day);
              if (!courseSchedules.containsKey(cId)) courseSchedules[cId] = [];
              courseSchedules[cId]!.add(dateKey);
            }

            for(var dates in courseSchedules.values) {
              for(var d in dates) dailyMaxLoad[d] = 0; 
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

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: TableCalendar(
                  firstDay: DateTime.utc(2023),
                  lastDay: DateTime.utc(2030),
                  focusedDay: _focusedDay,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                      _selectedTime = null; 
                      _selectedSlotStarts.clear(); 
                      _durationMinutes = 60;
                    });
                  },
                  rowHeight: 45,
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, _) {
                      DateTime normalized = DateTime(day.year, day.month, day.day);
                      int maxLoad = dailyMaxLoad[normalized] ?? 0;
                      return Container(
                        margin: const EdgeInsets.all(4), alignment: Alignment.center,
                        decoration: BoxDecoration(color: getDayColor(maxLoad, normalized), borderRadius: BorderRadius.circular(8)),
                        child: Text('${day.day}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      );
                    },
                    selectedBuilder: (context, day, _) {
                      DateTime normalized = DateTime(day.year, day.month, day.day);
                      int maxLoad = dailyMaxLoad[normalized] ?? 0;
                      return Container(
                        margin: const EdgeInsets.all(4), alignment: Alignment.center,
                        decoration: BoxDecoration(color: getDayColor(maxLoad, normalized), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF0B3C5D), width: 3)),
                        child: Text('${day.day}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      );
                    },
                    todayBuilder: (context, day, _) {
                       DateTime normalized = DateTime(day.year, day.month, day.day);
                       int maxLoad = dailyMaxLoad[normalized] ?? 0;
                       return Container(
                        margin: const EdgeInsets.all(4), alignment: Alignment.center,
                        decoration: BoxDecoration(color: getDayColor(maxLoad, normalized), shape: BoxShape.circle, border: Border.all(color: Colors.blueAccent, width: 2)),
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

  Widget _buildSchedulingPanel() {
    String formattedDate = DateFormat('EEEE, MMMM d, y').format(_selectedDay);
    DateTime startOfDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formattedDate, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0B3C5D))),
            const SizedBox(height: 15),

            const Text("1-Hour Free Slots (6 AM - 10 PM):", style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("Tap contiguous slots to auto-fill time and duration.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('quizzes')
                    .where('date_&_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                    .where('date_&_time', isLessThan: Timestamp.fromDate(endOfDay))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  List<DateTimeRange> bookedRanges = [];
                  for (var doc in snapshot.data!.docs) {
                    DateTime start = (doc['date_&_time'] as Timestamp).toDate();
                    int duration = doc['duration'] ?? 60;
                    bookedRanges.add(DateTimeRange(start: start, end: start.add(Duration(minutes: duration))));
                  }

                  List<DateTime> freeSlotStarts = [];
                  for (int i = 6; i < 22; i++) {
                    DateTime slotStart = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, i, 0);
                    DateTime slotEnd = slotStart.add(const Duration(hours: 1));
                    
                    bool isFree = true;
                    for (var booked in bookedRanges) {
                      if (slotStart.isBefore(booked.end) && slotEnd.isAfter(booked.start)) {
                        isFree = false;
                        break;
                      }
                    }
                    if (isFree) freeSlotStarts.add(slotStart);
                  }

                  if (freeSlotStarts.isEmpty) {
                    return const Text("No free slots available on this day.", style: TextStyle(color: Colors.red));
                  }

                  return SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: freeSlotStarts.map((slotStart) {
                        bool isSelected = _selectedSlotStarts.contains(slotStart);
                        String label = "${DateFormat('h a').format(slotStart)} - ${DateFormat('h a').format(slotStart.add(const Duration(hours: 1)))}";
                        
                        return FilterChip(
                          label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.green.shade700)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0B3C5D),
                          backgroundColor: Colors.green.shade50,
                          side: BorderSide(color: isSelected ? const Color(0xFF0B3C5D) : Colors.green.shade200),
                          onSelected: (bool selected) => _handleSlotSelection(slotStart, selected),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            
            const Divider(height: 30),

            const Text("Schedule Quiz Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Quiz Title",
                hintText: "e.g., Midsem, Surprise Test",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime == null ? "Select Start Time" : _selectedTime!.format(context)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () async {
                      TimeOfDay? picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                      if (picked != null) {
                        setState(() {
                          _selectedTime = picked;
                          _selectedSlotStarts.clear(); 
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Duration:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${_durationMinutes.toInt()} mins", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B3C5D))),
              ],
            ),
            Slider(
              value: _durationMinutes,
              min: 15, 
              max: 240, 
              divisions: 15,
              activeColor: const Color(0xFF0B3C5D),
              onChanged: (val) {
                setState(() {
                  _durationMinutes = val;
                  _selectedSlotStarts.clear(); 
                });
              },
            ),

            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : submitQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B3C5D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Confirm & Schedule", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}