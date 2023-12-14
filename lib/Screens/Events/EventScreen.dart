import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/dashBoardScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart'; // Assumed path
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({Key? key}) : super(key: key);
  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late Future<List<Event>> eventsFuture;

  List<Event> events = [];
  @override
  void initState() {
    super.initState();
    eventsFuture = fetchEvents();
  }

  // Fetch events from the backend
  Future<List<Event>> fetchEvents() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await
storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.serverUrl}/events'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<dynamic> eventsData = data;

        List<Event> events =
        eventsData.map((eventData) {
          return Event.fromJson(eventData as Map<String, dynamic>);
        }).toList();

        events.sort((a, b) => b.datetimeCreated.compareTo(a.datetimeCreated));

        return events;
      } else {
        throw Exception('Failed to load events. Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
      ),

      // FutureBuilder to display the events
      body: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.fetchUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final Map<String, dynamic> user = snapshot.data!;

            return FutureBuilder<List<Event>>(
                future: eventsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No Events found.'));
                  } else {
                    //save all events for reference
                    events = snapshot.data!;
                    return ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return EventItem(event: events[index]);
                      },
                    );
                  }
                });
          }
        },
      ),
    );
  }
}

//create Event Class
class Event {

  final int eventID;
  final String title;
  final String description;
  final String category;
  final int max_Participants;
  final String datetimeCreated;
  final String datetimeEvent;
  final double price;
  final int status;
  int? recurrence_type;
  int? recurrence_interval;
  String? country;
  String? street;
  String? city;
  String? zipcode;


  Event(
      {
        required this.eventID,
        required this.title,
        required this.description,
        required this.category,
        required this.max_Participants,
        required this.datetimeCreated,
        required this.datetimeEvent,
        required this.price,
        required this.status,
        required this.recurrence_type,
        required this.recurrence_interval,
        required this.country,
        required this.city,
        required this.street,
        required this.zipcode

      });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventID: json['event_id'],
      category: json['category'],
      title: json['title'],
      description: json['description'],
      max_Participants: json['max_participants'],
      datetimeCreated: json['datetime_created'],
      datetimeEvent: json['datetime_event'],
      price: json['price'],
      status: json['status'],
      recurrence_type: json['recurrence_type'],
      recurrence_interval: json['recurrence_interval'],
      country: json['country'],
      city: json['city'],
      street: json['street'],
      zipcode: json['zipcode']
    );
  }
}

//display a single event object in a ListTile
class EventItem extends StatelessWidget {

  final Event event;
  const EventItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.event),
      title: Text(event.title),
      subtitle: Text(event.description),
      //trailing: Icon(Icons.info), //hier noch eine onPressed Funktion für Friend Info/del/block etc
      trailing: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventInfoScreen(
                  event: event,
                ),
              ),
            );
          },
          icon: Icon(Icons.info)),
      onTap: () {
        //Open Dialog to either Send or Request Money
        requestOrSendDialog(context);
      },
    );
  }

  Future<dynamic> requestOrSendDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(event.title),
          content: Text(event.description),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Join'),
            ),
          ],
        );
      },
    );
  }
}

//create EventInfoScreen
class EventInfoScreen extends StatelessWidget {
  final Event event;
  const EventInfoScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
      ),
      body: Column(
        children: [
          Text(event.description),
          Text(event.category),
          Text(event.max_Participants.toString()),
          Text(event.datetimeEvent),
          Text(event.price.toString()),
          Text(event.status.toString()),
        ],
      ),
    );
  }
}

//create EventDetailsScreen


