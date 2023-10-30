import 'package:flutter/material.dart';
import 'AccountSummary.dart';
import 'UserProfileSection.dart';
import 'Notifications.dart';
import 'QuickActions.dart';
import 'RecentTransactions.dart';
import 'AppDrawer.dart';
import 'package:http/http.dart' as http;

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String username = "Lukas";
    double balance = 1000.00;
    List<Transaction> recentTransactions = [
      Transaction(amount: 25.00, name: 'Dennis', type: 'Payment'),
      Transaction(amount: 45.00, name: 'Vito', type: 'Received'),
      Transaction(type: 'Payment', amount: 10.00, name: 'Lukas'),
      Transaction(amount: 25.00, name: 'Labi', type: 'Received'),
      Transaction(type: 'Payment', amount: 10.00, name: 'Lukas'),
      Transaction(amount: 25.00, name: 'Lukas', type: 'Payment'),
      Transaction(type: 'Payment', amount: 10.00, name: 'Lukas'),
      Transaction(type: 'Payment', amount: 10.00, name: 'Labi'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              UserProfileSection(username),
              AccountSummary(balance),
              QuickActions(),
              Notifications(),
              RecentTransactions(transactions: recentTransactions),
            ],
          ),
        ),
      ),
      drawer: AppDrawer(), // Custom Drawer widget for the menu
    );
  }
}
