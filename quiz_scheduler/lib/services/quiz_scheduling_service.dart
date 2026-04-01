import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum ScheduleStatus { ok, timeConflict, workloadWarning }

class ScheduleResult {
  final ScheduleStatus status;
  final String message;
  final int maxWorkload;

  ScheduleResult({required this.status, this.message = "", this.maxWorkload = 0});
}

class QuizSchedulingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. VALIDATION & CONFLICT DETECTION ---
  Future<ScheduleResult> validateSchedule({
    required String courseId,
    required DateTime proposedStart,
    required DateTime proposedEnd,
    required DateTime selectedDay,
  }) async {
    Set<String> overlappingCourses = {courseId};

    // Gather students enrolled in this course
    var studentsSnapshot = await _db.collection('users')
        .where('courses', arrayContains: courseId)
        .get();

    for (var student in studentsSnapshot.docs) {
      List<dynamic> studentCourses = student['courses'] ?? [];
      for (var c in studentCourses) {
        overlappingCourses.add(c.toString());
      }
    }

    DateTime startOfDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    // Gather all quizzes for the day
    var dayQuizzesSnapshot = await _db.collection('quizzes')
        .where('date_&_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date_&_time', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    // CHECK 1: EXACT TIME OVERLAP (Hard Block)
    for (var doc in dayQuizzesSnapshot.docs) {
      String quizCourseId = doc['course_id'];

      if (overlappingCourses.contains(quizCourseId)) {
        DateTime existingStart = (doc['date_&_time'] as Timestamp).toDate();
        int existingDuration = doc['duration'] ?? 60;
        DateTime existingEnd = existingStart.add(Duration(minutes: existingDuration));

        if (proposedStart.isBefore(existingEnd) && proposedEnd.isAfter(existingStart)) {
          String startStr = DateFormat('h:mm a').format(existingStart); 
          String endStr = DateFormat('h:mm a').format(existingEnd);     
          return ScheduleResult(
            status: ScheduleStatus.timeConflict, 
            message: "$quizCourseId has a quiz from $startStr to $endStr."
          );
        }
      }
    }

    // CHECK 2: HIGH DAILY WORKLOAD (Soft Warning)
    int maxQuizzesOnDay = 0;
    for (var student in studentsSnapshot.docs) {
      List<dynamic> studentCourses = student['courses'] ?? [];
      int studentQuizCount = 0;
      
      for (var doc in dayQuizzesSnapshot.docs) {
        if (studentCourses.contains(doc['course_id'])) {
          studentQuizCount++;
        }
      }
      if (studentQuizCount > maxQuizzesOnDay) maxQuizzesOnDay = studentQuizCount;
    }

    if (maxQuizzesOnDay >= 2) {
      return ScheduleResult(status: ScheduleStatus.workloadWarning, maxWorkload: maxQuizzesOnDay);
    }

    return ScheduleResult(status: ScheduleStatus.ok);
  }

  // --- 2. SAVE TO DATABASE ---
  Future<void> saveQuiz({
    required String courseId,
    required String title,
    required DateTime startTime,
    required int durationMinutes,
    required String creatorEmail,
  }) async {
    DocumentSnapshot courseDoc = await _db.collection('courses').doc(courseId).get();
    String finalCourseName = courseDoc.exists ? (courseDoc['course_name'] ?? courseId) : courseId;

    await _db.collection('quizzes').add({
      'title': title, 
      'course_id': courseId,
      'course_name': finalCourseName, 
      'date_&_time': Timestamp.fromDate(startTime),
      'duration': durationMinutes,
      'created_by': creatorEmail,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}