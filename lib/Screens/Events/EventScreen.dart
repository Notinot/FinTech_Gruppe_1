import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/dashBoardScreen.dart';
import 'package:flutter_application_1/Screens/Events/InviteToEventScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart'; // Assumed path
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart' as search_bar;

/*
Status Overview
Event Status:
0 -> Canceled
1 -> Active
(not implemented yet)
2 -> Event Time pasted

User_Event Status:
0 -> Leaved
1 -> Joined
2 -> Pending (received invite)
*/

class EventScreen extends StatefulWidget {
  const EventScreen({Key? key}) : super(key: key);
  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late Future<List<Event>> eventsFuture;
  late search_bar.SearchBar searchBar;

  String currentSortOrder = 'All events';
  List<String> sortOptions = [
    'All events',
    'My events',
    'Active',
    'Inactive'
  ];

  String currentCategoryOption = 'Category';
  List<String> possibleCategories = ['Category'];


  List<Event> events = [];

  @override
  void initState() {
    super.initState();
    eventsFuture = fetchEvents();
    searchBar = search_bar.SearchBar(
      showClearButton: true,
      inBar: true,
      setState: setState,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      onCleared: onCleared,
      onClosed: onClosed,
      buildDefaultAppBar: buildAppBar,
      hintText: "Search",
    );
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
        String userId = await ApiService.fetchUserId();
        final List<dynamic> data = jsonDecode(response.body);
        final List<dynamic> eventsData = data;

        List<Event> filteredEvents = [];

        List<Event> events = eventsData.map((eventData) {
          return Event.fromJson(eventData as Map<String, dynamic>);
        }).toList();

        // Sort by status and datetime
        events.sort((a, b) {
          // First, sort by status (active events first)
          if (a.status == 1 && b.status != 1) {
            return -1; // a is active, b is not; move a up
          } else if (a.status != 1 && b.status == 1) {
            return 1; // b is active, a is not; move b up
          } else {
            // Both events have the same status, sort by datetimeEvent
            return b.datetimeEvent.compareTo(a.datetimeEvent);
          }
        });

        // Fill list for category list
        for (var event in events) {
          if (!possibleCategories.contains(event.category)) {
            possibleCategories.add(event.category);
          }
        }

        // Set if User is Creator
        for (var event in events) {
          if (userId == event.creatorId.toString()) {
            setState(() {
              event.isCreator = true;
            });
          }
        }

        switch (currentSortOrder) {
          case 'All events':
            if (currentCategoryOption == 'Category') {
              return events;
            } else if (currentCategoryOption != 'Category') {
              for (var event in events) {
                if (currentCategoryOption == event.category &&
                    !filteredEvents.contains(event)) {
                  filteredEvents.add(event);
                }
              }
              return filteredEvents;
            }
          case 'My events':
            if (currentCategoryOption == 'Category') {
              for (var event in events) {
                if (userId == event.creatorId.toString() &&
                    !filteredEvents.contains(event)) {
                  filteredEvents.add(event);
                }
              }
              return filteredEvents;
            } else if (currentCategoryOption != 'Category') {
              for (var event in events) {
                if (userId == event.creatorId.toString() &&
                    currentCategoryOption == event.category &&
                    !filteredEvents.contains(event)) {
                  filteredEvents.add(event);
                }
              }
              return filteredEvents;
            }
          case 'Active':
            if (currentCategoryOption == 'Category') {
              for (var event in events) {
                if (event.status == 1 &&
                    event.datetimeEvent.millisecondsSinceEpoch >
                        DateTime.now().millisecondsSinceEpoch &&
                    !filteredEvents.contains(event)) {
                  filteredEvents.add(event);
                }
              }
              return filteredEvents;
            } else if (currentCategoryOption != 'Category') {
              for (var event in events) {
                if (event.status == 1 &&
                    currentCategoryOption == event.category &&
                    event.datetimeEvent.millisecondsSinceEpoch >
                        DateTime.now().millisecondsSinceEpoch &&
                    !filteredEvents.contains(event)) {
                  filteredEvents.add(event);
                }
              }
              return filteredEvents;
            }
          case 'Inactive':
            if (currentCategoryOption == 'Category') {
              for (var event in events) {
                if (event.status != 1 ||
                    event.datetimeEvent.millisecondsSinceEpoch <
                        DateTime.now().millisecondsSinceEpoch) {
                  if (!filteredEvents.contains(event)) {
                    filteredEvents.add(event);
                  }
                }
              }
              return filteredEvents;
            } else if (currentCategoryOption != 'Category') {
              for (var event in events) {
                if (event.status != 1 ||
                    event.datetimeEvent.millisecondsSinceEpoch <
                        DateTime.now().millisecondsSinceEpoch) {
                  if (currentCategoryOption == event.category &&
                      !filteredEvents.contains(event)) {
                    filteredEvents.add(event);
                  }
                }
              }
              return filteredEvents;
            }
        }
        return events;
      } else {
        throw Exception('Failed to load events. Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Function to build the AppBar
  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: Text('Events'),
      leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Custom behavior when the back button is pressed
            // For example, you can navigate to a different screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          }),
        actions: [
        DropdownButton<String>(
          value: currentSortOrder,
          icon: Icon(Icons.sort),
          onChanged: (String? newValue) {
            if(newValue != null){
              setState(() {
                currentSortOrder = newValue;
              });
            }
          },
          items: sortOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
              onTap: () {
                setState(() {
                  currentSortOrder = value;
                  eventsFuture = fetchEvents();
                });
              },
            );
          }).toList(),
        ),
        // Not implemented because of missing Space!
        /*
        DropdownButton<String>(
          value: currentCategoryOption,
          icon: Icon(Icons.sort),
          onChanged: (String? newValue) {
            if(newValue != null){
              setState(() {
                currentCategoryOption = newValue;
              });
            }
          },
          items: possibleCategories.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
              onTap: () {
                setState(() {
                  currentCategoryOption = value;
                  eventsFuture = fetchEvents();
                });
              },
            );
          }).toList(),
        ),
        */
        searchBar.getSearchAction(context)
      ],
    );
  }

  Future<void> onSubmitted(String value) async {
    if (value.isNotEmpty) {
      List<Event> filteredEvents = events
          .where((events) =>
              events.title.toLowerCase().contains(value.toLowerCase()) ||
              events.creatorUsername
                  .toLowerCase()
                  .contains(value.toLowerCase()))
          .toList();
      setState(() {
        eventsFuture = Future.value(filteredEvents);
      });
    } else {
      setState(() {
        eventsFuture = fetchEvents();
      });
    }
  }

  Future<void> onChanged(String value) async {
    if (value.isNotEmpty) {
      List<Event> filteredEvents = events
          .where((events) =>
              events.title.toLowerCase().contains(value.toLowerCase()) ||
              events.creatorUsername
                  .toLowerCase()
                  .contains(value.toLowerCase()))
          .toList();
      setState(() {
        eventsFuture = Future.value(filteredEvents);
      });
    } else {
      setState(() {
        eventsFuture = fetchEvents();
      });
    }
  }

  Future<void> onCleared() async {
    // Handle search bar cleared
    // Update the UI to show the original list without filtering
    setState(() {
      eventsFuture = fetchEvents();
    });
  }

  Future<void> onClosed() async {
    //update the UI to show the original list without filtering
    setState(() {
      eventsFuture = fetchEvents();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: searchBar.build(context),
      //floating action button to refresh the transaction history screen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            currentSortOrder = 'All events';
            currentCategoryOption = 'Category';
            eventsFuture = fetchEvents();
          });
        },
        child: const Icon(Icons.refresh),
      ),

      // FutureBuilder to display the events
      body: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.fetchUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
  final int participants;
  final int maxParticipants;
  DateTime datetimeCreated;
  DateTime datetimeEvent;
  final double price;
  final int status;
  int? recurrenceType;
  int? recurrenceInterval;
  String? country;
  String? street;
  String? city;
  String? zipcode;
  final creatorUsername;
  final creatorId;
  bool isCreator;

  Event({
    required this.eventID,
    required this.title,
    required this.description,
    required this.category,
    required this.participants,
    required this.maxParticipants,
    required this.datetimeCreated,
    required this.datetimeEvent,
    required this.price,
    required this.status,
    required this.recurrenceType,
    required this.recurrenceInterval,
    required this.country,
    required this.city,
    required this.street,
    required this.zipcode,
    required this.creatorUsername,
    required this.creatorId,
    required this.isCreator,
  });

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

  IconData getIconForCategory(String category) {
    // Check if the category exists in the map, otherwise use a default icon
    if (status != 1) {
      return Icons.do_disturb;
    } else if (datetimeEvent.millisecondsSinceEpoch <
        DateTime.now().millisecondsSinceEpoch) {
      return Icons.update_disabled_rounded;
    }

    return iconMap.containsKey(category) ? iconMap[category]! : Icons.category;
  }

  Future<void> checkIfCreator() async {
    String userId = await ApiService.fetchUserId();
    if(creatorId.toString() == userId){
      isCreator = true;
    }
  }

  bool notOutDatedEvent(DateTime eventTime) {
    if (eventTime.millisecondsSinceEpoch >
        DateTime.now().millisecondsSinceEpoch) {
      return true;
    }
    return false;
  }

  bool notFullEvent() {
    if (participants < maxParticipants) {
      return true;
    }
    return false;
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventID: json['event_id'],
      category: json['category'],
      title: json['title'],
      description: json['description'],
      participants: json['participants'],
      maxParticipants: json['max_participants'],
      datetimeCreated: DateTime.parse(json['datetime_created']),
      datetimeEvent: DateTime.parse(json['datetime_event']),
      price: (json['price'] as num).toDouble(),
      status: json['status'],
      recurrenceType: json['recurrence_type'],
      recurrenceInterval: json['recurrence_interval'],
      country: json['country'],
      city: json['city'],
      street: json['street'],
      zipcode: json['zipcode'],
      creatorUsername: json['creator_username'],
      creatorId: json['creator_id'],
      isCreator: false,
    );
  }

  static Future<void> eventService(List<Event> events) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token not found');
      }

      List<Event> checkingEvents = [];

      // Get all repeatable Events
      for (var event in events) {
        if (event.recurrenceType != 0 && !checkingEvents.contains(event)) {
          checkingEvents.add(event);
        }
      }

      for (var event in checkingEvents) {
        if (event.datetimeEvent.compareTo(DateTime.now()) < 0) {
          switch (event.recurrenceType) {
            case 1:
              event.datetimeEvent =
                    event.datetimeEvent.add(Duration(days: 7));
              event.recurrenceInterval = (event.recurrenceInterval! + 1)!;
              case 2:
                // Needs to be improved
                event.datetimeEvent =
                    event.datetimeEvent.add(Duration(days: 30));
                event.recurrenceInterval = (event.recurrenceInterval! + 1)!;
              case 3:
                event.datetimeEvent =
                    event.datetimeEvent.add(Duration(days: 365));
                event.recurrenceInterval = (event.recurrenceInterval! + 1)!;
            }
          }
        }

        try {
          List<Map<String, dynamic>> eventsJson =
              checkingEvents.map((i) => i.toJson()).toList();

          String body = jsonEncode(eventsJson);
          print(body);
          ApiService.EventService(body);

        } catch (e) {
          print(e);
        }

    } catch (e) {
      print(e.toString());
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': this.eventID,
      'datetime_event': this.datetimeEvent.toString().substring(
          0, this.datetimeEvent.toString().length - 5), // Use UTC time
      'recurrence_interval': this.recurrenceInterval,
    };
  }
}

