import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Login%20&%20Register/LoginScreen.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:http/http.dart' as http;
import '../api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String email;
  const ChangePasswordScreen({super.key, required this.email});

  @override
  _ChangePasswordScreenState createState() =>
      _ChangePasswordScreenState(email: email);
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final String email;
  _ChangePasswordScreenState({required this.email});

  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController newPasswordAgainController =
      TextEditingController();
  String? code;
  String? verificationError;
  String? newPasswordError;
  String? newPasswordAgainError;

  void clearErrors() {
    // Clear any previous error messages
    setState(() {
      newPasswordError = null;
      newPasswordAgainError = null;
      verificationError = null;
    });
  }

  void showSnackBar({bool isError = false, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void handleChangePassword() async {
    clearErrors();

    final newPassword = newPasswordController.text;
    final newPasswordAgain = newPasswordAgainController.text;

    if (code == null) {
      setState(() {
        verificationError = 'You have to enter the verification code';
      });

      showSnackBar(
          isError: true, message: 'You have to enter the verification code');
      return;
    }

    if (newPassword.trim().isEmpty || newPasswordAgain.trim().isEmpty) {
      setState(() {
        newPasswordError = 'Password fields cannot be empty';
      });

      showSnackBar(isError: true, message: 'Password fields cannot be empty');
      return;
    }

    if (newPassword.length < 12) {
      // Check if password is at least 12 characters long
      setState(() {
        newPasswordError = 'Password must have at least 12 characters';
      });

      showSnackBar(
          isError: true, message: 'Password should be at least 12 characters');
      return;
    }

    if (!newPassword.contains(RegExp(r'[0-9]'))) {
      // Check if password contains at least one number
      setState(() {
        newPasswordError = 'Password must contain at least one number';
      });
      showSnackBar(isError: true, message: 'Password must include a number');
      return;
    }

    if (!newPassword.contains(RegExp(r'[$#&@~!@?}\[%!?_*+-]'))) {
      // Check if password contains at least one special character
      setState(() {
        newPasswordError =
            'Password must contain at least one special character (#&@~!@?}[%!_)';
      });
      showSnackBar(
          isError: true, message: 'Password must include a special character');
      return;
    }

    if (newPassword != newPasswordAgain) {
      // Check if passwords match
      setState(() {
        newPasswordAgainError = 'Passwords do not match';
      });
      showSnackBar(isError: true, message: 'Passwords do not match');
      return;
    }

    // Enter request
    // Code var needs to be fixed!!!
    final Map<String, String> requestBody;
    requestBody = {
      'email': email,
      'newPassword': newPassword,
      'verificationCode': code ?? ''
    };

    final response = await http.post(
        Uri.parse('${ApiService.serverUrl}/changepassword'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody));

    if (response.statusCode == 200) {
      showSnackBar(message: '  Changing password was successful ');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else if (response.statusCode == 400) {
      showSnackBar(
          isError: true,
          message: 'The new password can not be the old password');
    } else if (response.statusCode == 401) {
      showSnackBar(isError: true, message: 'Verification code is not correct');
    } else {
      showSnackBar(isError: true, message: 'Something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Changing your password'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Info"),
                      content: const Text(
                          "Please enter the verification code that was sent to your email address. Then enter your new password and confirm it.\n\nThe password must be at least 12 characters long and contain at least one number and one special character."),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Close"))
                      ],
                    );
                  });
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                ('Confirming your identity'),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              const Text(
                ('Please enter the verification code'),
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 40.0),
              OtpTextField(
                numberOfFields: 6,
                //      borderColor: Color(0xFF512DA8),
                showFieldAsBox: true,
                keyboardType: TextInputType.number,
                //       focusedBorderColor: Colors.blue,
                autoFocus: true,
                onSubmit: (String verifcationCode) {
                  if (double.tryParse(verifcationCode) == null) {
                    showSnackBar(
                        isError: true,
                        message:
                            'Verification code needs to consist of digits');
                    return;
                  }
                  code = verifcationCode;
                },
              ),
              const SizedBox(height: 40.0),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  errorText: newPasswordError,
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: newPasswordAgainController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  errorText: newPasswordAgainError,
                ),
              ),
              const SizedBox(height: 40.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  //     primary: Colors.blue, // Button background color
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                onPressed: handleChangePassword,
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 18.0,
                    //         color: Colors.white, // Button text color
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
