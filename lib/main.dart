import 'package:flutter/material.dart';
import 'Screens/login_screen.dart';
import 'package:http/http.dart' as http;

void main() async {
  // Check server availability
  // const serverUrl = 'http://192.168.2.33:3000';
  const serverUrl = 'http://localhost:3000';
  final response = await http.get(Uri.parse('$serverUrl/health'));

  // Create the Flutter app
  runApp(PayfriendzApp(serverAvailable: response.statusCode == 200));
}

class PayfriendzApp extends StatelessWidget {
  final bool serverAvailable;

  const PayfriendzApp({super.key, required this.serverAvailable});

  @override
  Widget build(BuildContext context) {
    if (serverAvailable) {
      // If the server is available, show the LoginScreen as the initial route
      return const MaterialApp(
        home: LoginScreen(),
      );
    } else {
      // If the server is unavailable, show an error screen
      return const MaterialApp(
        home: ServerUnavailableScreen(),
      );
    }
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
            // Display a message for server unavailability
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
