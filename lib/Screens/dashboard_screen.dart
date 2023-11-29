import 'package:flutter/material.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter_application_1/Screens/AppDrawer.dart';
import 'package:flutter_application_1/Screens/Notifications.dart';
import 'package:flutter_application_1/Screens/account_summary.dart';
import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:flutter_application_1/Screens/create_event_screen.dart';
import 'package:flutter_application_1/Screens/quick_menu.dart';
import 'package:flutter_application_1/Screens/request_money_screen.dart';
import 'package:flutter_application_1/Screens/send_money_screen.dart';
import 'package:flutter_application_1/Screens/user_profile_section.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      // Fetch user profile data here
      future: ApiService.fetchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while fetching data
          return CircularProgressIndicator(
            value: 0.5,
          );
        } else if (snapshot.hasError) {
          // Handle errors
          return Text('Error: ${snapshot.error}');
        } else {
          // Once data is loaded, display the dashboard
          final Map<String, dynamic> user = snapshot.data!;

          return Scaffold(
              appBar: AppBar(
                title: const Text('Dashboard'),
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
              floatingActionButton: Positioned(
                //bottom: 16.0,
                //right: 16.0,
                child: QuickMenu(user: user),
              ));
        }
      },
    );
  }
}

class UpcomingEvents extends StatelessWidget {
  final List<Event> events;

  const UpcomingEvents({Key? key, required this.events}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text(
          'Upcoming Events:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          itemCount: events.length,
          itemBuilder: (context, index) {
            return EventItem(event: events[index]);
          },
        ),
      ],
    );
  }
}

class Event {
  final String title;
  final String date;

  Event({required this.title, required this.date});
}

class EventItem extends StatelessWidget {
  final Event event;

  const EventItem({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: ListTile(
        title: Text(event.title),
        subtitle: Text(
          'Date: ${event.date}',
        ),
      ),
    );
  }
}
