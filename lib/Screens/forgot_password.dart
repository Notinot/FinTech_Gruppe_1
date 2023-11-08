import 'dart:convert';

import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController verificationCodeController = TextEditingController();

  String? emailError;


  void showSnackBar({bool isError = false, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void clearErrors() {

    setState(() {
      emailError = null;
    });
  }

  bool EmailValid(String email) {
    // Validate the email format using a regular expression
    final emailPattern = RegExp(
      r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
    );
    return emailPattern.hasMatch(email);
  }

  void handleForgotPassword() async {

    final String email = emailController.text;

    if(email.trim().isEmpty){

      setState(() {
        emailError = 'Email cannot be empty';
      });
    }

    if(!EmailValid(email)){

      setState(() {
        emailError = 'Invalid email format';
      });
    }

    final Map<String, String> requestBody;
    requestBody = {
      'email': email
    };

    final response = await http.post(
      Uri.parse('http://localhost:3000/forgotpassword'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode(requestBody)
    );

    if (response.statusCode == 200) {

      showSnackBar(
          message:
          '  Verification code has been send to $email ');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),

      );
    }

    // Open Verification Screen


    showSnackBar(isError: true, message: 'Failed');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
                ('Confirming your identity'),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold
                ),
            ),
            const SizedBox(height: 16.0),
            Text(
              ('You will receive an verification code'),
              style: TextStyle(
                  fontSize: 18,
              ),
            ),
            const SizedBox(height: 32.0),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),
                errorText: emailError,
              ),
            ),
            const SizedBox(height: 40.0),
            ElevatedButton(
              onPressed: handleForgotPassword,
              style: ElevatedButton.styleFrom(
                primary: Colors.blue, // Button background color
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 16),
              ),
              child: const Text(
                'Send',
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.white, // Button text color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}



