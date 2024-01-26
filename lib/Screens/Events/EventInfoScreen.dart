import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Events/InviteToEventScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart'; // Assumed path
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/Screens/Events/Event.dart';
import 'package:http/http.dart' as http;
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
                      eventId: event.eventID, allowInvite: true),
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
                      eventId: event.eventID, allowInvite: false),
                ),
              );
            },
            icon: Icon(Icons.people_rounded),
            label: Text('View participants'),
          );
        }
      } else {
        // Event is Active && User not Creator
        return TextButton(
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
                      child: Text('Yes'),
                    )
                  ],
                );
              },
            );
          },
          child: Text('Leave event'),
        );
      }
    }
    if (event.isCreator) {
      // Event is unactive && User = Creator
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InviteToEventScreen(
                  eventId: event.eventID, allowInvite: false),
            ),
          );
        },
        icon: Icon(Icons.people_rounded),
        label: Text('View participants'),
      );
    } else {
      return Container();
    }
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
                        title: Text('${event.title}'),
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
                          TextButton(
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
