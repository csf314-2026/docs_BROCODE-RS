import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class CalendarSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetches the current sync status from the user's Firestore document.
  Future<bool> isSyncEnabled() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;

    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.email).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['calendar_sync_enabled'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint("Error checking calendar sync status: $e");
      return false;
    }
  }

  /// Triggers the Google Auth flow to request Calendar permissions.
  /// If successful, the `AuthService` will automatically save `calendar_sync_enabled: true`
  /// and the `server_auth_code` to Firestore.
  Future<void> enableSync() async {
    try {
      await AuthService().signInWithGoogle(requestCalendarAccess: true);
    } catch (e) {
      debugPrint("Failed to enable calendar sync: $e");
      rethrow;
    }
  }

  /// Disables calendar sync by updating the user's Firestore document.
  /// It also deletes the server_auth_code so the backend knows to stop generating tokens.
  Future<void> disableSync() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception("User must be logged in to disable sync.");
    }

    try {
      await _firestore.collection('users').doc(user.email).set({
        'calendar_sync_enabled': false,
        // Remove the auth code so the backend stops attempting to use it
        'server_auth_code': FieldValue.delete(),
        'refresh_token': FieldValue.delete(), 
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Failed to disable calendar sync: $e");
      rethrow;
    }
  }
}