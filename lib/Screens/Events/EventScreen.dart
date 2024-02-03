import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/appDrawer.dart';
import 'package:flutter_application_1/Screens/Dashboard/dashBoardScreen.dart';
import 'package:flutter_application_1/Screens/Events/InviteToEventScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart'; // Assumed path
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart' as search_bar;
import 'package:flutter_application_1/Screens/Events/Event.dart';
import 'package:flutter_application_1/Screens/Events/EventInfoScreen.dart';
import 'package:path/path.dart';

/*
Status Overview
Event Status:
0 -> Canceled
1 -> Active
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
  bool isSearchMode = false;
  final TextEditingController searchController = TextEditingController();
  String currentSortOrder = 'All events';
  List<String> sortOptions = [
    'All events',
    'My events',
    'Invites',
    'Active',
    'Inactive'
  ];

  late int currentUserId;

  String currentCategoryOption = 'Category';
  List<String> possibleCategories = ['Category'];

  List<Event> events = [];
  List<Event> originalEvents = [];
  @override
  void initState() {
    super.initState();
    eventsFuture = fetchEvents();
    eventsFuture = fetchEvents().then((events) {
      originalEvents = List.from(events);
      return events;
    });
    // searchBar = search_bar.SearchBar(
    //   showClearButton: true,
    //   inBar: true,
    //   setState: setState,
    //   onSubmitted: onSubmitted,
    //   onChanged: onChanged,
    //   onCleared: onCleared,
    //   onClosed: onClosed,
    //   buildDefaultAppBar: buildAppBar,
    //   hintText: "Search",
    // );
  }

  List<Event> allEvents = [];
  void sortEvents(String sortOrder) {
    //reset the transactions list to the original list
    allEvents = List.from(originalEvents);
    print(currentUserId);
    // Sort the events based on the sort order
    switch (sortOrder) {
      case 'All events':
        break;
      case 'My events':
        allEvents.removeWhere((event) => event.creatorId != currentUserId);
        break;
      case 'Invites':
        allEvents.removeWhere((event) => event.user_event_status != 2);
        break;
      case 'Active':
        allEvents.removeWhere((event) =>
            event.status != 1 ||
            event.datetimeEvent.millisecondsSinceEpoch <
                DateTime.now().millisecondsSinceEpoch);
        break;
      case 'Inactive':
        allEvents.removeWhere((event) =>
            event.status == 1 &&
            event.datetimeEvent.millisecondsSinceEpoch >
                DateTime.now().millisecondsSinceEpoch);
        break;
    }
    // Update the Future to reflect the new sorted list
    setState(() {
      eventsFuture = Future.value(allEvents);
    });
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
        currentUserId = int.parse(userId);
        final List<dynamic> data = jsonDecode(response.body);
        final List<dynamic> eventsData = data;

        List<Event> filteredEvents = [];

        List<Event> events = eventsData.map((eventData) {
          return Event.fromJson(eventData as Map<String, dynamic>);
        }).toList();

        events.sort((a, b) {
          // First, sort by status (active events first)
          if (a.status == 1 && b.status != 1) {
            return -1; // a is active, b is not; move a up
          } else if (a.status != 1 && b.status == 1) {
            return 1; // b is active, a is not; move b up
          } else {
            // Both events have the same status, sort by datetimeEvent in reverse order
            return a.datetimeEvent
                .compareTo(b.datetimeEvent); // Swap a and b here
          }
        });

        /* Fill list for category list
        for (var event in events) {
          if (!possibleCategories.contains(event.category)) {
            possibleCategories.add(event.category);
          }
        }
        */

        // Set if User is Creator
        for (var event in events) {
          if (userId == event.creatorId.toString()) {
            setState(() {
              event.isCreator = true;
            });
          }
        }

        // switch (currentSortOrder) {
        //   case 'All events':
        //     if (currentCategoryOption == 'Category') {
        //       return events;
        //     } else if (currentCategoryOption != 'Category') {
        //       for (var event in events) {
        //         if (currentCategoryOption == event.category &&
        //             !filteredEvents.contains(event)) {
        //           filteredEvents.add(event);
        //         }
        //       }
        //       return filteredEvents;
        //     }
        //   case 'My events':
        //     if (currentCategoryOption == 'Category') {
        //       for (var event in events) {
        //         if (userId == event.creatorId.toString() &&
        //             !filteredEvents.contains(event)) {
        //           filteredEvents.add(event);
        //         }
        //       }
        //       return filteredEvents;
        //     } else if (currentCategoryOption != 'Category') {
        //       for (var event in events) {
        //         if (userId == event.creatorId.toString() &&
        //             currentCategoryOption == event.category &&
        //             !filteredEvents.contains(event)) {
        //           filteredEvents.add(event);
        //         }
        //       }
        //       return filteredEvents;
        //     }
        //   case 'Requests':
        //     for (var event in events) {
        //       if (event.status == 1 &&
        //           event.user_event_status == 2 &&
        //           !filteredEvents.contains(event)) {
        //         filteredEvents.add(event);
        //       }
        //     }
        //     return filteredEvents;
        //   case 'Active':
        //     if (currentCategoryOption == 'Category') {
        //       for (var event in events) {
        //         if (event.status == 1 &&
        //             event.datetimeEvent.millisecondsSinceEpoch >
        //                 DateTime.now().millisecondsSinceEpoch &&
        //             !filteredEvents.contains(event)) {
        //           filteredEvents.add(event);
        //         }
        //       }
        //       return filteredEvents;
        //     } else if (currentCategoryOption != 'Category') {
        //       for (var event in events) {
        //         if (event.status == 1 &&
        //             currentCategoryOption == event.category &&
        //             event.datetimeEvent.millisecondsSinceEpoch >
        //                 DateTime.now().millisecondsSinceEpoch &&
        //             !filteredEvents.contains(event)) {
        //           filteredEvents.add(event);
        //         }
        //       }
        //       return filteredEvents;
        //     }
        //   case 'Inactive':
        //     if (currentCategoryOption == 'Category') {
        //       for (var event in events) {
        //         if (event.status != 1 ||
        //             event.datetimeEvent.millisecondsSinceEpoch <
        //                 DateTime.now().millisecondsSinceEpoch) {
        //           if (!filteredEvents.contains(event)) {
        //             filteredEvents.add(event);
        //           }
        //         }
        //       }
        //       return filteredEvents;
        //     } else if (currentCategoryOption != 'Category') {
        //       for (var event in events) {
        //         if (event.status != 1 ||
        //             event.datetimeEvent.millisecondsSinceEpoch <
        //                 DateTime.now().millisecondsSinceEpoch) {
        //           if (currentCategoryOption == event.category &&
        //               !filteredEvents.contains(event)) {
        //             filteredEvents.add(event);
        //           }
        //         }
        //       }
        //       return filteredEvents;
        //     }
        // }
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
      title: isSearchMode
          ? TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Search Events...",
                border: InputBorder.none,
              ),
              onChanged: onSearchTextChanged,
            )
          : Text(' History'),
      actions: isSearchMode
          ? [
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    allEvents = List.from(originalEvents);
                    isSearchMode = false;
                    searchController.clear();
                    onSearchTextChanged('');
                  });
                },
              ),
            ]
          : [
              DropdownButton<String>(
                alignment: Alignment.center,
                underline: Container(),
                value: currentSortOrder,
                icon: Icon(Icons.sort),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      currentSortOrder = newValue;
                      sortEvents(currentSortOrder);
                    });
                  }
                },
                items:
                    sortOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                    onTap: () {
                      setState(() {
                        currentSortOrder = value;
                        sortEvents(currentSortOrder);
                      });
                    },
                  );
                }).toList(),
              ),
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    isSearchMode = true;
                    currentSortOrder = 'All events';
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Info"),
                          content: const Text(
                              "This is the event screen. Here you can see all events, join them, create new events and invite other users to your events.\n\nYou can also filter the events by category and sort them by different criteria.\n\nRefresh the event list by tapping the refresh button on the bottom right."),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text("Close"))
                          ],
                        );
                      });
                },
              ),
            ],
    );
  }

  void onSearchTextChanged(String query) {
    List<Event> filteredEvents = [];
    if (query.isEmpty) {
      filteredEvents = allEvents;
    } else {
      filteredEvents = allEvents.where((transaction) {
        return transaction.title.toLowerCase().contains(query.toLowerCase()) ||
            transaction.creatorUsername
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            transaction.category.toLowerCase().contains(query.toLowerCase()) ||
            transaction.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }

    setState(() {
      eventsFuture = Future.value(filteredEvents);
    });
  }
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
  //       searchBar.getSearchAction(context)
  //     ],
  //   );
  // }

  // Future<void> onSubmitted(String value) async {
  //   if (value.isNotEmpty) {
  //     List<Event> filteredEvents = events
  //         .where((events) =>
  //             events.title.toLowerCase().contains(value.toLowerCase()) ||
  //             events.creatorUsername
  //                 .toLowerCase()
  //                 .contains(value.toLowerCase()))
  //         .toList();
  //     setState(() {
  //       eventsFuture = Future.value(filteredEvents);
  //     });
  //   } else {
  //     setState(() {
  //       eventsFuture = fetchEvents();
  //     });
  //   }
  // }

  // Future<void> onChanged(String value) async {
  //   if (value.isNotEmpty) {
  //     List<Event> filteredEvents = events
  //         .where((events) =>
  //             events.title.toLowerCase().contains(value.toLowerCase()) ||
  //             events.creatorUsername
  //                 .toLowerCase()
  //                 .contains(value.toLowerCase()))
  //         .toList();
  //     setState(() {
  //       eventsFuture = Future.value(filteredEvents);
  //     });
  //   } else {
  //     setState(() {
  //       eventsFuture = fetchEvents();
  //     });
  //   }
  // }

  // Future<void> onCleared() async {
  //   // Handle search bar cleared
  //   // Update the UI to show the original list without filtering
  //   setState(() {
  //     eventsFuture = fetchEvents();
  //   });
  // }

  // Future<void> onClosed() async {
  //   //update the UI to show the original list without filtering
  //   setState(() {
  //     eventsFuture = fetchEvents();
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: searchBar.build(context),
      appBar: buildAppBar(context),
      drawer: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.fetchUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Drawer(); // You can return a loading state or an empty drawer
          } else if (snapshot.hasError) {
            return Drawer(); // Handle error state or return an empty drawer
          } else {
            final Map<String, dynamic> user = snapshot.data!;
            return AppDrawer(user: user);
          }
        },
      ),
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
      body: FutureBuilder<List<Event>>(
        future: eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Events found.'));
          } else {
            // Save all events for reference
            events = snapshot.data!;
            return ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                return EventItem(event: events[index]);
              },
            );
          }
        },
      ),
    );
  }

  /*@override
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
  }*/
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
    // event.status != 1 ? iconColor = Colors.red : iconColor;

    // determine the color of the icon and text based on if the user is part of the event
    //check if event is canceled, if so, set icon color to red always
    // if the user is part of the event, the icon will be green
    // if the user is not part of the event, and the event is not full or canceled, the icon will be orange
    // if the user is the creator of the event, the icon will be blue
    // if the user is not part of the event and the event is full, the icon will be red
    if (event.status == 0) {
      iconColor = Colors.red;
    } else if (event.isCreator && event.status == 1) {
      iconColor = Colors.blue;
    } else if (event.user_event_status == 1) {
      iconColor = Colors.green;
    } else if (event.user_event_status == 2) {
      iconColor = Colors.orange;
    } else if (event.user_event_status == 0) {
      iconColor = Colors.red;
    }

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
  const UpcomingEvents({Key? key, required this.fetchEventsFunction})
      : super(key: key);
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
          if (events.isNotEmpty) {
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
          } else {
            return Column(
              children: [
                const Text('No upcoming Events',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              ],
            );
          }
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
