import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_application_1/Screens/Dashboard/expandable_fab.dart';
import 'package:flutter_application_1/Screens/Events/CreateEventScreen.dart';
import 'package:flutter_application_1/Screens/Login%20&%20Register/LoginScreen.dart';
import 'package:flutter_application_1/Screens/Money/RequestMoneyScreen.dart';
import 'package:flutter_application_1/Screens/Money/SendMoneyScreen.dart';

class QuickMenuTransaction extends StatelessWidget {
  final String user;
  const QuickMenuTransaction({Key? key, required this.user}) : super(key: key);

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
              Icon(Icons.person_add),
              SizedBox(height: 8.0), // Adjust the spacing as needed
              Text('Add\nFriend'),
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
