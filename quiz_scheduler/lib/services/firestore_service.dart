import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================================
  // 1. GET PROFESSOR COURSES
  // ==========================================================
  Stream<QuerySnapshot> getProfessorCourses(String email) {
    return _db.collection('courses')
        .where('Professor', arrayContains: email)
        .snapshots();
  }

  // ==========================================================
  // 2. CONFLICT DETECTION ALGORITHM
  // ==========================================================
  Future<String?> checkConflict(String courseId, DateTime start, int durationMinutes) async {
    DateTime end = start.add(Duration(minutes: durationMinutes));
    
    // STEP 1: Find ALL quizzes happening at the same time (Any course)
    // We check a broad window (e.g., same day) first to minimize DB reads, 
    // then filter precisely in memory.
    DateTime startOfDay = DateTime(start.year, start.month, start.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    QuerySnapshot quizzesSnapshot = await _db.collection('quizzes')
        .where('date_&_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date_&_time', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    List<String> conflictingCourseIds = [];

    for (var doc in quizzesSnapshot.docs) {
      Timestamp qStartTs = doc['date_&_time'];
      int qDuration = doc['duration'];
      
      DateTime qStart = qStartTs.toDate();
      DateTime qEnd = qStart.add(Duration(minutes: qDuration));

      // Check Time Overlap
      if (start.isBefore(qEnd) && end.isAfter(qStart)) {
        conflictingCourseIds.add(doc['course_id'] as String);
      }
    }

    // If no quizzes at this time, we are safe!
    if (conflictingCourseIds.isEmpty) return null;

    // STEP 2: Check Student Overlap
    // We need to see if any student in OUR course is also in the CONFLICTING courses.
    
    // Get students in the target course
    QuerySnapshot studentsSnapshot = await _db.collection('users')
        .where('courses', arrayContains: courseId) // Students in OUR course
        .get();

    if (studentsSnapshot.docs.isEmpty) return null; // No students, no problem.

    for (var studentDoc in studentsSnapshot.docs) {
      List<dynamic> studentCourses = studentDoc['courses'] ?? [];
      
      // Check if this student is enrolled in any of the conflicting courses
      for (String conflictId in conflictingCourseIds) {
        if (courseId == conflictId) {
           return "Course Conflict: A quiz is already scheduled for $courseId at this time.";
        }
        if (studentCourses.contains(conflictId)) {
          // Found a student who has a clash!
          return "Student Conflict: ${studentDoc.id} has a quiz in course $conflictId at this time.";
        }
      }
    }

    return null; // No conflicts found
  }

  // ==========================================================
  // 3. ADD QUIZ
  // ==========================================================
  Future<void> scheduleQuiz(String courseId, DateTime date, String professorEmail) async {
    await _db.collection('quizzes').add({
      'course_id': courseId,
      'date_&_time': Timestamp.fromDate(date),
      'duration': 60, // Default duration
      'created_by': professorEmail,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}