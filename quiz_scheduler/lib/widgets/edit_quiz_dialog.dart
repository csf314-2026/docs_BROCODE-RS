import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditQuizDialog extends StatefulWidget {
  final String quizId;
  final Map<String, dynamic> currentData;

  const EditQuizDialog({
    super.key,
    required this.quizId,
    required this.currentData,
  });

  @override
  State<EditQuizDialog> createState() => _EditQuizDialogState();
}

class _EditQuizDialogState extends State<EditQuizDialog> {
  late DateTime editDate;
  late TimeOfDay editTime;
  late double editDuration;
  late TextEditingController titleController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    DateTime currentDateTime = (widget.currentData['date_&_time'] as Timestamp).toDate();
    editDate = currentDateTime;
    editTime = TimeOfDay.fromDateTime(currentDateTime);
    editDuration = (widget.currentData['duration'] ?? 60).toDouble();
    titleController = TextEditingController(text: widget.currentData['title']);
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (titleController.text.isEmpty) return;
    setState(() => isSaving = true);
    
    try {
      DateTime finalDateTime = DateTime(editDate.year, editDate.month, editDate.day, editTime.hour, editTime.minute);
      
      await FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId).update({
        'title': titleController.text.trim(),
        'date_&_time': Timestamp.fromDate(finalDateTime),
        'duration': editDuration.toInt(),
      });
      
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz updated successfully!"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Modify Quiz", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B3C5D))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Quiz Title",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(DateFormat('EEE, MMM d, y').format(editDate)),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), alignment: Alignment.centerLeft),
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context, initialDate: editDate, firstDate: DateTime.now(), lastDate: DateTime(2030)
                );
                if (picked != null) setState(() => editDate = picked);
              },
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              icon: const Icon(Icons.access_time),
              label: Text(editTime.format(context)),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), alignment: Alignment.centerLeft),
              onPressed: () async {
                TimeOfDay? picked = await showTimePicker(context: context, initialTime: editTime);
                if (picked != null) setState(() => editTime = picked);
              },
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Duration:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${editDuration.toInt()} mins", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B3C5D))),
              ],
            ),
            Slider(
              value: editDuration, min: 15, max: 240, divisions: 15,
              activeColor: const Color(0xFF0B3C5D),
              onChanged: (val) => setState(() => editDuration = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _saveChanges,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B3C5D), foregroundColor: Colors.white),
          child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Save Changes"),
        ),
      ],
    );
  }
}