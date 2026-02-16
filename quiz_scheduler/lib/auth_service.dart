import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==========================================================
  // ADMIN WHITELIST
  // Add any app admins here
  // ==========================================================
  final List<String> adminEmails = [

    "admin@goa.bits-pilani.ac.in",
    "rishabhsahusng@gmail.com"

    // Example:
    // "rishabh.sahu@goa.bits-pilani.ac.in",
  ];

  // ==========================================================
  // DOMAIN + ADMIN AUTHORIZATION CHECK
  // ==========================================================
  bool isAuthorized(String email) {

  // TEMP DEV BYPASS
  if (email.contains("@")) {
    return true;
  }

  return false;
}

  // bool isAuthorized(String email) {

  //   // Faculty domain access
  //   if (email.endsWith("@goa.bits-pilani.ac.in")) {
  //     return true;
  //   }

  //   // Admin override access
  //   if (adminEmails.contains(email)) {
  //     return true;
  //   }

  //   return false;
  // }

  // ==========================================================
  // GOOGLE SIGN IN
  // ==========================================================
  Future<User?> signInWithGoogle() async {

  try {

    final GoogleSignInAccount? googleUser =
        await GoogleSignIn().signIn();

    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential =
        GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential =
        await _auth.signInWithCredential(
            credential);

    User? user = userCredential.user;

    if (user == null) return null;

    // ================================
    // 🔍 DEBUG PRINT — ADD HERE
    // ================================
    print("Logged in email: ${user.email}");

    // ================================
    // DOMAIN CHECK
    // ================================
    if (!isAuthorized(user.email!)) {

      await signOut();

      throw Exception(
          "Unauthorized Domain Access");
    }

    return user;

  } catch (e) {
    rethrow;
  }
}


  // ==========================================================
  // GET CURRENT USER
  // ==========================================================
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // ==========================================================
  // SIGN OUT
  // ==========================================================
  Future<void> signOut() async {

    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
