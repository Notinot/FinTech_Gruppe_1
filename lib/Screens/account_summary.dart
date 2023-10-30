import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AccountSummary extends StatelessWidget {
  final double balance; // Replace with actual user data

  AccountSummary(this.balance);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Balance',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              '\$${balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
