import 'package:flutter/material.dart';
import 'account_summary.dart';
import 'user_profile_section.dart';
import 'Notifications.dart';
import 'QuickActions.dart';
import 'AppDrawer.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String username = "Lukas";
    double balance = 1000.00;
    // Example list of upcoming events
    List<Event> upcomingEvents = [
      Event(title: 'Meeting', date: '2023-11-01'),
      Event(title: 'Workshop', date: '2023-11-05'),
      Event(title: 'Conference', date: '2023-11-10'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              UserProfileSection(username),
              AccountSummary(balance),
              QuickActions(),
              Notifications(),
              UpcomingEvents(events: upcomingEvents),
            ],
          ),
        ),
      ),
      drawer: AppDrawer(),
    );
  }
}

class UpcomingEvents extends StatelessWidget {
  final List<Event> events;

  UpcomingEvents({required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          'Upcoming Events:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
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

  EventItem({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: ListTile(
        title: Text(event.title),
        subtitle: Text(
          'Date: ${event.date}',
        ),
      ),
    );
  }
}
