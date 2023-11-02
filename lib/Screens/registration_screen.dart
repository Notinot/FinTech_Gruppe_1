import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();

  String? passwordError;
  String? emailError;
  String? usernameError;
  String? firstnameError;
  String? lastnameError;

  void clearErrors() {
    setState(() {
      passwordError = null;
      emailError = null;
      usernameError = null;
      firstnameError = null;
      lastnameError = null;
    });
  }

  bool EmailValid(String email) {
    final emailPattern = RegExp(
      r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
    );
    return emailPattern.hasMatch(email);
  }

  Future<void> registerUser() async {
    clearErrors();

    final String username = usernameController.text;
    final String email = emailController.text;
    final String firstname = firstnameController.text;
    final String lastname = lastnameController.text;
    final String password = passwordController.text;
    final String confirmPassword = confirmPasswordController.text;

    if (username.isEmpty) {
      setState(() {
        usernameError = 'Username cannot be empty';
      });
    }

    if (email.isEmpty) {
      setState(() {
        emailError = 'Email cannot be empty';
      });
    }

    if (firstname.isEmpty) {
      setState(() {
        firstnameError = 'First name cannot be empty';
      });
    }

    if (firstname.length < 2) {
      setState(() {
        firstnameError = 'First name must be at least two characters long';
      });
    }

    if (lastname.isEmpty) {
      setState(() {
        lastnameError = 'Last name cannot be empty';
      });
    }

    if (lastname.length < 2) {
      setState(() {
        firstnameError = 'Last name must be at least two characters long';
      });
    }

    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        passwordError = 'Password fields cannot be empty';
      });
      showSnackBar(isError: true, message: 'Please complete all fields');
      return;
    }

    if (password.length < 12) {
      setState(() {
        passwordError = 'Password must have at least 12 characters';
      });
      showSnackBar(
          isError: true, message: 'Password should be at least 12 characters');
      return;
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      setState(() {
        passwordError = 'Password must contain at least one number';
      });
      showSnackBar(isError: true, message: 'Password must include a number');
      return;
    }

    if (!password.contains(RegExp(r'[#&@~!@?}\[%!?]'))) {
      setState(() {
        passwordError =
            'Password must contain at least one special character (#&@~!@?}[%!?)';
      });
      showSnackBar(
          isError: true, message: 'Password must include a special character');
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        passwordError = 'Passwords do not match';
      });
      showSnackBar(isError: true, message: 'Passwords do not match');
      return;
    }

    if (!EmailValid(email)) {
      setState(() {
        emailError = 'Invalid email format';
      });
      showSnackBar(isError: true, message: 'Invalid email format');
      return;
    }

    // Create a JSON payload to send to the API
    final Map<String, dynamic> requestBody = {
      'username': username,
      'email': email,
      'firstname': firstname,
      'lastname': lastname,
      'password': password,
    };

// Make an HTTP POST request to your backend API
    final response = await http.post(
      Uri.parse('http://localhost:3000/register'),
      headers: {
        'Content-Type': 'application/json', // Set the content type
      },
      body: json.encode(requestBody), // Encode the request body as JSON
    );

    if (response.statusCode == 200) {
      // Registration successful, handle accordingly
      showSnackBar(message: 'Registration successful');
    } else {
      // Registration failed, handle accordingly
      showSnackBar(isError: true, message: 'Registration failed');
    }
  }

  void showSnackBar({bool isError = false, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                errorText: usernameError,
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                errorText: emailError,
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: firstnameController,
              decoration: InputDecoration(
                labelText: 'First name',
                border: OutlineInputBorder(),
                errorText: firstnameError,
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: lastnameController,
              decoration: InputDecoration(
                labelText: 'Last name',
                border: OutlineInputBorder(),
                errorText: lastnameError,
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                errorText: passwordError,
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
                errorText: passwordError,
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: registerUser,
              child: Text(
                'Register',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
