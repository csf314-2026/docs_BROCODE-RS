import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SettingsView extends StatefulWidget {
  final User user;
  const SettingsView({super.key, required this.user});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _reminderFrequency = 'None'; // 'None', 'Daily', 'Weekly'
  bool _isLoadingSettings = true;
  bool _isSavingSettings = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reminderFrequency = prefs.getString('reminder_frequency') ?? 'None';
      _isLoadingSettings = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSavingSettings = true);
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Save locally for the UI
    await prefs.setString('reminder_frequency', _reminderFrequency);

    try {
      // 2. Get their unique device token for Push Notifications
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // 3. Save to Firestore so the Cloud Function knows what to do
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSettings) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Settings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B3C5D))),
          const Text("Manage your smart reminders.", style: TextStyle(color: Colors.black54, fontSize: 14)),
          const SizedBox(height: 20),

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
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
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
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            // NOTE: Update this text when you change the server to 8 PM!
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
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}