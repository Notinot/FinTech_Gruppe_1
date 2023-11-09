import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:http/http.dart' as http;


class ChangePasswordScreen extends StatefulWidget {

  // Email over parameter
  final Map<String, dynamic> user;
  const ChangePasswordScreen({super.key, required this.user});
  

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();

}

// GET USER DATA


class _ChangePasswordScreenState extends State<ChangePasswordScreen> {


  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController newPasswordAgainController = TextEditingController();
  String? code;
  String? verificationError;
  String? newPasswordError;
  String? newPasswordAgainError;

  void showSnackBar({bool isError = false, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void handleChangePassword() async {

    final newPassword = newPasswordController.text;
    final newPasswordAgain = newPasswordAgainController.text;

    if(code == null){

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

      showSnackBar(
          isError: true, message: 'Password fields cannot be empty');
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

    if (!newPassword.contains(RegExp(r'[#&@~!@?}\[%!?_]'))) {
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

    final Map<String, String> requestBody;
    requestBody = {

    };

    final response = await http.post(
        Uri.parse('http://localhost:3000/forgotpassword'),
        headers: {
          'Content-Type': 'application/json'
        },
        body: json.encode(requestBody)
    );


  }

    @override
    Widget build(BuildContext context) {
      
      return Scaffold(
        appBar: AppBar(
          title: const Text('Changing your password'),
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
                ('Please enter the verification code'),
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 40.0),
              OtpTextField(
                numberOfFields: 6,
                borderColor: Color(0xFF512DA8),
                showFieldAsBox: true,
                focusedBorderColor: Colors.blue,
                autoFocus: true,
                onSubmit: (String verifcationCode) {

                   if(double.tryParse(verifcationCode) == null){

                      showSnackBar(isError: true, message: 'Verification code needs to consist of digits');
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
                  primary: Colors.blue, // Button background color
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                ),
                onPressed: handleChangePassword,
                child: const Text(
                  'Confirm',
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
