import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'account_summary.dart';
import 'user_profile_section.dart';
import 'Notifications.dart';
import 'QuickActions.dart';
import 'AppDrawer.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Extract user details
    String username = user['username'];
    double balance = user['balance'].toDouble();

    // Example list of upcoming events
    List<Event> upcomingEvents = [
      Event(title: 'Meeting', date: '2023-11-01'),
      Event(title: 'Workshop', date: '2023-11-05'),
      Event(title: 'Conference', date: '2023-11-10'),
    ];

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
              UserProfileSection(username),
              // Display user's account summary
              AccountSummary(balance),
              // Provide quick access actions
              const QuickActions(),
              // Show user notifications
              const Notifications(),
              // Display upcoming events
              UpcomingEvents(events: upcomingEvents),
            ],
          ),
        ),
      ),
      // Add the AppDrawer to the dashboard screen
      drawer: AppDrawer(user: user),
    );
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
