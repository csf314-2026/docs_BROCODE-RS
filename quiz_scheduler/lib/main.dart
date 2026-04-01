import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Added for FCM
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart'; // Added for role persistence
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Added for banners

// Import all your screens
import 'services/firebase_options.dart';
import 'login_page.dart';
import 'web/admin_dashboard.dart';
import 'web/faculty_dashboard.dart';
import 'web/student_dashboard.dart';
import 'android/mobile_student_dashboard.dart';
import 'services/notification_service.dart';

// ADD THIS RIGHT BELOW YOUR IMPORTS
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Local Notifications
  await NotificationService().init(); 
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // --- FCM FOREGROUND LISTENER ---
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      NotificationService().flutterLocalNotificationsPlugin.show(
        // ADD THESE NAMES:
        id: message.hashCode,
        title: message.notification!.title,
        body: message.notification!.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'quiz_updates',
            'Quiz Updates',
            channelDescription: 'Notifications for new quizzes',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

  runApp(const QuizSchedulerApp());
}

class QuizSchedulerApp extends StatelessWidget {
  const QuizSchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BITS Evals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF003366),
        useMaterial3: true,
      ),
      home: const AuthGate(), 
    );
  }
}

// --- UPDATED AUTH GATE ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _getDashboard(User user) async {
    String email = user.email!;

    try {
      // 1. Fetch the intent saved by the Login Page
      final prefs = await SharedPreferences.getInstance();
      String intent = prefs.getString('login_intent') ?? 'standard';

      // 2. ADMIN ROUTE
      if (intent == 'admin') {
        DocumentSnapshot accessDoc = await FirebaseFirestore.instance.collection('app_settings').doc('access_control').get();
        List<dynamic> admins = accessDoc.exists ? (accessDoc['admin_emails'] ?? []) : [];
        if (admins.contains(email)) {
          return AdminDashboard(user: user);
        }
      } 
      
      // 3. STANDARD ROUTE (Faculty or Student)
      else if (intent == 'standard') {
        // Check Faculty First
        var profQuery = await FirebaseFirestore.instance.collection('courses').where('Professor', arrayContains: email).limit(1).get();
        if (profQuery.docs.isNotEmpty) {
          return FacultyDashboard(user: user);
        }

        // Fallback to Student
        if (email.endsWith('@goa.bits-pilani.ac.in')) {
          if (kIsWeb) return StudentDashboard(user: user);
          return MobileStudentDashboard(user: user);
        }
      }

    } catch (e) {
      debugPrint("Routing error: $e");
    }
    
    // If permissions fail, force logout and return to login screen
    await FirebaseAuth.instance.signOut();
    return const LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Not logged in -> Login Page
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // Logged in -> Check SharedPreferences for the correct Dashboard
        return FutureBuilder<Widget>(
          future: _getDashboard(snapshot.data!),
          builder: (context, dashboardSnapshot) {
            if (dashboardSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Color(0xFF003366))),
              );
            }
            return dashboardSnapshot.data ?? const LoginPage();
          },
        );
      },
    );
  }
}