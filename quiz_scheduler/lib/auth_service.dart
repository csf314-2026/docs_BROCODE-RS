import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================================
  // DYNAMIC AUTHORIZATION CHECK
  // ==========================================================
  Future<bool> isAuthorized(String? email) async {
    // 1. Safety Check
    if (email == null || email.isEmpty) {
      print("AUTH DEBUG: Email was null or empty.");
      return false;
    }

    try {
      // 2. Normalize
      String cleanEmail = email.trim().toLowerCase();
      String domain = cleanEmail.split('@').last;
      
      print("AUTH DEBUG: Checking permissions for: $cleanEmail");

      // 3. Fetch Whitelist from Firestore (Admin/Domains)
      DocumentSnapshot snapshot = await _firestore
          .collection('app_settings')
          .doc('access_control')
          .get();

      // Default empty lists if doc doesn't exist yet
      List<dynamic> admins = [];
      List<dynamic> allowedDomains = [];

      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        admins = data['admin_emails'] ?? [];
        allowedDomains = data['allowed_domains'] ?? [];
      }

      // 4. CHECK 1: Is Admin?
      List<String> cleanAdmins = admins.map((e) => e.toString().toLowerCase().trim()).toList();
      if (cleanAdmins.contains(cleanEmail)) {
        print("AUTH DEBUG: Access Granted (Admin Match)");
        return true;
      }

      // 5. CHECK 2: Is Allowed Domain? (Student Check)
      List<String> cleanDomains = allowedDomains.map((d) => d.toString().toLowerCase().trim()).toList();
      if (cleanDomains.contains(domain)) {
        print("AUTH DEBUG: Access Granted (Domain Match)");
        return true;
      }

      // 6. CHECK 3: Is Professor? (The NEW Fix)
      // We check if this email exists in the 'Professor' array of ANY course.
      // This allows personal Gmails if they are assigned to a course.
      var professorQuery = await _firestore
          .collection('courses')
          .where('Professor', arrayContains: cleanEmail) // Firestore check
          .limit(1)
          .get();

      if (professorQuery.docs.isNotEmpty) {
        print("AUTH DEBUG: Access Granted (Professor Match)");
        return true;
      }

      // 7. If all checks fail -> Deny
      print("AUTH DEBUG: Access Denied. Email not found in Admins, Domains, or Professors.");
      return false;

    } catch (e) {
      print("AUTH DEBUG: Error checking authorization: $e");
      return false;
    }
  }

  // ==========================================================
  // GOOGLE SIGN IN (Firebase Native - Web Popup)
  // ==========================================================
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Open the popup
      final UserCredential userCredential = 
          await _auth.signInWithPopup(googleProvider);
      
      User? user = userCredential.user;

      // === NULL SAFETY CHECK ===
      if (user == null || user.email == null) {
        await signOut();
        throw Exception("Login failed: Google did not provide an email address.");
      }

      // Check Authorization (Admin / Domain / Professor)
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
  }
}