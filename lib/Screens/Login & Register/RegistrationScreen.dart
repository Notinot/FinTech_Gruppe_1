// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'LoginScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:io' as io;

import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../api_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

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
    // Clear any previous error messages
    setState(() {
      passwordError = null;
      emailError = null;
      usernameError = null;
      firstnameError = null;
      lastnameError = null;
    });
  }

  ImageProvider<Object> _imageProvider =
      const AssetImage('lib/assets/profile_image.png');

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );
      if (result != null) {
        final file = result.files.first;
        if (file.extension == 'jpg' ||
            file.extension == 'jpeg' ||
            file.extension == 'png') {
          if (file.bytes != null) {
            setState(() {
              _imageProvider =
                  MemoryImage(Uint8List.fromList(file.bytes as List<int>));
            });
          }
        }
      }
    } else {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imageProvider = FileImage(io.File(pickedFile.path));
        });
      }
    }
  }

  bool EmailValid(String email) {
    // Validate the email format using a regular expression
    final emailPattern = RegExp(
      r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
    );
    return emailPattern.hasMatch(email);
  }

  Future<void> registerUser() async {
    // Clear any previous error messages
    clearErrors();

    final String username = usernameController.text;
    final String email = emailController.text;
    final String firstname = firstnameController.text;
    final String lastname = lastnameController.text;
    final String password = passwordController.text;
    final String confirmPassword = confirmPasswordController.text;

    Uint8List? profileImageBytes;

    if (_imageProvider is MemoryImage) {
      final memoryImage = _imageProvider as MemoryImage;
      profileImageBytes = memoryImage.bytes;
    } else if (_imageProvider is FileImage) {
      final fileImage = _imageProvider as FileImage;

      // You need to get the file path from the FileImage
      final file = io.File(fileImage.file.path);

      try {
        // Read the file as bytes
        profileImageBytes = await file.readAsBytes();
      } catch (error) {
        // Handle the error, e.g., set profileImageBytes to null
        print('Error reading file: $error');
        profileImageBytes = null;
      }
    }

    if (username.trim().isEmpty) {
      // Check if username is empty
      setState(() {
        usernameError = 'Username cannot be empty';
      });
      showSnackBar(isError: true, message: 'Username cannot be empty');
      return;
    }

    if (RegExp(r'\s').hasMatch(username) ||
        username.toLowerCase().trim() == "deleteduser" ||
        username.toLowerCase().trim() == "deleted" ||
        username.toLowerCase().trim() == "null") {
      setState(() {
        usernameError = 'This Username is invalid, choose a different one!';
      });
      showSnackBar(
        isError: true,
        message: 'This Username is invalid, choose a different one!',
      );
      return;
    }

    // Check if username is at least 3 characters long
    if (username.length < 3) {
      setState(() {
        usernameError = 'Username must be at least 3 characters long';
      });
      showSnackBar(
          isError: true,
          message: 'Username must be at least 3 characters long');
      return;
    }
    //username cant contain spaces
    if (RegExp(r'\s').hasMatch(username)) {
      setState(() {
        usernameError = 'Username cannot contain spaces';
      });
      showSnackBar(isError: true, message: 'Username cannot contain spaces');
      return;
    }

    // Check if username is at most 20 characters long
    if (username.length > 20) {
      setState(() {
        usernameError = 'Username must be at most 20 characters long';
      });
      showSnackBar(
          isError: true,
          message: 'Username must be at most 20 characters long');
      return;
    }

    if (email.trim().isEmpty) {
      // Check if email is empty
      setState(() {
        emailError = 'Email cannot be empty';
      });
      showSnackBar(isError: true, message: 'Email cannot be empty');
      return;
    }
    //email cant contain spaces
    if (RegExp(r'\s').hasMatch(email)) {
      setState(() {
        emailError = 'Email cannot contain spaces';
      });
      showSnackBar(isError: true, message: 'Email cannot contain spaces');
      return;
    }

    //check if email is at most 50 characters long
    if (email.length > 50) {
      setState(() {
        emailError = 'Email must be at most 50 characters long';
      });
      showSnackBar(
          isError: true, message: 'Email must be at most 50 characters long');
      return;
    }

    if (firstname.trim().isEmpty) {
      // Check if first name is empty
      setState(() {
        firstnameError = 'First name cannot be empty';
      });
      showSnackBar(isError: true, message: 'First name cannot be empty');
      return;
    }

    if (firstname.length < 2) {
      // Check if first name is at least two characters long
      setState(() {
        firstnameError = 'First name must be at least two characters long';
      });
      showSnackBar(
          isError: true,
          message: 'First name must be at least two characters long');
      return;
    }
    //firstname cant contain spaces
    if (RegExp(r'\s').hasMatch(firstname)) {
      setState(() {
        firstnameError = 'First name cannot contain spaces';
      });
      showSnackBar(isError: true, message: 'First name cannot contain spaces');
      return;
    }
    if (lastname.trim().isEmpty) {
      // Check if last name is empty
      setState(() {
        lastnameError = 'Last name cannot be empty';
      });
      showSnackBar(isError: true, message: 'Last name cannot be empty');
      return;
    }
    //lastname cant contain spaces
    if (RegExp(r'\s').hasMatch(lastname)) {
      setState(() {
        lastnameError = 'Last name cannot contain spaces';
      });
      showSnackBar(isError: true, message: 'Last name cannot contain spaces');
      return;
    }
    if (lastname.length < 2) {
      // Check if last name is at least two characters long
      setState(() {
        lastnameError = 'Last name must be at least two characters long';
      });
      showSnackBar(
          isError: true,
          message: 'Last name must be at least two characters long');
      return;
    }

    if (password.isEmpty || confirmPassword.isEmpty) {
      // Check if password fields are empty
      setState(() {
        passwordError = 'Password fields cannot be empty';
      });
      showSnackBar(isError: true, message: 'Please complete all fields');
      return;
    }

    if (password.length < 12) {
      // Check if password is at least 12 characters long
      setState(() {
        passwordError = 'Password must have at least 12 characters';
      });
      showSnackBar(
          isError: true, message: 'Password should be at least 12 characters');
      return;
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      // Check if password contains at least one number
      setState(() {
        passwordError = 'Password must contain at least one number';
      });
      showSnackBar(isError: true, message: 'Password must include a number');
      return;
    }

    if (!password.contains(RegExp(r'[$#&@~!@?}\[%!?_*+-]'))) {
      // Check if password contains at least one special character
      setState(() {
        passwordError =
            'Password must contain at least one special character (#&@~!@?}[%!_)';
      });
      showSnackBar(
          isError: true, message: 'Password must include a special character');
      return;
    }

    if (password != confirmPassword) {
      // Check if passwords match
      setState(() {
        passwordError = 'Passwords do not match';
      });
      showSnackBar(isError: true, message: 'Passwords do not match');
      return;
    }

    if (!EmailValid(email)) {
      // Check if email format is valid
      setState(() {
        emailError = 'Invalid email format';
      });
      showSnackBar(isError: true, message: 'Invalid email format');
      return;
    }
    if (_imageProvider == const AssetImage('lib/assets/profile_image.png')) {
      // User did not choose a profile picture, set it to null or handle as needed
      profileImageBytes =
          null; // or you can set it to a null value expected by your API
    }
    print('Picture data: $profileImageBytes');
    final Map<String, dynamic> requestBody;
    // Create a JSON payload to send to the API
    if (profileImageBytes != null) {
      requestBody = {
        'username': username,
        'email': email,
        'firstname': firstname,
        'lastname': lastname,
        'password': password,
        'picture': profileImageBytes != null
            ? base64Encode(
                profileImageBytes) // Convert to base64-encoded string
            : null
      };
    } else {
      requestBody = {
        'username': username,
        'email': email,
        'firstname': firstname,
        'lastname': lastname,
        'password': password,
      };
    }

    print('Picture data: $requestBody');
    // Make an HTTP POST request to your backend API
    final response = await http.post(
      //Uri.parse('http://192.168.178.28:3000/register'),
      Uri.parse('${ApiService.serverUrl}/register'),
      headers: {
        'Content-Type': 'application/json', // Set the content type
      },
      body: json.encode(requestBody), // Encode the request body as JSON
    );

    if (response.statusCode == 200) {
      // Registration successful, handle accordingly
      showSnackBar(
          message:
              ' Registration successfull!  Verification code has been send to $email ');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else if (response.statusCode == 400) {
      showSnackBar(
          isError: true, message: 'Email address or username already in use');
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
        title: const Text('Registration'),
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
                          "This is the Registration Screen. Here you can register with your first and lastname, username, email and password.\n\nNote that the password must be at least 12 characters long and contain at least one number and one special character.\n\nThe username must be between 3 and 20 characters long and can not be changed afterwards."),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ClipOval(
                child:
                    CircleAvatar(radius: 80, backgroundImage: _imageProvider),
              ),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Choose Profile Picture'),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  helperText: 'Username can not be changed afterwards',
                  labelText: 'Username',
                  border: const OutlineInputBorder(),
                  errorText: usernameError,
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  errorText: emailError,
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: firstnameController,
                decoration: InputDecoration(
                  labelText: 'First name',
                  border: const OutlineInputBorder(),
                  errorText: firstnameError,
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: lastnameController,
                decoration: InputDecoration(
                  labelText: 'Last name',
                  border: const OutlineInputBorder(),
                  errorText: lastnameError,
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  errorText: passwordError,
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  errorText: passwordError,
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: registerUser,
                child: const Text(
                  'Register',
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
