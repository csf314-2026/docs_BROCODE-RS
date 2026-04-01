import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Imports for our new modules ---
import '../../services/quiz_scheduling_service.dart';
import '../../widgets/calendar_heatmap.dart';
import '../../widgets/scheduling_panel.dart';
import '../../widgets/event_details_list.dart'; // Import the new widget

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
  bool _isSubmitting = false;

  final QuizSchedulingService _schedulingService = QuizSchedulingService();
  final GlobalKey<SchedulingPanelState> _panelKey = GlobalKey<SchedulingPanelState>();

  Future<void> _handleQuizSubmission(String title, TimeOfDay time, double durationMinutes) async {
    if (_selectedCourseId == null) return;
    setState(() => _isSubmitting = true);

    try {
      DateTime proposedStart = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, time.hour, time.minute);
      DateTime proposedEnd = proposedStart.add(Duration(minutes: durationMinutes.toInt()));

      ScheduleResult validationResult = await _schedulingService.validateSchedule(
        courseId: _selectedCourseId!,
        proposedStart: proposedStart,
        proposedEnd: proposedEnd,
        selectedDay: _selectedDay,
      );

      if (validationResult.status == ScheduleStatus.timeConflict) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 10), Text("Time Conflict Detected")]),
            content: Text("Cannot schedule. Students in your course have an overlapping schedule:\n\n${validationResult.message}\n\nPlease choose a different time slot."),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
          )
        );
        return; 
      }

      if (validationResult.status == ScheduleStatus.workloadWarning) {
        if (!mounted) return;
        bool? proceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange), SizedBox(width: 10), Text("High Workload Warning")]),
            content: Text("Some students in your course already have ${validationResult.maxWorkload} quizzes scheduled on this day.\n\nAre you sure you want to schedule another assessment for them?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                child: const Text("Schedule Anyway"),
              ),
            ],
          )
        );
        if (proceed != true) return; 
      }

      await _schedulingService.saveQuiz(
        courseId: _selectedCourseId!,
        title: title,
        startTime: proposedStart,
        durationMinutes: durationMinutes.toInt(),
        creatorEmail: widget.user.email!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz Scheduled Successfully!"), backgroundColor: Colors.green));
      _panelKey.currentState?.clearForm();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth >= 850;
        bool isMobile = constraints.maxWidth < 768;

        return Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderTitle(isMobile),
                    const SizedBox(height: 16),
                    _buildCourseDropdown(),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeaderTitle(isMobile),
                    _buildCourseDropdown(),
                  ],
                ),

              SizedBox(height: isMobile ? 20 : 30),

              Expanded(
                child: _selectedCourseId == null 
                  ? Center(child: Text("Please select a course to continue.", style: TextStyle(color: Colors.grey, fontSize: isMobile ? 14 : 16)))
                  : isWideScreen 
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4, 
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    CalendarHeatmap(
                                       selectedCourseId: _selectedCourseId,
                                       focusedDay: _focusedDay,
                                       selectedDay: _selectedDay,
                                       onDaySelected: (selected, focused) => setState(() {
                                         _selectedDay = selected;
                                         _focusedDay = focused;
                                       })
                                    ),
                                    const SizedBox(height: 15),
                                    EventDetailsList(selectedDay: _selectedDay), // Event list appears below calendar
                                  ],
                                ),
                              )
                            ),
                            const SizedBox(width: 20),
                            Expanded(flex: 5, child: SchedulingPanel(
                              key: _panelKey,
                              isMobile: isMobile,
                              selectedDay: _selectedDay,
                              selectedCourseId: _selectedCourseId,
                              isSubmitting: _isSubmitting,
                              onSubmit: _handleQuizSubmission,
                            )),
                          ],
                        )
                      : SingleChildScrollView( 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CalendarHeatmap(
                               selectedCourseId: _selectedCourseId,
                               focusedDay: _focusedDay,
                               selectedDay: _selectedDay,
                               onDaySelected: (selected, focused) => setState(() {
                                 _selectedDay = selected;
                                 _focusedDay = focused;
                               })
                              ),
                              const SizedBox(height: 15),
                              EventDetailsList(selectedDay: _selectedDay),
                              const SizedBox(height: 20),
                              SchedulingPanel(
                                key: _panelKey,
                                isMobile: isMobile,
                                selectedDay: _selectedDay,
                                selectedCourseId: _selectedCourseId,
                                isSubmitting: _isSubmitting,
                                onSubmit: _handleQuizSubmission,
                              ),
                              const SizedBox(height: 40), 
                            ],
                          ),
                        ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildHeaderTitle(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Schedule Quiz", style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold)),
        Text("Select a course and date to view free slots.", style: TextStyle(color: Colors.black54, fontSize: isMobile ? 14 : 16)),
      ],
    );
  }

  Widget _buildCourseDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('courses').where('Professor', arrayContains: widget.user.email).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var courses = snapshot.data!.docs;
        List<DropdownMenuItem<String?>> items = [
          const DropdownMenuItem(value: null, child: Text("Select a Course")), 
        ];
        for (var doc in courses) {
          var data = doc.data() as Map<String, dynamic>;
          items.add(DropdownMenuItem(value: doc.id, child: Text(data['course_name'] ?? doc.id, overflow: TextOverflow.ellipsis)));
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedCourseId,
              hint: const Text("Select Course"),
              items: items,
              onChanged: (val) => setState(() => _selectedCourseId = val),
            ),
          ),
        );
      },
    );
  }
}