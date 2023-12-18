import 'dart:convert';
import 'dart:typed_data';
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
      final token = await storage.read(key: 'token');

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


class Event {

  final int eventID;
  final String title;
  final String category;
  final String description;
  final int max_Participants;
  DateTime datetimeCreated;
  DateTime datetimeEvent;
  final double price;
  final int status;
  int? recurrence_type;
  int? recurrence_interval;
  String? country;
  String? street;
  String? city;
  String? zipcode;
  final creator_id;
  final creator_username;
  final user_id;


  final Map<String, IconData> iconMap = {
    'Book and Literature': Icons.menu_book_rounded,
    'Cultural and Arts': Icons.panorama,
    'Community': Icons.people_rounded,
    'Enviromental': Icons.park_rounded,
    'Fashion': Icons.local_mall_rounded,
    'Film and Entertainment': Icons.movie_creation_rounded,
    'Food and Drink': Icons.restaurant,
    'Gaming': Icons.sports_esports_rounded,
    'Health and Wellness': Icons.health_and_safety_rounded,
    'Science': Icons.science_rounded,
    'Sport': Icons.sports_martial_arts_rounded,
    'Technology and Innovation': Icons.biotech_outlined,
    'Travel and Adventure': Icons.travel_explore_rounded,
    'Professional': Icons.business_center_rounded,
  };

  bool isCreator(){
    if(creator_id == user_id){return true;}
    return false;
  }

  IconData getIconForCategory(String category) {
    // Check if the category exists in the map, otherwise use a default icon
    return iconMap.containsKey(category) ? iconMap[category]! : Icons.category;
  }

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
        required this.zipcode,
        required this.creator_id,
        required this.creator_username,
        required this.user_id
      });


  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
        eventID: json['event_id'],
        category: json['category'],
        title: json['title'],
        description: json['description'],
        max_Participants: json['max_participants'],
        datetimeCreated: DateTime.parse(json['datetime_created']),
        datetimeEvent: DateTime.parse(json['datetime_event']),
        price: (json['price'] as num).toDouble(),
        status: json['status'],
        recurrence_type: json['recurrence_type'],
        recurrence_interval: json['recurrence_interval'],
        country: json['country'],
        city: json['city'],
        street: json['street'],
        zipcode: json['zipcode'],
        creator_id: json['creator_id'],
        creator_username: json['creator_username'],
      user_id: json['user_id']
    );
  }
}


//Display a single event object in a ListTile
class EventItem extends StatelessWidget {

  final Event event;
  EventItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
          event.getIconForCategory(event.category),
      ),
      title: Text(event.title),
      subtitle: Text(event.creator_username),
      trailing: IconButton(
          onPressed: () {

            //Open Dialog to either Send or Request Money
            requestOrSendDialog(context);

          },
          icon: Icon(Icons.info)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventInfoScreen(
              event: event,
            ),
          ),
        );
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
              child: Text('Back'),
            ),
            event.isCreator()
            ?
            TextButton(
              onPressed: () {

                ApiService.joinEvent(event.eventID);
                Navigator.of(context).pop();
              },
              child: Text('Join')
            )
                :
            TextButton(
                onPressed: () {

                  Navigator.of(context).pop();
                },
                child: Text('Cancel Event')
            )
          ],
        );
      },
    );
  }
}






class EventInfoScreen extends StatelessWidget {
  
  final Event event;
  const EventInfoScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    bool isEmpty = event.country == '' && event.city == '' &&  event.street == '' && event.zipcode == '';
    bool isNull = event.price <= 0;

    return Scaffold(
      appBar: AppBar(
        title:
        Text(event.title)
      ),
      body: SingleChildScrollView(
        child:Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 16),
                Text(
                    'Event Information',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
                ),
                SizedBox(height: 12),
                const Divider(
                    height: 8,
                    thickness: 2
                ),
                SizedBox(height: 12),
                Padding(padding:
                EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.person_rounded),
                      SizedBox(width: 8),
                      Text(
                        'Creator: ${event.creator_username}',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        event.getIconForCategory(event.category)
                      ),
                      SizedBox(width: 8),
                      Text(
                        event.category,
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.description_rounded),
                      SizedBox(width: 8),
                      Text('Description: ',
                          style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
                SizedBox(height: 3),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(child:
                      Text(
                        event.description,
                        style: TextStyle(fontSize: 18),
                      ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.supervised_user_circle_rounded),
                      Text(
                        '  Participants: ${event.max_Participants.toString()}',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16),
                  child: EventDateSection(event: event),
                ),
                SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: EventTimeSection(event: event),
                ),
                SizedBox(height: 4),
                isEmpty
                    ?
                Container()
                    :
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.add_location_alt_rounded),
                      SizedBox(width: 8),
                      Text(
                        ' ${event.country}, ${event.city}, \n ${event.zipcode}, ${event.street}',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                isNull
                    ?
                Padding(padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.money_off_csred_rounded),
                      SizedBox(width: 8),
                      Text(
                        'Free',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
                    :
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.attach_money_rounded),
                      SizedBox(width: 8),
                      Text(
                        formatAmount(),
                        style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16)
                /*
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      child: const Text('Join',
                          style: TextStyle(fontSize: 18)),
                      onPressed: () {/* ... */},
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
                */
              ],
            ),
          ),
        ),
      ),
    );
  }

  String formatAmount() {
    return '${NumberFormat(" #,##0.00", "de_DE").format(event.price)} €'; // Example
  }

}


class EventDateSection extends StatelessWidget {

  final Event event;
  const EventDateSection({Key? key, required this.event})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.date_range_rounded),
            SizedBox(width: 8),
            Text(
              DateFormat('dd.MM.yyyy').format(event.datetimeEvent),
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ],
    );
  }
}



class EventTimeSection extends StatelessWidget {

  final Event event;
  const EventTimeSection({Key? key, required this.event})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.access_time_rounded),
            SizedBox(width: 8),
            Text(
              DateFormat('HH:mm').format(event.datetimeEvent),
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ],
    );
  }
}
