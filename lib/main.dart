import 'package:flutter/material.dart';
import 'Screens/login_screen.dart';
import 'package:http/http.dart' as http;

void main() async {
  // Check server availability
  const serverUrl = 'http://localhost:3000';
  final response = await http.get(Uri.parse('$serverUrl/health'));

  // Create the Flutter app
  runApp(PayfriendzApp(serverAvailable: response.statusCode == 200));
}

class PayfriendzApp extends StatelessWidget {
  final bool serverAvailable;

  PayfriendzApp({required this.serverAvailable});

  @override
  Widget build(BuildContext context) {
    if (serverAvailable) {
      return MaterialApp(
        home: LoginScreen(), // Set the LoginScreen as the initial route
      );
    } else {
      return MaterialApp(
        home:
            ServerUnavailableScreen(), // Server is unavailable, show an error screen
      );
    }
  }
}

class ServerUnavailableScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Server Unavailable'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('The server is currently unavailable.'),
            ElevatedButton(
              onPressed: () {
                // Implement a retry mechanism here
                // You can attempt to reconnect to the server.
              },
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
