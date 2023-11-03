import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController verificationCodeController =
      TextEditingController();

  bool requiresVerification = false;
  Future<void> checkUserActiveStatus(String email) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/check-active'), // Use the correct route
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final isActive = data['active'];

      setState(() {
        requiresVerification = isActive == 0;
      });
    } else {}
  }

  void handleLogin() async {
    final String email = emailController.text;
    final String password = passwordController.text;

    // Call checkUserActiveStatus to determine if the user requires verification
    await checkUserActiveStatus(email);

    if (requiresVerification) {
      final verificationCode = verificationCodeController.text;
      if (verificationCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the Verification code send to you'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }
    }

    final requestData = requiresVerification
        ? {
            'email': email,
            'password': password,
            'verificationCode': verificationCodeController.text,
          }
        : {
            'email': email,
            'password': password,
          };

    final response = await http.post(
      Uri.parse('http://localhost:3000/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestData),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final token = data['token'];
      final user = data['user'];

      const storage = FlutterSecureStorage();
      await storage.write(key: 'token', value: token);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(user: user),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Invalid email, password, or verification code. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            if (requiresVerification) const SizedBox(height: 12.0),
            if (requiresVerification)
              TextField(
                controller: verificationCodeController,
                obscureText: false,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: handleLogin,
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
            const SizedBox(height: 12.0),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegistrationScreen()),
                );
              },
              child: const Text(
                "Don't have an account yet? Register here",
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
