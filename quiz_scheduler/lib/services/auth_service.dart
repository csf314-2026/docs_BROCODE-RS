import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:google_sign_in/google_sign_in.dart'; 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isAuthorized(String? email) async {
    if (email == null || email.isEmpty) return false;

    try {
      String cleanEmail = email.trim().toLowerCase();
      String domain = cleanEmail.split('@').last;
      
      DocumentSnapshot snapshot = await _firestore.collection('app_settings').doc('access_control').get();
      List<dynamic> admins = [];
      List<dynamic> allowedDomains = [];

      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        admins = data['admin_emails'] ?? [];
        allowedDomains = data['allowed_domains'] ?? [];
      }

      List<String> cleanAdmins = admins.map((e) => e.toString().toLowerCase().trim()).toList();
      if (cleanAdmins.contains(cleanEmail)) return true;

      List<String> cleanDomains = allowedDomains.map((d) => d.toString().toLowerCase().trim()).toList();
      if (cleanDomains.contains(domain)) return true;

      var professorQuery = await _firestore.collection('courses').where('Professor', arrayContains: cleanEmail).limit(1).get();
      if (professorQuery.docs.isNotEmpty) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<User?> signInWithGoogle({bool requestCalendarAccess = false}) async {
    try {
      UserCredential userCredential;
      String? serverAuthCode;

      if (kIsWeb) {
        // --- WEB FLOW ---
        // Note: Flutter Web does not easily expose offline server codes natively.
        // Sync should be initiated via the Android app.
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        if (requestCalendarAccess) {
          googleProvider.addScope('https://www.googleapis.com/auth/calendar.events');
          googleProvider.setCustomParameters({'prompt': 'consent', 'access_type': 'offline'});
        }
        userCredential = await _auth.signInWithPopup(googleProvider);
        
      } else {
        // --- MOBILE FLOW (Android/iOS) ---
        final googleSignIn = GoogleSignIn.instance;

        // THE MAGIC FIX: If asking for Calendar, force Google to forget the session.
        // This GUARANTEES the consent screen shows up and issues a fresh code.
        if (requestCalendarAccess) {
          try { await googleSignIn.disconnect(); } catch (_) {}
        }
        
        List<String> scopes = ['email', 'profile'];
        if (requestCalendarAccess) scopes.add('https://www.googleapis.com/auth/calendar.events');

        await googleSignIn.initialize(
          serverClientId: '699022731941-8dairkag4kun3uitmdc5ebv80k4ab12m.apps.googleusercontent.com',
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
        if (googleUser == null) return null; // User cancelled

        // Request Server Code
        if (requestCalendarAccess) {
          final GoogleSignInServerAuthorization? serverAuth = 
              await googleUser.authorizationClient.authorizeServer(scopes);
          serverAuthCode = serverAuth?.serverAuthCode;

          // STRICT CHECK: Don't fail silently anymore!
          if (serverAuthCode == null) {
            throw Exception("Google refused to provide a sync code. Try clearing app data.");
          }
        }

        final clientAuth = await googleUser.authorizationClient.authorizeScopes(scopes);
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: clientAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }
      
      User? user = userCredential.user;
      if (user == null || user.email == null) {
        await signOut();
        throw Exception("Login failed: Google did not provide an email address.");
      }

      bool authorized = await isAuthorized(user.email);
      if (!authorized) {
        await signOut();
        throw Exception("Unauthorized Domain Access"); 
      }

      // --- Database Write ---
      if (requestCalendarAccess) {
        Map<String, dynamic> updateData = {'calendar_sync_enabled': true};
        if (serverAuthCode != null) {
          updateData['server_auth_code'] = serverAuthCode;
        }
        await _firestore.collection('users').doc(user.email).set(updateData, SetOptions(merge: true));
      }

      return user;

    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }
  }
}