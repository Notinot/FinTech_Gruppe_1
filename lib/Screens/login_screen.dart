import 'package:flutter/material.dart';
import 'registration_screen.dart';
//import 'dashboard_screen.dart'; // Import the HomeScreen class
import 'dashboard_screen copy.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16.0),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                String enteredUsername = "test"; // Replace with user input
                String enteredPassword = "test"; // Replace with user input

                if (enteredUsername == "test" && enteredPassword == "test") {
                  // Successful login, navigate to the home screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => DashboardScreen()),
                  );
                } else {
                  // Handle unsuccessful login, show an error message
                  // You can display an error message or other UI feedback to the user
                }
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
