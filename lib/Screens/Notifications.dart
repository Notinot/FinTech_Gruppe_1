import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Notifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          Text(
            'Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          NotificationItem(
            icon: Icons.info,
            text: 'Your payment to John Doe was successful.',
          ),
          NotificationItem(
            icon: Icons.warning,
            text: 'You received a payment from Alice Smith.',
          ),
          // Add more notification items as needed
        ],
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final IconData icon;
  final String text;

  NotificationItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: Colors.blue),
        SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
