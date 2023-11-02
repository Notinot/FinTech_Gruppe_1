import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/login_screen.dart';
import 'transaction_history_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppDrawer extends StatelessWidget {
  final Map<String, dynamic> user;
  AppDrawer({required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(user['username']),
            accountEmail: Text(user['email']),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage(
                  'lib/assets/profile_img.png'), // Replace with the user's profile picture
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () {
              // Navigate to the dashboard screen
              // Implement the navigation as needed
            },
          ),
          ListTile(
            leading: Icon(Icons.attach_money),
            title: Text('Money Transfer'),
            onTap: () {
              // Navigate to the money transfer section
              // Implement the navigation as needed
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('History'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TransactionHistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.event),
            title: Text('Events'),
            onTap: () {
              // Navigate to the events section
              // Implement the navigation as needed
            },
          ),
          ListTile(
            leading: Icon(Icons.group),
            title: Text('Groups'),
            onTap: () {
              // Navigate to the groups section
              // Implement the navigation as needed
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              // Navigate to the settings section
              // Implement the navigation as needed
            },
          ),
          Divider(), // Add a divider to separate the top items from the bottom items
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Sign Out'),
            onTap: () {
              logout(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
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
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');

  // Clear the token
  await storage.delete(key: 'token');

  print('Token deleted: $token'); // Add this line for debugging

  // Navigate to the login screen and remove the ability to go back
  Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => LoginScreen()));
}
