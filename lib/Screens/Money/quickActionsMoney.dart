import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/expandable_fab.dart';
import 'package:flutter_application_1/Screens/Events/CreateEventScreen.dart';
import 'package:flutter_application_1/Screens/Money/RequestMoneyScreen.dart';
import 'package:flutter_application_1/Screens/Money/SendMoneyScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart';

class QuickMenuTransactions extends StatelessWidget {
  final Map<String, dynamic> user;
  const QuickMenuTransactions({Key? key, required this.user}) : super(key: key);

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
