import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        QuickActionButton(
          icon: Icons.attach_money,
          label: 'Send Money',
          onTap: () {
            // Implement the action for sending money
          },
        ),
        QuickActionButton(
          icon: Icons.money_off,
          label: 'Request Payment',
          onTap: () {
            // Implement the action for requesting payment
          },
        ),
        QuickActionButton(
          icon: Icons.event,
          label: 'Create Event',
          onTap: () {
            // Implement the action for creating an event
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

  QuickActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            size: 48,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
