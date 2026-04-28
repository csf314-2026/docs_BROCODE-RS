import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Import the updated AuthService
import '../../services/auth_service.dart';

class SettingsView extends StatefulWidget {
  final User user;
  const SettingsView({super.key, required this.user});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _reminderFrequency = 'None';
  bool _isLoadingSettings = true;
  bool _isSavingSettings = false;
  
  // --- NEW: Calendar Sync State ---
  bool _isCalendarSyncEnabled = false;
  bool _isSyncingCalendar = false; // For showing a spinner during OAuth

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // --- NEW: Fetch Calendar Sync preference directly from Firestore ---
    bool calendarEnabled = false;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.user.email).get();
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        calendarEnabled = data['calendar_sync_enabled'] ?? false;
      }
    } catch (e) {
      debugPrint("Error loading user doc: $e");
    }

    if (mounted) {
      setState(() {
        _reminderFrequency = prefs.getString('reminder_frequency') ?? 'None';
        _isCalendarSyncEnabled = calendarEnabled;
        _isLoadingSettings = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSavingSettings = true);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('reminder_frequency', _reminderFrequency);

    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      await FirebaseFirestore.instance.collection('users').doc(widget.user.email).set({
        'reminder_frequency': _reminderFrequency,
        'fcm_token': fcmToken,
      }, SetOptions(merge: true));

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Smart Reminders activated via Cloud! ☁️"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving to cloud: $e"), backgroundColor: Colors.red));
    }

    if (mounted) setState(() => _isSavingSettings = false);
  }

  // --- NEW: Calendar Sync Toggle Handler ---
  Future<void> _toggleCalendarSync(bool enable) async {
    setState(() => _isSyncingCalendar = true);
    
    try {
      if (enable) {
        // Opting In: Request extra scopes via AuthService
        await AuthService().signInWithGoogle(requestCalendarAccess: true);
        if (mounted) {
          setState(() => _isCalendarSyncEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Google Calendar Sync Enabled!"), backgroundColor: Colors.green)
          );
        }
      } else {
        // Opting Out: Just update Firestore directly
        await FirebaseFirestore.instance.collection('users').doc(widget.user.email).set({
          'calendar_sync_enabled': false,
        }, SetOptions(merge: true));
        
        if (mounted) {
          setState(() => _isCalendarSyncEnabled = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Google Calendar Sync Disabled."), backgroundColor: Colors.orange)
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sync failed: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncingCalendar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSettings) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Settings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B3C5D))),
            const Text("Manage your smart reminders.", style: TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 20),
            
            // --- REMINDERS CARD ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.smart_toy, color: Color(0xFF0B3C5D)),
                        SizedBox(width: 10),
                        Text("Smart Cloud Reminders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Our servers will automatically calculate your schedule and send you a push notification if you have upcoming evals.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const Divider(height: 30),
                    const Text("Reminder Frequency", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _reminderFrequency,
                          items: const [
                            DropdownMenuItem(value: 'None', child: Text("None (Off)")),
                            DropdownMenuItem(value: 'Daily', child: Text("Daily (Evals Tomorrow)")),
                            DropdownMenuItem(value: 'Weekly', child: Text("Weekly (Evals this week)")),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _reminderFrequency = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Notifications are sent at 7:15 AM IST. Weekly summaries are sent on Sundays.",
                              style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isSavingSettings ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B3C5D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isSavingSettings
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Save Preferences", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // --- NEW: CALENDAR SYNC CARD ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_calendar, color: Color(0xFF0B3C5D)),
                        const SizedBox(width: 10),
                        const Expanded(child: Text("Google Calendar Sync", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        if (_isSyncingCalendar)
                          const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Automatically add registered quizzes directly to your primary Google Calendar. Quizzes will update automatically if a professor modifies the schedule.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _isCalendarSyncEnabled ? Colors.green : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: _isCalendarSyncEnabled ? Colors.green.shade50 : Colors.transparent,
                      ),
                      child: SwitchListTile(
                        title: Text(
                          _isCalendarSyncEnabled ? "Sync Active" : "Sync Disabled",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isCalendarSyncEnabled ? Colors.green.shade700 : Colors.grey.shade700
                          ),
                        ),
                        value: _isCalendarSyncEnabled,
                        activeColor: Colors.green,
                        onChanged: _isSyncingCalendar ? null : _toggleCalendarSync,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}