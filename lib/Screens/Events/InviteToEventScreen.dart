
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Events/EventScreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../api_service.dart';

class InviteToEventScreen extends StatefulWidget {

  final int eventId;
  InviteToEventScreen({required this.eventId});

  @override
  _InviteToEventScreenState createState() => _InviteToEventScreenState();
}

class _InviteToEventScreenState extends State<InviteToEventScreen> {

  final TextEditingController recipientController = TextEditingController();
  Color recipientBorderColor = Colors.grey;
  final String recipient = '';


  Future<List<String>> fetchParticipants(int eventId) async {
    try{
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token not found');
      }

      List<String> participants = [];

      final response = await http.get(
        Uri.parse('${ApiService.serverUrl}/event-participants?eventId=$eventId'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if(response.statusCode == 200){

        final List<dynamic> participantsList = jsonDecode(response.body);

        // Explicitly cast each element to String
        final List<String> participants = participantsList
            .map((dynamic item) => (item as Map<String, dynamic>)['username'].toString())
            .toList();

        for(var p in participants){
          print(p);
        }
        return participants;

      }else{

        throw Exception('Failed to load participants. Error: ${response.statusCode}');
      }
    }catch(e){
      print("Error fetching Participants");
      print(e);
      rethrow;
    }
  }


  @override
  Widget build(BuildContext context) {

    final Future<List<String>> participants = fetchParticipants(widget.eventId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Friends'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Recipient:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: recipientController,
              decoration: InputDecoration(
                hintText: 'Enter recipient name or email',
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

                  if (recipient == user['username'] ||
                      recipient == user['email']) {
                    showErrorSnackBar(
                        context, 'You cannot send a invite to yourself');
                    return;
                  }

                  if(recipient.isEmpty){
                    showErrorSnackBar(
                        context, 'Recipient can not be empty');
                    return;
                  }

                  int res = await ApiService.inviteEvent(widget.eventId, recipient);
                  if (res == 200) {

                    recipientController.clear();

                    showSuccessSnackBar(context,
                        'Invite sent successfully to $recipient');

                  }
                  else if(res == 401){
                    showErrorSnackBar(context, '$recipient already interacted with the Event');
                  }
                  else if(res == 400 || res == 500){
                    showErrorSnackBar(context, 'Failed to send invite to $recipient');
                  }
                },
                child: Text('Invite'), // Add this line
              ),
            ),
            const SizedBox(height: 24),
            Text("Participants: ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: participants,
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
                          // Add more details if needed
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