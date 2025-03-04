import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hatka/Screen/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      // Navigate to LoginScreen directly without using named routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Removes all previous screens from the stack
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Settings Header Text
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Settings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            
            // Terms and Privacy
            TextButton(
              onPressed: () {
                // Navigate to Terms and Privacy screen
                // Navigator.push(context, MaterialPageRoute(builder: (context) => TermsPrivacyScreen()));
              },
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text('Terms and Privacy', style: TextStyle(fontSize: 18)),
              ),
            ),
            const Divider(),

            // Get Help
            TextButton(
              onPressed: () {
                // Navigate to Help screen
                // Navigator.push(context, MaterialPageRoute(builder: (context) => HelpScreen()));
              },
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text('Get Help', style: TextStyle(fontSize: 18)),
              ),
            ),
            const Divider(),

            // Logout
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          _signOut(context);
                        },
                        child: const Text(
                          'Log Out',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Log Out',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
