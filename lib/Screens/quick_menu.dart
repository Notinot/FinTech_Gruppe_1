import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_application_1/expandable_fab.dart';
import 'package:flutter_application_1/Screens/create_event_screen.dart';
import 'package:flutter_application_1/Screens/login_screen.dart';
import 'package:flutter_application_1/Screens/request_money_screen.dart';
import 'package:flutter_application_1/Screens/send_money_screen.dart';

class QuickMenu extends StatelessWidget {
  final Map<String, dynamic> user;
  const QuickMenu({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandableFab(
      distance: 150.0,
      children: [
        FloatingActionButton.large(
          heroTag: null,
          //child: const Icon(Icons.attach_money),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.attach_money),
              SizedBox(height: 8.0), // Adjust the spacing as needed
              Text('Send\nMoney'),
            ],
          ),

          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SendMoneyScreen(),
              ),
            );
          },
        ),
        FloatingActionButton.large(
          heroTag: null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.request_page),
              SizedBox(height: 8.0), // Adjust the spacing as needed
              Text('Request\nMoney'),
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequestMoneyScreen(),
              ),
            );
          },
        ),
        FloatingActionButton.large(
          heroTag: null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event),
              SizedBox(height: 8.0), // Adjust the spacing as needed
              Text('Create\nEvent'),
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateEventScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

Future<void> logout(BuildContext context) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');

  // Clear the token
  await storage.delete(key: 'token');

  print('Token deleted: $token'); // Add this line for debugging

  // Navigate to the login screen and remove the ability to go back
  Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => const LoginScreen()));
}
