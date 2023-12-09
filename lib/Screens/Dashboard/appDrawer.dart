import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter_application_1/Screens/Dashboard/dashBoardScreen.dart';

import 'package:flutter_application_1/Screens/Friends/FriendsScreen.dart';

import 'package:flutter_application_1/Screens/Money/TransactionHistoryScreen.dart';

import 'package:flutter_application_1/Screens/Login%20&%20Register/LoginScreen.dart';

import 'package:flutter_application_1/Screens/EditUser/EditUserScreen.dart';

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
            currentAccountPicture: CircleAvatar(
              backgroundImage: user['picture'] != null &&
                      user['picture'] is Map<String, dynamic> &&
                      user['picture']['data'] != null
                  ? MemoryImage(
                      Uint8List.fromList(user['picture']['data'].cast<int>()))
                  : AssetImage('lib/assets/profile_img.png') as ImageProvider,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DashboardScreen()),
              );
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
            leading: const Icon(Icons.groups_rounded),
            title: const Text('Friends'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FriendsScreen()),
                //    builder: (context) => FriendsScreen(user: user)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile information'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditUser()),
              );
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
