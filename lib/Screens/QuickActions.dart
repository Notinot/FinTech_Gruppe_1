import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/send_money_screen.dart';

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
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(16),
            child: Icon(
              icon,
              size: 48,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
