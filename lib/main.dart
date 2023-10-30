import 'package:flutter/material.dart';
import 'Screens/registration_screen.dart'; // Import the RegistrationScreen class
import 'Screens/login_screen.dart'; // Import the LoginScreen class
import 'Screens/dashboard_screen.dart'; // Import the HomeScreen class
import 'package:http/http.dart' as http;

void main() => runApp(PayfriendzApp());

class PayfriendzApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(), // Set the LoginScreen as the initial route
    );
  }
}

class PayfriendzScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payfriendz'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Welcome to Payfriendz'),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text('Login'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationScreen()),
                );
              },
              child: Text('Register'),
            ),
            // Add other UI elements as needed
          ],
        ),
      ),
    );
  }
}
