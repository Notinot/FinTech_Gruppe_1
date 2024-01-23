
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {

    print(recipient);

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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

                  // check if user is sending money to himself
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