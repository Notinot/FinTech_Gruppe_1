import 'package:flutter/material.dart';
import 'Screens/login_screen.dart';
import 'package:http/http.dart' as http;

void main() async {
  runApp(PayfriendzApp());
}

class PayfriendzApp extends StatelessWidget {
  // Define a boolean variable to track server availability
  final bool serverAvailable;

  // Constructor for PayfriendzApp
  const PayfriendzApp({super.key, this.serverAvailable = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: serverAvailable ? LoginScreen() : ServerUnavailableScreen(),
    );
  }
}

class ServerUnavailableScreen extends StatelessWidget {
  const ServerUnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Unavailable'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('The server is currently unavailable.'),
            ElevatedButton(
              onPressed: () {
                // Implement a retry mechanism
                // You can add logic to retry connecting to the server here.
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
