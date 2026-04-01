import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EventDetailsList extends StatelessWidget {
  final DateTime selectedDay;

  const EventDetailsList({super.key, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    DateTime startOfDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        // Filter events that overlap with the selected day
        var dayEvents = snapshot.data!.docs.where((doc) {
          DateTime start = (doc['date_start'] as Timestamp).toDate();
          DateTime end = (doc['date_end'] as Timestamp).toDate();
          DateTime normalizedStart = DateTime(start.year, start.month, start.day);
          DateTime normalizedEnd = DateTime(end.year, end.month, end.day);
          return !startOfDay.isBefore(normalizedStart) && !startOfDay.isAfter(normalizedEnd);
        }).toList();

        if (dayEvents.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("No academic events on this day.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text("Day Events:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0B3C5D))),
            ),
            ...dayEvents.map((doc) {
              String type = doc['type'];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: type == 'holiday' ? Colors.blue.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: type == 'holiday' ? const Color(0xFF0B3C5D) : Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(
                      type == 'holiday' ? Icons.beach_access : Icons.assignment_late,
                      color: type == 'holiday' ? const Color(0xFF0B3C5D) : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      doc['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: type == 'holiday' ? const Color(0xFF0B3C5D) : Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}