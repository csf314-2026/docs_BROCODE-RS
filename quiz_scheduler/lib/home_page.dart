import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:table_calendar/table_calendar.dart';
import 'package:excel/excel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  /// Stores quiz count per day
  Map<DateTime, int> quizData = {};

  @override
  void initState() {
    super.initState();
    loadExcelData();
  }

  // ============================================================
  // EXCEL LOADER  (Future → Replace with DB/API call)
  // ============================================================
  Future<void> loadExcelData() async {
  try {
    ByteData data =
        await rootBundle.load("data/quiz_data.xlsx");

    Uint8List bytes = data.buffer.asUint8List();
    var excel = Excel.decodeBytes(bytes);

    Map<DateTime, int> tempData = {};

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table]!;

      if (sheet.rows.isEmpty) continue;

      // ===============================
      // READ HEADER ROW
      // ===============================
      var header = sheet.rows[0];

      debugPrint("Headers → ${header.map((c) => c?.value)}");

      // ===============================
      // READ DATA ROWS
      // ===============================
      for (int i = 1; i < sheet.rows.length; i++) {
        var row = sheet.rows[i];

        if (row.length < 2) continue;

        var dateVal = row[0]?.value;
        var countVal = row[1]?.value;

        if (dateVal == null) continue;

        DateTime? parsedDate;

        // String date
        if (dateVal is String) {
          parsedDate = DateTime.tryParse(dateVal);
        }

        // Excel serial date
        if (dateVal is double) {
          parsedDate = DateTime(1899, 12, 30)
              .add(Duration(days: dateVal.toInt()));
        }

        if (parsedDate == null) continue;

        DateTime normalized =
            DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

        int count =
            int.tryParse(countVal.toString()) ?? 0;

        tempData[normalized] = count;
      }
    }

    setState(() {
      quizData = tempData;
    });

    debugPrint("Loaded Quiz Data → $quizData");

  } catch (e) {
    debugPrint("Excel Load Error ❌: $e");
  }
}


  // ============================================================
  // HEATMAP COLOR LOGIC  (SEPARATE → Future Editable)
  // ============================================================
  Color getHeatmapColor(DateTime day) {
    DateTime normalized = DateTime(day.year, day.month, day.day);

    int count = quizData[normalized] ?? 0;

    if (count == 0) {
      return Colors.green;
    } else if (count <= 2) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Faculty Dashboard"),
        backgroundColor: const Color(0xFF0B3C5D),
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

          const Text(
            "Quiz Density Heatmap",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          // ====================================================
          // CALENDAR
          // ====================================================
          Expanded(
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,

              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },

              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  Color color = getHeatmapColor(
                    DateTime(day.year, day.month, day.day),
                  );

                  return Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ====================================================
          // LEGEND
          // ====================================================
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                LegendBox(color: Colors.green, text: "No Quiz"),
                LegendBox(color: Colors.yellow, text: "1–2 Quizzes"),
                LegendBox(color: Colors.red, text: "3+ Quizzes"),
              ],
            ),
          ),
          Text(
            "Loaded Dates: ${quizData.length}",
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LEGEND WIDGET
// ============================================================
class LegendBox extends StatelessWidget {
  final Color color;
  final String text;

  const LegendBox({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        const SizedBox(width: 6),

        Text(text),
      ],
    );
  }
}
