// Create a new Flutter widget for the verification code input page.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'login_screen.dart';

class VerificationCodeScreen extends StatefulWidget {
  const VerificationCodeScreen({super.key});

  @override
  _VerificationCodeScreenState createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final TextEditingController verificationCodeController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Code'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: verificationCodeController,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Add logic to submit the verification code.
                submitVerificationCode(verificationCodeController.text);
              },
              child: const Text(
                'Submit',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void submitVerificationCode(String code) async {
    final Map<String, dynamic> requestBody = {
      'verification_code': code,
    };

    final response = await http.post(
      Uri.parse('http://localhost:3000/verify'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    // Handle the response from the server.
    if (response.statusCode == 200) {
      // Verification successful
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const LoginScreen()), // Navigate to the login screen or another appropriate screen.
      );
    } else {
      // Verification failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
