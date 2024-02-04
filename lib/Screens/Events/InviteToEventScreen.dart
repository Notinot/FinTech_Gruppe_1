import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/dashBoardScreen.dart';
import 'package:flutter_application_1/Screens/Events/EventScreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/Screens/api_service.dart';

class InviteToEventScreen extends StatefulWidget {
  final int eventId;
  final bool allowInvite;
  final bool iAmParticipant;
  InviteToEventScreen(
      {required this.eventId,
      required this.allowInvite,
      required this.iAmParticipant});

  @override
  _InviteToEventScreenState createState() => _InviteToEventScreenState();
}

class _InviteToEventScreenState extends State<InviteToEventScreen> {
  final TextEditingController recipientController = TextEditingController();
  Color recipientBorderColor = Colors.grey;
  final String recipient = '';

  @override
  Widget build(BuildContext context) {
    final Future<List<String>> joinedParticipants =
        ApiService.fetchParticipants(widget.eventId, 1);
    final Future<List<String>> invitedParticipants =
        ApiService.fetchParticipants(widget.eventId, 2);

    if (widget.iAmParticipant == false) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Event Participants'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate back when the back button is pressed
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              checkIfInvitesPossible(),
              const SizedBox(height: 24),
              Text("Participants: ",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: joinedParticipants,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text('No participants found');
                    } else {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(snapshot.data![index]),
                            trailing:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              ElevatedButton(
                                  onPressed: () async {
                                    if (await ApiService.kickParticipant(
                                            widget.eventId,
                                            snapshot.data![index]) ==
                                        200) {
                                      Navigator.of(context).pop();
                                      showSuccessSnackBar(context,
                                          'Kicking ${snapshot.data![index]} was successful');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              InviteToEventScreen(
                                            eventId: widget.eventId,
                                            allowInvite: true,
                                            iAmParticipant: false,
                                          ),
                                        ),
                                      );
                                    } else if (await ApiService.kickParticipant(
                                            widget.eventId,
                                            snapshot.data![index]) ==
                                        401) {
                                      showErrorSnackBar(context,
                                          '${snapshot.data![index]} was already kicked from the event');
                                    } else if (await ApiService.kickParticipant(
                                            widget.eventId,
                                            snapshot.data![index]) ==
                                        402) {
                                      showErrorSnackBar(context,
                                          'You do not have enough money to refund ${snapshot.data![index]} the event costs');
                                    } else {
                                      showErrorSnackBar(context,
                                          'Something went wrong trying to kick ${snapshot.data![index]}');
                                    }
                                  },
                                  child: Text("Kick")),
                            ]),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text("Invited participants: ",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: invitedParticipants,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text('No participants invited');
                    } else {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(snapshot.data![index]),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Event Participants'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              checkIfInvitesPossible(),
              const SizedBox(height: 24),
              Text("Participants: ",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: joinedParticipants,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text('No participants found');
                    } else {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(snapshot.data![index]),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget checkIfInvitesPossible() {
    // Recipient can be invited
    if (widget.allowInvite == true) {
      return Column(
        children: [
          const Text(
            'Recipient:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: recipientController,
            decoration: InputDecoration(
              hintText: 'Enter username',
              border: OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                final recipient = recipientController.text;

                if (recipient.trim().isEmpty) {
                  setState(() {
                    recipientBorderColor = Colors.red;
                  });
                  showErrorSnackBar(context, 'Recipient cannot be empty');
                  return;
                } else {
                  setState(() {
                    recipientBorderColor = Colors.grey;
                  });
                }

                final Map<String, dynamic> user =
                    await ApiService.fetchUserProfile();

                // Check if recipient is the same as the user
                if (recipient == user['username'] ||
                    recipient == user['email']) {
                  showErrorSnackBar(
                      context, 'You cannot send a invite to yourself');
                  return;
                }

                int res =
                    await ApiService.inviteEvent(widget.eventId, recipient);
                if (res == 200) {
                  recipientController.clear();

                  showSuccessSnackBar(
                      context, 'Invite sent successfully to $recipient');
                } else if (res == 401) {
                  showErrorSnackBar(
                      context, '$recipient already interacted with the Event');
                } else if (res == 402) {
                  showErrorSnackBar(context, '$recipient does not exist');
                }
                else if (res == 403){
                  showErrorSnackBar(context, 'You and $recipient have each other blocked');
                }
                else if (res == 400 || res == 500) {
                  showErrorSnackBar(
                      context, 'Failed to send invite to $recipient');
                }
              },
              child: Text('Invite'), // Add this line
            ),
          ),
        ],
      );
    } else {
      return Container();
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
}
