import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================================
  // DYNAMIC AUTHORIZATION CHECK
  // ==========================================================
  Future<bool> isAuthorized(String? email) async {
    // 1. Safety Check: If email is null, reject immediately.
    if (email == null || email.isEmpty) {
      print("AUTH DEBUG: Email was null or empty.");
      return false;
    }

    try {
      // 2. Normalize: Convert to lowercase to match Firestore data
      String cleanEmail = email.trim().toLowerCase();
      String domain = cleanEmail.split('@').last;
      
      print("AUTH DEBUG: Checking permissions for: $cleanEmail");

      // 3. Fetch Whitelist from Firestore
      DocumentSnapshot snapshot = await _firestore
          .collection('app_settings')
          .doc('access_control')
          .get();

      if (!snapshot.exists) {
        print("AUTH DEBUG: CRITICAL - 'access_control' document not found in Firestore!");
        return false; 
      }

      // 4. Safely get data
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
      
      if (data == null) {
        print("AUTH DEBUG: Document exists but data is null.");
        return false;
      }

      // 5. Check Admin Emails
      List<dynamic> admins = data['admin_emails'] ?? [];
      // Convert database list to lowercase strings for comparison
      List<String> cleanAdmins = admins.map((e) => e.toString().toLowerCase().trim()).toList();
      
      if (cleanAdmins.contains(cleanEmail)) {
        print("AUTH DEBUG: Access Granted (Admin Match)");
        return true;
      }

      // 6. Check Allowed Domains
      List<dynamic> domains = data['allowed_domains'] ?? [];
      List<String> cleanDomains = domains.map((d) => d.toString().toLowerCase().trim()).toList();
      
      if (cleanDomains.contains(domain)) {
        print("AUTH DEBUG: Access Granted (Domain Match)");
        return true;
      }

      print("AUTH DEBUG: Access Denied. Email not in whitelist.");
      return false;

    } catch (e) {
      print("AUTH DEBUG: Error checking authorization: $e");
      // This usually happens if Firestore Rules block the read
      return false;
    }
  }

  // ==========================================================
  // GOOGLE SIGN IN
  // ==========================================================
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; 

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      // === FIXED: NULL SAFETY CHECK ===
      // Previous code used user.email! which crashed if email was null
      if (user == null || user.email == null) {
        await signOut();
        throw Exception("Login failed: Google did not provide an email address.");
      }

      // Check Authorization
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
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}