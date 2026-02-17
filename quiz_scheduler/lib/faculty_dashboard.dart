import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:table_calendar/table_calendar.dart';
import 'package:excel/excel.dart';

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, int> quizData = {};
  bool isLoading = true;

  // ==========================================================
  // LOAD EXCEL DATA
  // ==========================================================
  Future<void> loadExcelData() async {
    try {
      ByteData data = await rootBundle.load("data/quiz_data.xlsx");

      Uint8List bytes = data.buffer.asUint8List();
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
          }

          if (dateVal is double) {
            parsedDate = DateTime(
              1899,
              12,
              30,
            ).add(Duration(days: dateVal.toInt()));
          }

          if (parsedDate != null) {
            DateTime normalized = DateTime(
              parsedDate.year,
              parsedDate.month,
              parsedDate.day,
            );

            int count = int.tryParse(countVal.toString()) ?? 0;

            tempData[normalized] = count;
          }
        }
      }

      setState(() {
        quizData = tempData;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Excel Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadExcelData();
  }

  // ==========================================================
  // HEATMAP COLOR ENGINE (Editable Future Logic)
  // ==========================================================
  Color getHeatmapColor(DateTime day) {
    DateTime normalized = DateTime(day.year, day.month, day.day);

    int count = quizData[normalized] ?? 0;

    if (count == 0) return Colors.green;
    if (count <= 2) return Colors.yellow;
    return Colors.red;
  }

  // ==========================================================
  // UI
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // =======================
      // TOP BAR
      // =======================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.blue),
            SizedBox(width: 10),
            Text(
              "BITS Goa  |  Quiz Scheduler",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: const [
              CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person),
              ),
              SizedBox(width: 8),
              Text("John Prof", style: TextStyle(color: Colors.black)),
              SizedBox(width: 16),
            ],
          ),
        ],
      ),

      // =======================
      // BODY
      // =======================
      body: Row(
        children: [
          // ===================
          // SIDEBAR
          // ===================
          Container(
            width: 220,
            color: const Color(0xFF0B3C5D),
            child: Column(
              children: const [
                SizedBox(height: 30),

                SidebarItem(
                  icon: Icons.dashboard,
                  text: "Dashboard",
                  active: true,
                ),

                SidebarItem(icon: Icons.quiz, text: "Quizzes"),
              ],
            ),
          ),

          // ===================
          // MAIN CONTENT
          // ===================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Hey, John 👋",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Here’s the student workload heatmap for scheduling quizzes:",
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),

                  const SizedBox(height: 20),

                  // ===================
                  // HEATMAP CARD
                  // ===================
                  Expanded(
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                children: [
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Student Quiz Density - February 2026",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // LEGEND
                                  Row(
                                    children: const [
                                      Legend(
                                        color: Colors.green,
                                        text: "0 Quizzes",
                                      ),
                                      Legend(
                                        color: Colors.yellow,
                                        text: "1–2 Quizzes",
                                      ),
                                      Legend(color: Colors.red, text: "High"),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // CALENDAR
                                  Expanded(
                                    child: TableCalendar(
                                      firstDay: DateTime.utc(2020),
                                      lastDay: DateTime.utc(2035),
                                      focusedDay: _focusedDay,

                                      calendarBuilders: CalendarBuilders(
                                        defaultBuilder: (context, day, _) {
                                          Color color = getHeatmapColor(day);

                                          return Container(
                                            margin: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.8),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text('${day.day}'),
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

// ==========================================================
// SIDEBAR ITEM
// ==========================================================
class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool active;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.text,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: active ? Colors.white24 : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ==========================================================
// LEGEND WIDGET
// ==========================================================
class Legend extends StatelessWidget {
  final Color color;
  final String text;

  const Legend({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 18, height: 18, color: color),
        const SizedBox(width: 6),
        Text(text),
        const SizedBox(width: 16),
      ],
    );
  }
}
