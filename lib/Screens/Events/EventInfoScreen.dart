import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Events/InviteToEventScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart'; // Assumed path
import 'package:intl/intl.dart';
import 'package:flutter_application_1/Screens/Events/Event.dart';
import 'package:flutter_application_1/Screens/Events/EditEventScreen.dart'
    as edit;
import 'EventScreen.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Info"),
                      content: const Text(
                          "This is the event information screen. Here you can see all the information about the selected event.\n\nYou can also edit or cancel the event if you are the creator of the event\n\nIf you are not the creator of the event, you can join the event if it is not full or leave the event if you are already joined."),
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
                              ? event.status == 1
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
                      showParticipantsButton(event, context),
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
                                  Icon(Icons.euro),
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
                                  Icon(Icons.euro),
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
                          buildButton(event, context)
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

  Widget showParticipantsButton(Event event, BuildContext context) {
    if (event.status == 1 && event.user_event_status != 0 && !event.isCreator) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => InviteToEventScreen(
                          eventId: event.eventID,
                          allowInvite: false,
                          iAmParticipant: true)),
                );
              },
              child: Icon(Icons.supervised_user_circle_rounded),
            ),
            Text(
              '  Participants: ${event.participants.toString()} / ${event.maxParticipants.toString()}',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 40),
            TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => InviteToEventScreen(
                            eventId: event.eventID,
                            allowInvite: false,
                            iAmParticipant: true)),
                  );
                },
                child: Text('View')),
          ],
        ),
      );
    } else {
      return Padding(
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
      );
    }
  }

  Widget buildButton(Event event, BuildContext context) {
    // Event is active
    if (event.status == 1) {
      // User is Creator
      if (event.isCreator) {
        // Event is not completly full
        if (event.notFullEvent()) {
          // Event is active && User is Creator && Event is not full
          return ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                textStyle:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InviteToEventScreen(
                      eventId: event.eventID,
                      allowInvite: true,
                      iAmParticipant: false),
                ),
              );
            },
            icon: Icon(Icons.emoji_people_rounded),
            label: Text('Invite'),
          );
        } else {
          // Event is active && User is Creator && Event IS full
          return ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                textStyle:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InviteToEventScreen(
                      eventId: event.eventID,
                      allowInvite: false,
                      iAmParticipant: false),
                ),
              );
            },
            icon: Icon(Icons.people_rounded),
            label: Text('View participants'),
          );
        }
      } else if (event.user_event_status == 1) {
        // Event is Active && User not Creator && User is already joined
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Leaving ${event.title}'),
                  content: Text(
                      'Are you sure you want to leave the Event "${event.title}"?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Back'),
                    ),
                    TextButton(
                      onPressed: () async {
                        int result = await ApiService.leaveEvent(event.eventID);
                        if (result == 401) {
                          Navigator.of(context).pop();
                          showErrorSnackBar(
                              context, 'Event was already leaved!');
                        } else if (result == 0) {
                          Navigator.of(context).pop();
                          showErrorSnackBar(context, 'Leaving event failed!');
                        } else if (result == 1) {
                          Navigator.of(context).pop();
                          showSuccessSnackBar(
                              context, 'Leaving event was successful!');
                        }
                      },
                      child: Text('Leave'),
                    )
                  ],
                );
              },
            );
          },
          child: Text('Leave'),
        );
      } else if (event.user_event_status == 2) {
        if (event.maxParticipants > event.participants) {
          // User is not joined
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    textStyle:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Decline ${event.title}'),
                        content: Text(
                            'Are you sure you want to decline the Event "${event.title}"?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              int result =
                                  await ApiService.declineEvent(event.eventID);
                              if (result == 401) {
                                Navigator.of(context).pop();
                                showErrorSnackBar(
                                    context, 'Event was already declined!');
                              } else if (result == 0) {
                                Navigator.of(context).pop();
                                showErrorSnackBar(
                                    context, 'Declining event failed!');
                              } else if (result == 1) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EventScreen()),
                                );
                                showSuccessSnackBar(
                                    context, 'Declining event was successful!');
                              }
                            },
                            child: Text('Decline'),
                          )
                        ],
                      );
                    },
                  );
                },
                child: Text('Decline'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    textStyle:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Joining ${event.title}'),
                        content: Text(
                            'Attention!\n No refund if you decide to leave the event at a later time!\n Do you want to join "${event.title}"?',
                            style: TextStyle(fontSize: 16)),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Back'),
                          ),
                          TextButton(
                            onPressed: () async {
                              int result = await ApiService.joinEvent(
                                  event.creatorUsername,
                                  event.price,
                                  event.title,
                                  event.eventID);
                              if (result == 400) {
                                Navigator.of(context).pop();
                                showErrorSnackBar(
                                    context, 'Joining event failed');
                              } else if (result == 401) {
                                Navigator.of(context).pop();
                                showErrorSnackBar(
                                    context, 'You already joined the event');
                              } else if (result == 402) {
                                Navigator.of(context).pop();
                                showErrorSnackBar(context,
                                    'You do not have enough money to join the event.');
                              } else if (result == 200) {
                                Navigator.of(context).pop();
                                showSuccessSnackBar(
                                    context, 'Joining event was successful');
                              }
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EventScreen()));
                            },
                            child: Text('Yes'),
                          )
                        ],
                      );
                    },
                  );
                },
                child: Text('Join'),
              )
            ],
          );
        } else {
          // User is not joined but event is full
          return ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                textStyle:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Remove ${event.title}'),
                    content: Text(
                        'Are you sure you want to remove the Event "${event.title}"?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          int result =
                              await ApiService.leaveEvent(event.eventID);
                          if (result == 401) {
                            Navigator.of(context).pop();
                            showErrorSnackBar(
                                context, 'Event was already removed!');
                          } else if (result == 0) {
                            Navigator.of(context).pop();
                            showErrorSnackBar(
                                context, 'Removing event failed!');
                          } else if (result == 1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => EventScreen()),
                            );
                            showSuccessSnackBar(
                                context, 'Removing event was successful!');
                          }
                        },
                        child: Text('Remove'),
                      )
                    ],
                  );
                },
              );
            },
            label: Text('Remove'),
            // label: Text('Leave Event'),
            icon: Icon(Icons.disabled_visible_rounded),
          );
        }
      }
    }
    if (event.isCreator) {
      // Event is inactive && User = Creator
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            // Define your second button here
            onPressed: () async {
              if (await ApiService.deleteEvent(event.eventID) == 200) {
                Navigator.of(context).pop();
                showSuccessSnackBar(context, 'Deleting event was successful!');
              } else if (await ApiService.deleteEvent(event.eventID) == 401) {
                Navigator.of(context).pop();
                showErrorSnackBar(context, 'Event was already deleted!');
              } else {
                showErrorSnackBar(context, 'Could not delete event!');
              }
            },
            icon: Icon(
                Icons.delete_forever_rounded), // Replace with your desired icon
            label: Text('Delete event'), // Replace with your desired label
          ),
          SizedBox(height: 8), // Adjust the spacing between buttons
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InviteToEventScreen(
                    eventId: event.eventID,
                    allowInvite: false,
                    iAmParticipant: false,
                  ),
                ),
              );
            },
            icon: Icon(Icons.people_rounded),
            label: Text('View participants'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            // Define your second button here
            onPressed: () async {
              if (await ApiService.deleteEvent(event.eventID) == 200) {
                Navigator.of(context).pop();
                showSuccessSnackBar(context, 'Deleting event was successful!');
              } else if (await ApiService.deleteEvent(event.eventID) == 401) {
                Navigator.of(context).pop();
                showErrorSnackBar(context, 'Event was already deleted!');
              } else {
                showErrorSnackBar(context, 'Could not delete event!');
              }
            },
            icon: Icon(
                Icons.delete_forever_rounded), // Replace with your desired icon
            label: Text('Delete event'), // Replace with your desired label
          ),
          SizedBox(height: 8), // Adjust the spacing between buttons
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InviteToEventScreen(
                    eventId: event.eventID,
                    allowInvite: false,
                    iAmParticipant: false,
                  ),
                ),
              );
            },
            icon: Icon(Icons.people_rounded),
            label: Text('View participants'),
          ),
        ],
      );
    }
  }

  String formatAmount() {
    return '${NumberFormat("#,##0.00", "de_DE").format(event.price)} €';
  }

  Future<dynamic> editOrcancelEvent(BuildContext context) async {
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
              style: ElevatedButton.styleFrom(
                  textStyle:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(
                    context); //closes dialog so pressing return wont open it again
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Cancel ${event.title}'),
                        content: Text(
                            'Are you sure you want to cancel the Event "${event.title}"?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('No'),
                          ),
                          SizedBox(width: 32),
                          ElevatedButton(
                            onPressed: () async {
                              int result =
                                  await ApiService.cancelEvent(event.eventID);
                              if (result == 401) {
                                Navigator.of(context).pop();
                                showErrorSnackBar(
                                    context, 'Event was already canceled!');
                              } else if (result == 0) {
                                Navigator.of(context).pop();
                                showErrorSnackBar(
                                    context, 'Canceling event failed!');
                              } else if (result == 1) {
                                Navigator.of(context).pop();
                                showSuccessSnackBar(
                                    context, 'Canceling event was successful!');
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => EventScreen()));
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
              style: ElevatedButton.styleFrom(
                  textStyle:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              child: Text('Edit'),
              onPressed: () {
                Navigator.pop(
                    context); //closes dialog so pressing return wont open it again
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => edit.EditEventScreen(
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
