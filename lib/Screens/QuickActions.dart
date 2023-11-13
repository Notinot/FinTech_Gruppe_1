import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/send_money_screen.dart';

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
              MaterialPageRoute(
                  builder: (context) => SendMoneyScreen(user: user)),
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
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(
              icon,
              size: 48,
              color: Colors.white,
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
