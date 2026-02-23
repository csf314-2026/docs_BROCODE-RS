import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class ScheduleQuizView extends StatefulWidget {
  final User user;
  const ScheduleQuizView({super.key, required this.user});

  @override
  State<ScheduleQuizView> createState() => _ScheduleQuizViewState();
}

class _ScheduleQuizViewState extends State<ScheduleQuizView> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _titleController = TextEditingController(); // NEW: Title Controller

  String? selectedCourseId;
  String? selectedCourseName; // NEW: To store the name for saving
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  double durationMinutes = 60; 
  bool isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> submitQuiz() async {
    if (selectedCourseId == null || selectedDate == null || selectedTime == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all fields, including Quiz Title."), backgroundColor: Colors.red));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      DateTime finalDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // 1. CHECK CONFLICTS
      String? conflictError = await _firestoreService.checkConflict(
        selectedCourseId!, 
        finalDateTime, 
        durationMinutes.toInt() 
      );

      if (conflictError != null) {
        if (!mounted) return;
        showDialog(
          context: context, 
          builder: (_) => AlertDialog(
            title: const Text("Scheduling Conflict"),
            content: Text(conflictError),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
          )
        );
        return; 
      }

      // 2. SAVE TO FIRESTORE
      // We save 'course_name' and 'title' directly here to make the Student Dashboard faster.
      await FirebaseFirestore.instance.collection('quizzes').add({
        'title': _titleController.text.trim(), // NEW
        'course_id': selectedCourseId,
        'course_name': selectedCourseName ?? selectedCourseId, // NEW
        'date_&_time': Timestamp.fromDate(finalDateTime),
        'duration': durationMinutes.toInt(),
        'created_by': widget.user.email,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Quiz Scheduled Successfully!"), backgroundColor: Colors.green));
      
      // Reset Form
      setState(() {
        _titleController.clear();
        selectedCourseId = null;
        selectedCourseName = null;
        selectedDate = null;
        selectedTime = null;
        durationMinutes = 60;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Schedule a New Quiz",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),

          // --- 1. COURSE SELECTION ---
          const Text("Select Course", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getProfessorCourses(widget.user.email!),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              var courses = snapshot.data!.docs;
              
              if (courses.isEmpty) return const Text("No courses found.", style: TextStyle(color: Colors.red));

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedCourseId,
                    hint: const Text("Choose a course"),
                    items: courses.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String name = data['course_name'] ?? doc.id;
                      
                      return DropdownMenuItem(
                        value: doc.id, 
                        child: Text("$name (${doc.id})"),
                        onTap: () {
                          // Capture the name when selected
                          selectedCourseName = name;
                        },
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedCourseId = val),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // --- 2. QUIZ TITLE (NEW) ---
          const Text("Quiz Title", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: "e.g., Quiz 1, Midsem, Surprise Test",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),

          // --- 3. DATE & TIME ---
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Date", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(selectedDate == null ? "Select Date" : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.centerLeft,
                         minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Start Time", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(selectedTime == null ? "Select Time" : selectedTime!.format(context)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.centerLeft,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () async {
                        TimeOfDay? picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                        if (picked != null) setState(() => selectedTime = picked);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),

          // --- 4. DURATION SLIDER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Duration", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("${durationMinutes.toInt()} mins", 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B3C5D))),
            ],
          ),
          Slider(
            value: durationMinutes,
            min: 15,
            max: 180,
            divisions: 11,
            label: "${durationMinutes.toInt()} mins",
            activeColor: const Color(0xFF0B3C5D),
            onChanged: (val) => setState(() => durationMinutes = val),
          ),
          
          const SizedBox(height: 40),

          // --- SUBMIT ---
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : submitQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B3C5D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Schedule Quiz", style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}