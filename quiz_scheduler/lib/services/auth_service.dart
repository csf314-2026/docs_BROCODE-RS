import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:google_sign_in/google_sign_in.dart'; 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================================
  // DYNAMIC AUTHORIZATION CHECK
  // ==========================================================
  Future<bool> isAuthorized(String? email) async {
    if (email == null || email.isEmpty) return false;

    try {
      String cleanEmail = email.trim().toLowerCase();
      String domain = cleanEmail.split('@').last;
      
      DocumentSnapshot snapshot = await _firestore
          .collection('app_settings')
          .doc('access_control')
          .get();

      List<dynamic> admins = [];
      List<dynamic> allowedDomains = [];

      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        admins = data['admin_emails'] ?? [];
        allowedDomains = data['allowed_domains'] ?? [];
      }

      // 1. Check Admin
      List<String> cleanAdmins = admins.map((e) => e.toString().toLowerCase().trim()).toList();
      if (cleanAdmins.contains(cleanEmail)) return true;

      // 2. Check Domain
      List<String> cleanDomains = allowedDomains.map((d) => d.toString().toLowerCase().trim()).toList();
      if (cleanDomains.contains(domain)) return true;

      // 3. Check Professor
      var professorQuery = await _firestore
          .collection('courses')
          .where('Professor', arrayContains: cleanEmail)
          .limit(1)
          .get();

      if (professorQuery.docs.isNotEmpty) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  // ==========================================================
  // CROSS-PLATFORM GOOGLE SIGN IN (v7.0.0+ Compliant)
  // ==========================================================
  Future<User?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // --- WEB FLOW ---
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // --- MOBILE FLOW (Android/iOS) ---
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.initialize(
          serverClientId: '699022731941-8dairkag4kun3uitmdc5ebv80k4ab12m.apps.googleusercontent.com',
        ); // Mandatory in v7+

        // Step 1: Authentication (Identity)
        final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
        if (googleUser == null) return null; // User cancelled

        // Step 2: Authorization (Permissions)
        final List<String> scopes = ['email', 'profile'];
        final clientAuth = await googleUser.authorizationClient.authorizeScopes(scopes);

        // Step 3: Extract Identity Token
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Step 4: Create Firebase Credential
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: clientAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Step 5: Sign in to Firebase
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

      return user;

    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut(); // Updated to singleton here too
    }
  }
}