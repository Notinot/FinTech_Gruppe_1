import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccountSummary extends StatelessWidget {
  final double balance; // Replace with actual user data

  const AccountSummary(this.balance, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Balance',
              style: TextStyle(
                fontSize: 18,
                //   color: Colors.grey,
              ),
            ),
            Text(
              '${NumberFormat("#,##0.00", "de_DE").format(balance)} €',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
