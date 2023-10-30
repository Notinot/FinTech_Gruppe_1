import 'package:flutter/material.dart';

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

  String? passwordError;
  String? emailError;
  String? usernameError;

  void clearErrors() {
    setState(() {
      passwordError = null;
      emailError = null;
      usernameError = null;
    });
  }

  Future<void> registerUser() async {
    clearErrors();

    final String username = usernameController.text;
    final String email = emailController.text;
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

    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        passwordError = 'Password fields cannot be empty';
      });
    }

    if (password != confirmPassword) {
      setState(() {
        passwordError = 'Passwords do not match';
      });
      return;
    }

    if (!email.contains('@')) {
      setState(() {
        emailError = 'Email must contain "@" symbol';
      });
      return;
    }

    // Make an HTTP POST request to your backend API
    //final response = await http.post(
    //  Uri.parse('YOUR_BACKEND_API_URL_HERE'), // Replace with your API URL
    //  body: {
    //    'username': username,
    //    'email': email,
    //    'password': password,
    //  },
    //);

    //if (response.statusCode == 200) {
    // Registration successful
    // You can navigate the user to the next screen or show a success message
    //} else {
    // Registration failed
    // You can handle errors, such as displaying an error message
    // }
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
