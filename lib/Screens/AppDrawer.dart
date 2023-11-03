import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/login_screen.dart';
import 'transaction_history_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppDrawer extends StatelessWidget {
  final Map<String, dynamic> user;
  const AppDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(user['username']),
            accountEmail: Text(user['email']),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: AssetImage(
                  'lib/assets/profile_img.png'), // Replace with the user's profile picture
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              // Navigate to the dashboard screen
              // Implement the navigation as needed
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Money Transfer'),
            onTap: () {
              // Navigate to the money transfer section
              // Implement the navigation as needed
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TransactionHistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Events'),
            onTap: () {
              // Navigate to the events section
              // Implement the navigation as needed
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Groups'),
            onTap: () {
              // Navigate to the groups section
              // Implement the navigation as needed
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Navigate to the settings section
              // Implement the navigation as needed
            },
          ),
          const Divider(), // Add a divider to separate the top items from the bottom items
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sign Out'),
            onTap: () {
              logout(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false, // This clears the navigation stack
              );
            },
          ),
        ],
      ),
    );
  }
}

Future<void> logout(BuildContext context) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');

  // Clear the token
  await storage.delete(key: 'token');

  print('Token deleted: $token'); // Add this line for debugging

  // Navigate to the login screen and remove the ability to go back
  Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => const LoginScreen()));
}
