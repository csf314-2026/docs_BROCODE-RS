import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:table_calendar/table_calendar.dart';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FacultyDashboard extends StatefulWidget {
  final User user; // Stores the logged-in user

  const FacultyDashboard({super.key, required this.user});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, int> quizData = {};
  bool isLoading = true;
  String? errorMessage; // To handle "Asset Not Found"

 // ==========================================================
  // LOAD EXCEL DATA (UPDATED PATH)
  // ==========================================================
  Future<void> loadExcelData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // === FIX: Use the exact path 'assets/data/...' ===
      ByteData data = await rootBundle.load("/data/quiz_data.xlsx");
      
      var bytes = data.buffer.asUint8List();
      var excel = Excel.decodeBytes(bytes);

      Map<DateTime, int> tempData = {};

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table]!;
        for (int i = 1; i < sheet.rows.length; i++) {
          var row = sheet.rows[i];
          if (row.length < 2) continue;

          var dateVal = row[0]?.value;
          var countVal = row[1]?.value;
          DateTime? parsedDate;

          if (dateVal is String) {
            parsedDate = DateTime.tryParse(dateVal);
          } else if (dateVal is int || dateVal is double) {
             parsedDate = DateTime(1899, 12, 30).add(Duration(days: (dateVal as num).toInt()));
          }

          if (parsedDate != null) {
            DateTime normalized = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
            int count = int.tryParse(countVal.toString()) ?? 0;
            tempData[normalized] = count;
          }
        }
      }

      if (mounted) {
        setState(() {
          quizData = tempData;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Asset Error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          // Updated error message to help debug
          errorMessage = "Could not find 'assets/data/quiz_data.xlsx'.\nCheck pubspec.yaml and file location.";
        });
      }
    }
  }
  @override
  void initState() {
    super.initState();
    loadExcelData();
  }

  // ==========================================================
  // HEATMAP LOGIC
  // ==========================================================
  Color getHeatmapColor(DateTime day) {
    DateTime normalized = DateTime(day.year, day.month, day.day);
    int count = quizData[normalized] ?? 0;

    if (count == 0) return Colors.green.shade300;
    if (count <= 2) return Colors.amber.shade300;
    return Colors.red.shade400;
  }

  // ==========================================================
  // UI
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    // Extract User Info
    String displayName = widget.user.displayName ?? "Faculty";
    String firstName = displayName.split(" ")[0];
    String? photoUrl = widget.user.photoURL;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.blue),
            SizedBox(width: 10),
            Text(
              "BITS Goa | Quiz Scheduler",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              // User Profile Pic
              CircleAvatar(
                backgroundColor: Colors.blueAccent,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null ? Text(firstName[0], style: const TextStyle(color: Colors.white)) : null,
              ),
              const SizedBox(width: 8),
              // User Name
              Text(displayName, style: const TextStyle(color: Colors.black)),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 220,
            color: const Color(0xFF0B3C5D),
            child: const Column(
              children: [
                SizedBox(height: 30),
                SidebarItem(icon: Icons.dashboard, text: "Dashboard", active: true),
                SidebarItem(icon: Icons.quiz, text: "Quizzes"),
              ],
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hey, $firstName 👋",
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Here’s the student workload heatmap for scheduling quizzes:",
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  // CALENDAR / HEATMAP CARD
                  Expanded(
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : errorMessage != null
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.red, size: 40),
                                        const SizedBox(height: 10),
                                        Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: [
                                      // Legend
                                      Row(
                                        children: [
                                          Legend(color: Colors.green.shade300, text: "Free"),
                                          Legend(color: Colors.amber.shade300, text: "Medium"),
                                          Legend(color: Colors.red.shade400, text: "Heavy"),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      // Calendar
                                      Expanded(
                                        child: TableCalendar(
                                          firstDay: DateTime.utc(2020),
                                          lastDay: DateTime.utc(2035),
                                          focusedDay: _focusedDay,
                                          calendarBuilders: CalendarBuilders(
                                            defaultBuilder: (context, day, _) {
                                              return Container(
                                                margin: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: getHeatmapColor(day),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '${day.day}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helpers
class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool active;
  const SidebarItem({super.key, required this.icon, required this.text, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: active ? Colors.white10 : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class Legend extends StatelessWidget {
  final Color color;
  final String text;
  const Legend({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 6),
        Text(text),
        const SizedBox(width: 16),
      ],
    );
  }
}