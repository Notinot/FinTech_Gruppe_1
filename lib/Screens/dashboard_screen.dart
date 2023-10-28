// dashboard_screen.dart

import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Replace these placeholders with actual user data
    String username = "User123";
    double balance = 1000.00;
    List<Transaction> recentTransactions = [
      Transaction("Payment", "John Doe", 50.00),
      Transaction("Received", "Alice Smith", 200.00),
      Transaction("Payment", "John Doe", 50.00),
      Transaction("Received", "Alice Smith", 200.00),
      Transaction("Payment", "John Doe", 50.00),
      Transaction("Received", "Alice Smith", 200.00),
      // Add more transactions
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Welcome, $username',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Card(
              elevation: 5,
              margin: EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Balance', style: TextStyle(fontSize: 18)),
                    Text('\$${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('Recent Transactions:', style: TextStyle(fontSize: 18)),
            Expanded(
              child: ListView.builder(
                itemCount: recentTransactions.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    child: ListTile(
                      title: Text(recentTransactions[index].type),
                      subtitle: Text(
                          'Amount: \$${recentTransactions[index].amount.toStringAsFixed(2)}\n${recentTransactions[index].name}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.attach_money),
              title: Text('Money Transfer'),
              onTap: () {
                // Navigate to the money transfer section
                // Implement the navigation as needed
              },
            ),
            ListTile(
              leading: Icon(Icons.contacts),
              title: Text('Contact Management'),
              onTap: () {
                // Navigate to the contact management section
                // Implement the navigation as needed
              },
            ),
            Divider(), // Add a divider to separate the top items from the bottom items
            ListTile(
              leading: Icon(Icons.group),
              title: Text('Groups & Events'),
              onTap: () {
                // Navigate to the groups and events section
                // Implement the navigation as needed
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Account'),
              onTap: () {
                // Navigate to the account section
                // Implement the navigation as needed
              },
            ),
            Divider(), // Add a divider to separate the bottom items from the "Sign Out"
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Sign Out'),
              onTap: () {
                // Handle sign out logic, such as clearing user session
                // Implement the sign out functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Transaction {
  final String type;
  final String name;
  final double amount;

  Transaction(this.type, this.name, this.amount);
}
