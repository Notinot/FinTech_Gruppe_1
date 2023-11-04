import 'package:flutter/material.dart';

class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        children: <Widget>[
          Text(
            'Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          NotificationItem(
            icon: Icons.info,
            text: 'Your payment to Dennis Kammos was successful.',
          ),
          NotificationItem(
            icon: Icons.warning,
            text: "You received a payment from Vito D'Elia .",
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

  const NotificationItem({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
