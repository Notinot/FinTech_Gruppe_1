import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Money/SendMoneyScreen.dart';
import 'package:flutter_application_1/Screens/Money/RequestMoneyScreen.dart';
import 'package:flutter_application_1/Screens/Events/CreateEventScreen.dart';

class QuickActions extends StatelessWidget {
  final Map<String, dynamic> user;
  const QuickActions({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        QuickActionButton(
          icon: Icons.attach_money,
          label: 'Send Money',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SendMoneyScreen()),
            );
          },
        ),
        QuickActionButton(
          icon: Icons.request_page,
          label: 'Request Payment',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RequestMoneyScreen()),
            );
          },
        ),
        QuickActionButton(
          icon: Icons.event,
          label: 'Create Event',
          onTap: () {
            // Implement the action for creating an event
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateEventScreen()),
            );
          },
        ),
      ],
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Function onTap;

  const QuickActionButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Column(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              //      color: Colors.blue,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(
              icon,
              size: 48,
              //   color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
