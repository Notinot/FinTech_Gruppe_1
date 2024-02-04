import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_application_1/Screens/Dashboard/expandable_fab.dart';
import 'package:flutter_application_1/Screens/Events/CreateEventScreen.dart';
import 'package:flutter_application_1/Screens/Login%20&%20Register/LoginScreen.dart';
import 'package:flutter_application_1/Screens/Money/RequestMoneyScreen.dart';
import 'package:flutter_application_1/Screens/Money/SendMoneyScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart';

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
          //child: const Icon(Icons.euro),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.euro),
              SizedBox(height: 8.0), // Adjust the spacing as needed
              Text('Send\nMoney'),
            ],
          ),

          onPressed: () {
            ApiService.navigateWithAnimation(context, SendMoneyScreen());
            /*Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SendMoneyScreen(),
              ),
            );*/
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
            ApiService.navigateWithAnimation(context, RequestMoneyScreen());
            /*Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequestMoneyScreen(),
              ),
            );*/
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
            ApiService.navigateWithAnimation(context, CreateEventScreen());
            /*Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateEventScreen(),
              ),
            );*/
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
