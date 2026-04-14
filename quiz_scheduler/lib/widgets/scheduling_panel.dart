import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SchedulingPanel extends StatefulWidget {
  final bool isMobile;
  final DateTime selectedDay;
  final String? selectedCourseId;
  final bool isSubmitting;
  final Function(String title, TimeOfDay time, double duration) onSubmit;
  final FirebaseFirestore? firestore;

  const SchedulingPanel({
    super.key,
    required this.isMobile,
    required this.selectedDay,
    required this.selectedCourseId,
    required this.isSubmitting,
    required this.onSubmit,
    this.firestore,
  });

@override
State<SchedulingPanel> createState() => SchedulingPanelState();
}

class SchedulingPanelState extends State<SchedulingPanel> {
  final TextEditingController _titleController = TextEditingController();
  TimeOfDay? _selectedTime;
  double _durationMinutes = 60;
  List<DateTime> _selectedSlotStarts = [];

  @override
  void didUpdateWidget(covariant SchedulingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-clear time/slots if the user selects a new day or new course
    if (oldWidget.selectedDay != widget.selectedDay || oldWidget.selectedCourseId != widget.selectedCourseId) {
      setState(() {
        _selectedTime = null;
        _durationMinutes = 60;
        _selectedSlotStarts.clear();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

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
          _selectedSlotStarts = isSelected ? [slot] : [];
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

  void _submit() {
    if (_selectedTime == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields."), backgroundColor: Colors.red));
      return;
    }
    widget.onSubmit(_titleController.text.trim(), _selectedTime!, _durationMinutes);
  }

  // A helper method exposed to the parent so it can clear the form after success
  void clearForm() {
    setState(() {
      _titleController.clear();
      _selectedTime = null;
      _durationMinutes = 60;
      _selectedSlotStarts.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, MMMM d, y').format(widget.selectedDay);
    DateTime startOfDay = DateTime(widget.selectedDay.year, widget.selectedDay.month, widget.selectedDay.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(widget.isMobile ? 16 : 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formattedDate, style: TextStyle(fontSize: widget.isMobile ? 18 : 20, fontWeight: FontWeight.bold, color: const Color(0xFF0B3C5D))),
            const SizedBox(height: 15),

            Text("1-Hour Free Slots (6 AM - 10 PM):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: widget.isMobile ? 14 : 16)),
            const Text("Tap contiguous slots to auto-fill time and duration.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            
            StreamBuilder<QuerySnapshot>(
              stream: (widget.firestore ?? FirebaseFirestore.instance)
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
                  DateTime slotStart = DateTime(widget.selectedDay.year, widget.selectedDay.month, widget.selectedDay.day, i, 0);
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

                return Wrap(
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
                );
              },
            ),
            
            const Divider(height: 30),

            Text("Schedule Quiz Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: widget.isMobile ? 15 : 16)),
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
              min: 15, max: 240, divisions: 15,
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
                onPressed: widget.isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B3C5D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: widget.isSubmitting 
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