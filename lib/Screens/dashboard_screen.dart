import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'account_summary.dart';
import 'user_profile_section.dart';
import 'Notifications.dart';
import 'QuickActions.dart';
import 'AppDrawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      // Fetch user profile data here
      future: fetchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while fetching data
          return CircularProgressIndicator();
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
                    // Provide quick access actions
                    QuickActions(user: user),
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
          );
        }
      },
    );
  }

  Future<Map<String, dynamic>> fetchUserProfile() async {
    // Retrieve the token from secure storage
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    print(token);

    if (token == null) {
      // Handle the case where the token is not available
      throw Exception('Token not found');
    }
    final response = await http.get(
      Uri.parse('http://localhost:3000/user/profile'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    print(response);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['user'];
    } else {
      // Handle error
      throw Exception('Failed to load user profile');
    }
  }
}

class UpcomingEvents extends StatelessWidget {
  final List<Event> events;

  const UpcomingEvents({super.key, required this.events});

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

  const EventItem({super.key, required this.event});

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
