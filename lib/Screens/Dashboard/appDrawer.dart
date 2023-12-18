import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter_application_1/Screens/Dashboard/dashBoardScreen.dart';
import 'package:flutter_application_1/Screens/Events/CreateEventScreen.dart';

import 'package:flutter_application_1/Screens/Friends/FriendsScreen.dart';
import 'package:flutter_application_1/Screens/Money/AddMoneyScreen.dart';
import 'package:flutter_application_1/Screens/Friends/FriendsScreenTEMP.dart';

import 'package:flutter_application_1/Screens/Money/TransactionHistoryScreen.dart';
import 'package:flutter_application_1/assets/color_schemes.g.dart';
import 'package:flutter_application_1/Screens/Login%20&%20Register/LoginScreen.dart';

import 'package:flutter_application_1/Screens/EditUser/EditUserScreen.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_application_1/Screens/Events/EventScreen.dart';
import 'package:flutter_application_1/Screens/Dashboard/themeNotifier.dart';
//import the provider package
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  final Map<String, dynamic> user;
  const AppDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Get the instance of ThemeNotifier using Provider
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    bool isDarkMode = themeNotifier.darkTheme;

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
            leading: const Icon(Icons.monetization_on),
            title: const Text('Transactions'),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EventScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups_rounded),
            title: const Text('Friends'),
            onTap: () {
              Navigator.push(
                context,
                //MaterialPageRoute(builder: (context) => FriendsScreen()),
                MaterialPageRoute(builder: (context) => FriendsScreenTEMP()),
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

          //ListTile to add money to the account
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add Money'),
            onTap: () {
              // Navigate to the events section
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddMoneyScreen()),
              );
            },
          ),
          //ListTile to change theme from light to dark and vice versa

          const Divider(), // Add a divider to separate the top items from the bottom items
          ListTile(
            //change the icon depending on the theme, make it a toggle button
            leading: themeNotifier.darkTheme
                ? const Icon(Icons.light_mode)
                : const Icon(Icons.dark_mode),
            title: themeNotifier.darkTheme
                ? const Text('Light Theme')
                : const Text('Dark Theme'),
            onTap: () {
              themeNotifier.darkTheme = !themeNotifier.darkTheme;
            },
          ),
          const Divider(),

          SizedBox(height: 170),
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