//Display a single event object in a ListTile
class EventItem extends StatelessWidget {
  final Event event;
  EventItem({super.key, required this.event});

  bool isFree() {
    return event.price <= 0;
  }

  @override
  Widget build(BuildContext context) {
    Color? iconColor;
    event.status != 1 ? iconColor = Colors.red : iconColor;

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        child: Hero(
          tag: 'event_${event.eventID}',
          child: Card(
            elevation: 2.0,
            child: ListTile(
              leading: Icon(
                event.getIconForCategory(event.category),
                color: iconColor,
              ),
              title: Text(event.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      padding: EdgeInsets.all(2),
                      child: isFree()
                          ? Text('Free',
                              style: TextStyle(fontWeight: FontWeight.bold))
                          : Text(
                              '${NumberFormat("#,##0.00", "de_DE").format(event.price)}\€',
                            )),
                  Container(
                    padding: EdgeInsets.all(2),
                    child: Text(event.creatorUsername),
                  ),
                ],
              ),
              trailing: Text(
                '${DateFormat('dd/MM/yyyy').format(event.datetimeEvent)}\n${DateFormat('HH:mm').format(event.datetimeEvent)}',
                textAlign: TextAlign.right,
              ),
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
            ),
          ),
        ));
  }
}

class EventInfoScreen extends StatelessWidget {
  final Event event;

