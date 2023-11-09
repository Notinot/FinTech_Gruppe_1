import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChangePasswordScreen extends StatefulWidget {

  // Email over parameter
  const ChangePasswordScreen(String email, {super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}



class _ChangePasswordScreenState extends State<ChangePasswordScreen> {

  final TextEditingController verificationController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController newPasswordAgainController = TextEditingController();
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

    final code = verificationController.text;
    final newPassword = newPasswordController.text;
    final newPasswordAgain = newPasswordAgainController.text;

    if(code.trim().isEmpty){

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
        newPasswordError = 'Passwords do not match';
      });
      showSnackBar(isError: true, message: 'Passwords do not match');
      return;
    }



  }

  @override
  Widget build(BuildContext context) {

    return Form(child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          height: 68,
          width: 64,
          child: TextField(
            onChanged: (value) {
              if (value.length == 1) {
                FocusScope.of(context).nextFocus();
              }
            },
            style: Theme
                .of(context)
                .textTheme
                .titleLarge,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly
            ],
          ),
        ),
        SizedBox(
          height: 68,
          width: 64,
          child: TextField(
            onChanged: (value) {
              if (value.length == 1) {
                FocusScope.of(context).nextFocus();
              }
            },
            style: Theme
                .of(context)
                .textTheme
                .titleLarge,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly
            ],
          ),
        ),
        SizedBox(
          height: 68,
          width: 64,
          child: TextField(
            onChanged: (value) {
              if (value.length == 1) {
                FocusScope.of(context).nextFocus();
              }
            },
            style: Theme
                .of(context)
                .textTheme
                .titleLarge,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly
            ],
          ),
        ),
        SizedBox(
          height: 68,
          width: 64,
          child: TextField(
            onChanged: (value) {
              if (value.length == 1) {
                FocusScope.of(context).nextFocus();
              }
            },
            style: Theme
                .of(context)
                .textTheme
                .titleLarge,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly
            ],
          ),
        ),
        SizedBox(
          height: 68,
          width: 64,
          child: TextField(
            onChanged: (value) {
              if (value.length == 1) {
                FocusScope.of(context).nextFocus();
              }
            },
            style: Theme
                .of(context)
                .textTheme
                .titleLarge,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly
            ],
          ),
        ),
        SizedBox(
          height: 68,
          width: 64,
          child: TextField(
            onChanged: (value) {
              if (value.length == 1) {
                FocusScope.of(context).nextFocus();
              }
            },
            style: Theme
                .of(context)
                .textTheme
                .titleLarge,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly
            ],
          ),
        ),
        SizedBox(height: 32.0),
      ],
    )
    );
  }
}
