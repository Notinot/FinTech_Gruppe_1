import 'dart:html';

import 'package:flutter/material.dart';
import 'Screens/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'Screens/dashboard_screen.dart';

void main() {
  runApp(PayfriendzApp());
}

class PayfriendzApp extends StatefulWidget {
  @override
  _PayfriendzAppState createState() => _PayfriendzAppState();
}

class _PayfriendzAppState extends State<PayfriendzApp> {
  bool serverAvailable = false;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkServerAvailability();
    //checkStayLoggedIn(); //COMMENT THIS OUT TO STAY LOGGED IN (in theory)
  }

  Future<void> checkServerAvailability() async {
    // const serverUrl = '192.168.56.1:3000';
    const serverUrl = 'http://localhost:3000';
    final response = await http.get(Uri.parse('$serverUrl/health'));
    setState(() {
      serverAvailable = response.statusCode == 200;
    });
  }

  //Testing Stay Logged in function for future implementation
  Future<void> checkStayLoggedIn() async {
    const secureStorage = FlutterSecureStorage();
    String? authToken = await secureStorage.read(key: 'token');
    print(authToken);
    if (authToken != null && authToken.isNotEmpty) {
      setState(() {
        isLoggedIn = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (serverAvailable && isLoggedIn) {
      return const MaterialApp(
        home: DashboardScreen(),
      );
    } else if (serverAvailable) {
      return const MaterialApp(
        home: LoginScreen(),
      );
    } else {
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