  const EventInfoScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isEmpty = event.country == '' &&
        event.city == '' &&
        event.street == '' &&
        event.zipcode == '';
    bool isNull = event.price <= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
      ),
      body: Hero(
        tag: 'event_${event.eventID}',
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 20,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: SingleChildScrollView(
              child: Padding(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Event Information',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 24),
                          event.isCreator
                              ? event.notOutDatedEvent(event.datetimeEvent)
                                  ? InkWell(
                                      onTap: () {
                                        editOrcancelEvent(context);
                                      },
                                      child: Icon(
                                        Icons.settings,
                                        color: Colors.grey,
                                      ))
                                  : Container()
                              : Container()
                        ],
                      ),
                      SizedBox(height: 12),
                      const Divider(height: 8, thickness: 2),
                      SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(Icons.person_rounded),
                            SizedBox(width: 8),
                            Text(
                              'Creator: ${event.creatorUsername}',
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
                            Icon(event.getIconForCategory(event.category)),
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
                            Text(
                              'Description: ',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 3),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 50),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
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
                              '  Participants: ${event.participants.toString()} / ${event.maxParticipants.toString()}',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: EventDateSection(event: event),
                      ),
                      SizedBox(height: 4),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: EventTimeSection(event: event),
                      ),
                      SizedBox(height: 4),
                      isEmpty
                          ? Container()
                          : Padding(
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
                          ? Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
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
                          : Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.attach_money_rounded),
                                  SizedBox(width: 8),
                                  Text(
                                    formatAmount(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                'Back',
                                style: TextStyle(fontSize: 16),
                              )),
                          SizedBox(width: 20),
                          event.status != 1
                              ? Container()
                              : event.isCreator
                                  ? event.notOutDatedEvent(event.datetimeEvent)
                                      ? event.notFullEvent()
                                          ? ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                  textStyle: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15)),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        InviteToEventScreen(
                                                            eventId:
                                                                event.eventID),
                                                  ),
                                                );
                                              },
                                              icon: Icon(
                                                  Icons.emoji_people_rounded),
                                              label: Text('Invite'),
                                            )
                                          : Container()
                                      : Container()
                                  : event.notOutDatedEvent(event.datetimeEvent)
                                      ? TextButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text(
                                                      'Leaving ${event.title}'),
                                                  content: Text(
                                                      'Are you sure you want to leave the Event "${event.title}"?'),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text('Back'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        int result =
                                                            await ApiService
                                                                .leaveEvent(event
                                                                    .eventID);
                                                        if (result == 401) {
                                                          Navigator.of(context)
                                                              .pop();
                                                          showErrorSnackBar(
                                                              context,
                                                              'Event was already leaved!');
                                                        } else if (result ==
                                                            0) {
                                                          Navigator.of(context)
                                                              .pop();
                                                          showErrorSnackBar(
                                                              context,
                                                              'Leaving event failed!');
                                                        } else if (result ==
                                                            1) {
                                                          Navigator.of(context)
                                                              .pop();
                                                          showSuccessSnackBar(
                                                              context,
                                                              'Leaving event was successful!');
                                                        }
                                                      },
                                                      child: Text('Yes'),
                                                    )
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          child: Text('Leave event'),
                                        )
                                      : Container()
                        ],
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String formatAmount() {
    return '${NumberFormat("#,##0.00", "de_DE").format(event.price)} €';
  }

  Future<dynamic> editOrcancelEvent(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(event.title),
          content: Text('Edit or Cancel Event'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Back'),
              child: const Text('Back'),
            ),
            ElevatedButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(
                    context); //closes dialog so pressing return wont open it again
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                            '${event.title}'),
                        content: Text(
                            'Are you sure you want to cancel the Event "${event.title}"?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pop();
                            },
                            child: Text('No'),
                          ),
                          SizedBox(width: 32),
                          TextButton(
                            onPressed: () async {
                              int result =
                              await ApiService
                                  .cancelEvent(event
                                  .eventID);
                              if (result == 401) {
                                Navigator.of(context)
                                    .pop();
                                showErrorSnackBar(
                                    context,
                                    'Event was already canceled!');
                              } else if (result == 0) {
                                Navigator.of(context)
                                    .pop();
                                showErrorSnackBar(
                                    context,
                                    'Canceling event failed!');
                              } else if (result == 1) {
                                Navigator.of(context)
                                    .pop();
                                showSuccessSnackBar(
                                    context,
                                    'Canceling event was successful!');
                              }
                            },
                            child: Text('Yes'),
                          )
                        ],
                      );
                    });
              },
            ),
            ElevatedButton(
              child: Text('Edit'),
              onPressed: () {
                Navigator.pop(
                    context); //closes dialog so pressing return wont open it again
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEventScreen(
                      event: event,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

}


class EditEventScreen extends StatelessWidget {

  final Event event;
  const EditEventScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}



class EventDateSection extends StatelessWidget {
  final Event event;
  const EventDateSection({Key? key, required this.event}) : super(key: key);

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
  const EventTimeSection({Key? key, required this.event}) : super(key: key);

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

class UpcomingEvents extends StatelessWidget {
  const UpcomingEvents({Key? key, required this.fetchEventsFunction}) : super(key: key);
  final Future<List<Event>> Function() fetchEventsFunction;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Event>>(
      future: fetchEventsFunction(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No upcoming events');
        } else {
          List<Event> events = snapshot.data!;
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
      },
    );
  }
}


void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ),
  );
}
