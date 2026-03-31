import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ViewQuizzesView extends StatefulWidget {
  final User user;
  const ViewQuizzesView({super.key, required this.user});

  @override
  State<ViewQuizzesView> createState() => _ViewQuizzesViewState();
}

class _ViewQuizzesViewState extends State<ViewQuizzesView> {
  bool _showUpcoming = true; 

  // --- EDIT DIALOG ---
  void _showEditDialog(String quizId, Map<String, dynamic> currentData) {
    DateTime currentDateTime = (currentData['date_&_time'] as Timestamp).toDate();
    DateTime editDate = currentDateTime;
    TimeOfDay editTime = TimeOfDay.fromDateTime(currentDateTime);
    double editDuration = (currentData['duration'] ?? 60).toDouble();
    TextEditingController titleController = TextEditingController(text: currentData['title']);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                        if (picked != null) setStateDialog(() => editDate = picked);
                      },
                    ),
                    const SizedBox(height: 10),

                    OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(editTime.format(context)),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), alignment: Alignment.centerLeft),
                      onPressed: () async {
                        TimeOfDay? picked = await showTimePicker(context: context, initialTime: editTime);
                        if (picked != null) setStateDialog(() => editTime = picked);
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
                      onChanged: (val) => setStateDialog(() => editDuration = val),
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
                  onPressed: isSaving ? null : () async {
                    if (titleController.text.isEmpty) return;
                    setStateDialog(() => isSaving = true);
                    
                    try {
                      DateTime finalDateTime = DateTime(editDate.year, editDate.month, editDate.day, editTime.hour, editTime.minute);
                      
                      await FirebaseFirestore.instance.collection('quizzes').doc(quizId).update({
                        'title': titleController.text.trim(),
                        'date_&_time': Timestamp.fromDate(finalDateTime),
                        'duration': editDuration.toInt(),
                      });
                      
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz updated successfully!"), backgroundColor: Colors.green));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                      setStateDialog(() => isSaving = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B3C5D), foregroundColor: Colors.white),
                  child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Save Changes"),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER & TOGGLE ---
          // FIX: Explicit Stack on mobile to prevent overflow
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderTitle(isMobile),
                const SizedBox(height: 16),
                _buildToggleContainer(),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeaderTitle(isMobile),
                _buildToggleContainer(),
              ],
            ),
            
          SizedBox(height: isMobile ? 20 : 30),

          // --- FETCH & FILTER DATA ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .where('Professor', arrayContains: widget.user.email)
                  .snapshots(),
              builder: (context, courseSnapshot) {
                if (courseSnapshot.hasError) return const Text("Error loading courses");
                if (courseSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                List<String> myCourseIds = courseSnapshot.data!.docs.map((doc) => doc.id).toList();

                if (myCourseIds.isEmpty) {
                  return _buildEmptyState("You are not listed as a professor for any courses.", Icons.school, isMobile);
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('quizzes')
                      .where('course_id', whereIn: myCourseIds)
                      .orderBy('date_&_time', descending: false)
                      .snapshots(),
                  builder: (context, quizSnapshot) {
                    if (quizSnapshot.hasError) return Text("Error: ${quizSnapshot.error}");
                    if (quizSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    var allQuizzes = quizSnapshot.data!.docs;
                    
                    DateTime now = DateTime.now();
                    List<QueryDocumentSnapshot> upcomingQuizzes = [];
                    List<QueryDocumentSnapshot> pastQuizzes = [];

                    for (var doc in allQuizzes) {
                      DateTime quizTime = (doc['date_&_time'] as Timestamp).toDate();
                      if (quizTime.isAfter(now)) {
                        upcomingQuizzes.add(doc);
                      } else {
                        pastQuizzes.add(doc);
                      }
                    }

                    pastQuizzes = pastQuizzes.reversed.toList();
                    List<QueryDocumentSnapshot> displayedQuizzes = _showUpcoming ? upcomingQuizzes : pastQuizzes;

                    if (displayedQuizzes.isEmpty) {
                      return _buildEmptyState(
                        _showUpcoming ? "No upcoming quizzes scheduled." : "No past quizzes found.", 
                        _showUpcoming ? Icons.event_available : Icons.history,
                        isMobile
                      );
                    }

                    return ListView.builder(
                      itemCount: displayedQuizzes.length,
                      itemBuilder: (context, index) {
                        var data = displayedQuizzes[index].data() as Map<String, dynamic>;
                        return _buildQuizCard(data, displayedQuizzes[index].id, isUpcoming: _showUpcoming, isMobile: isMobile);
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

  // --- UI HELPERS ---

  Widget _buildHeaderTitle(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("My Quizzes", style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text("Manage your scheduled assessments.", style: TextStyle(color: Colors.black54, fontSize: isMobile ? 14 : 16)),
      ],
    );
  }

  Widget _buildToggleContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton("Upcoming", true),
          _buildToggleButton("Past", false),
        ],
      ),
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

  Widget _buildQuizCard(Map<String, dynamic> data, String quizId, {required bool isUpcoming, required bool isMobile}) {
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
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 16, color: isUpcoming ? Colors.black87 : Colors.grey.shade700)
                      ),
                    ],
                  ),
                ),

                if (isUpcoming) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                    constraints: const BoxConstraints(), // Reduces default padding around icon
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tooltip: "Modify Quiz",
                    onPressed: () => _showEditDialog(quizId, data),
                  ),

                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    tooltip: "Delete Quiz",
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

  Widget _buildEmptyState(String message, IconData icon, bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isMobile ? 50 : 60, color: Colors.grey[300]),
            const SizedBox(height: 15),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: isMobile ? 14 : 16)),
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