import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/login_screen.dart';
import 'transaction_history_screen.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName:
                Text('Lukas Meinberg'), // Replace with actual user data
            accountEmail:
                Text('lukas@gmail.com'), // Replace with actual user data
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
