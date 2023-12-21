import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/appDrawer.dart';
import 'package:flutter_application_1/Screens/Dashboard/Notifications.dart';
import 'package:flutter_application_1/Screens/Dashboard/accountSummary.dart';
import 'package:flutter_application_1/Screens/Friends/FriendsScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:flutter_application_1/Screens/Events/CreateEventScreen.dart';
import 'package:flutter_application_1/Screens/Dashboard/quickActionsMenu.dart';
import 'package:flutter_application_1/Screens/Money/RequestMoneyScreen.dart';
import 'package:flutter_application_1/Screens/Money/SendMoneyScreen.dart';
import 'package:flutter_application_1/Screens/Dashboard/userProfileSection.dart';
import 'package:flutter_application_1/Screens/dashBoardScreen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      // Fetch user profile data here
      future: ApiService.fetchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Handle errors
          return Text('Error: ${snapshot.error}');
        } else {
          // Once data is loaded, display the dashboard
          final Map<String, dynamic> user = snapshot.data!;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
              actions: [
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    // Show friend requests as a modal bottom sheet
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      builder: (context) => FriendsScreen(),
                    );
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Display user's profile information
                    UserProfileSection(user),
                    // Display user's account summary
                    AccountSummary(user['balance'].toDouble()),
                    // Show user notifications
                    Notifications(),
                    // Display upcoming events
                    UpcomingEvents(
                      events: [
                        Event(title: 'Meeting', date: '2023-11-01'),
                        Event(title: 'Workshop', date: '2023-11-05'),
                        Event(title: 'Conference', date: '2023-11-10'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Add the AppDrawer to the dashboard screen
            drawer: AppDrawer(user: user),
            floatingActionButton: QuickMenu(
              user: user,
            ),
          );
        }
      },
    );
  }
}
