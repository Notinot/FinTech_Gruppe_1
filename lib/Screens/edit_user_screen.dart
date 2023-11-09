import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/dashboard_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditUser extends StatefulWidget {
  Map<String, dynamic> user;
  EditUser({Key? key, required this.user}) : super(key: key);

  @override
  _EditUserState createState() => _EditUserState();
}

class _EditUserState extends State<EditUser> {
  bool isEditing = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController currentPasswordController =
      TextEditingController();
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
  String? confirmPasswordError;
  String? currentPasswordError;
  Map<String, dynamic>? userT;

  void clearErrors() {
    // Clear any previous error messages
    setState(() {
      passwordError = null;
      confirmPasswordError = null;
      currentPasswordError = null;
      emailError = null;
      usernameError = null;
      firstnameError = null;
      lastnameError = null;
    });
  }

  ImageProvider<Object> _imageProvider =
      AssetImage('lib/assets/profile_image.png');

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

  Future<void> DeleteProfile() async {
    final Map<String, dynamic> request = {'userid': widget.user['user_id']};
    final response = await http.post(
      Uri.parse('http://localhost:3000/delete_user'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(request),
    );
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  Future<void> EditUserProfile() async {
    // Clear any previous error messages
    clearErrors();

    String username = usernameController.text;
    String email = emailController.text;
    String firstname = firstnameController.text;
    String lastname = lastnameController.text;
    String new_password = passwordController.text;
    String current_password = currentPasswordController.text;
    String confirmPassword = confirmPasswordController.text;
    bool pw_change = false;
    final user_id = widget.user['user_id'];

    Uint8List? profileImageBytes;

    if (_imageProvider is MemoryImage) {
      final memoryImage = _imageProvider as MemoryImage;
      profileImageBytes = memoryImage.bytes;
    }

    if (username.trim().isEmpty) {
      // Check if username is empty
      setState(() {
        username = widget.user['username'];
      });
    }
    if (username.length < 3 && firstname.isNotEmpty) {
      // Check if first name is at least two characters long
      setState(() {
        usernameError = 'Username must be at least two characters long';
      });
    }

    if (email.trim().isEmpty) {
      // Check if email is empty
      setState(() {
        email = widget.user['email'];
      });
    }

    if (firstname.trim().isEmpty) {
      // Check if first name is empty
      setState(() {
        firstname = widget.user['first_name'];
      });
    }

    if (firstname.length < 2 && firstname.isNotEmpty) {
      // Check if first name is at least two characters long
      setState(() {
        firstnameError = 'First name must be at least two characters long';
      });
    }

    if (lastname.trim().isEmpty) {
      // Check if last name is empty
      setState(() {
        lastname = widget.user['last_name'];
      });
    }

    if (lastname.length < 2 && lastname.isNotEmpty) {
      // Check if last name is at least two characters long
      setState(() {
        lastnameError = 'Last name must be at least two characters long';
      });
    }

    if (new_password.isEmpty && confirmPassword.isEmpty) {
      // Check if password fields are empty
      setState(() {
        pw_change = false;
      });
    }

    if (new_password.length < 12 && current_password.isNotEmpty) {
      // Check if password is at least 12 characters long
      setState(() {
        passwordError = 'Password must have at least 12 characters';
      });
      showSnackBar(
          isError: true, message: 'Password should be at least 12 characters');
      return;
    }

    if (!new_password.contains(RegExp(r'[0-9]')) && new_password.isNotEmpty) {
      // Check if password contains at least one number
      setState(() {
        passwordError = 'Password must contain at least one number';
      });
      showSnackBar(isError: true, message: 'Password must include a number');
      return;
    }

    if (!new_password.contains(RegExp(r'[#&@~!@?}\[%!?_]')) &&
        new_password.isNotEmpty) {
      // Check if password contains at least one special character
      setState(() {
        passwordError =
            'Password must contain at least one special character (#&@~!@?}[%!_)';
      });
      showSnackBar(
          isError: true, message: 'Password must include a special character');
      return;
    }

    if (new_password != confirmPassword) {
      // Check if passwords match
      setState(() {
        confirmPasswordError = 'Passwords do not match';
      });
      showSnackBar(isError: true, message: 'Passwords do not match');
      return;
    }

    if ((new_password == confirmPassword && new_password.isNotEmpty) &&
        current_password.isNotEmpty) {
      pw_change = true;
    }

    if (new_password.isNotEmpty && current_password.isEmpty) {
      setState(() {
        currentPasswordError =
            'You have to enter your current password, to change it!';
      });
      showSnackBar(
          isError: true,
          message:
              'Current password not entered while trying to change password');
      return;
    }

    if (new_password.isEmpty && current_password.isNotEmpty) {
      setState(() {
        currentPasswordError =
            'You only have to enter your current password if you want to choose a new password!';
      });
      showSnackBar(
          isError: true,
          message:
              'Current password not entered while trying to change password');
      return;
    }

    if (!EmailValid(email) && email.isNotEmpty) {
      // Check if email format is valid
      setState(() {
        emailError = 'Invalid email format';
      });
      showSnackBar(isError: true, message: 'Invalid email format');
      return;
    }
    if (_imageProvider == AssetImage('lib/assets/profile_image.png') &&
        widget.user['picture'] == null) {
      // User did not choose a profile picture, set it to null or handle as needed
      profileImageBytes =
          null; // or you can set it to a null value expected by your API
    } else if (_imageProvider == AssetImage('lib/assets/profile_image.png') &&
        widget.user['picture'] != null) {
      profileImageBytes =
          Uint8List.fromList(widget.user['picture']['data'].cast<int>());
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
        'password': current_password,
        'new_password': new_password,
        'userid': user_id,
        'pw_change': pw_change,
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
        'password': current_password,
        'new_password': new_password,
        'userid': user_id,
        'pw_change': pw_change
      };
    }
    if (pw_change == false) {
      requestBody.remove('password');
    }

    print('Picture data: $requestBody');
    // Make an HTTP POST request to your backend API
    final response = await http.post(
      Uri.parse('http://localhost:3000/edit_user'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final token = data['token'];
      final userT = data['user'];

      const storage = FlutterSecureStorage();
      await storage.write(key: 'token', value: token);
      widget.user = userT;
      showSnackBar(
          message:
              ' Profile update successful!  Verification code has been sent to $email ');

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => EditUser(user: userT)));
    } else if (response.statusCode == 401) {
      showSnackBar(isError: true, message: 'Current password is invalid!');
    } else if (response.statusCode == 402) {
      showSnackBar(isError: true, message: 'Username is already taken');
    } else if (response.statusCode == 403) {
      showSnackBar(isError: true, message: 'Email is already in  use');
    } else {
      print(response.statusCode);
      print(response.body);
      showSnackBar(isError: true, message: 'Editing profile failed');
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
    String username = widget.user['username'];
    String email = widget.user['email'];
    String firstname = widget.user['first_name'];
    String lastname = widget.user['last_name'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => DashboardScreen(user: widget.user)));
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ClipOval(
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage: widget.user['picture'] != null &&
                          widget.user['picture'] is Map<String, dynamic> &&
                          widget.user['picture']['data'] != null
                      ? MemoryImage(Uint8List.fromList(
                          widget.user['picture']['data'].cast<int>()))
                      : _imageProvider,
                ),
              ),
              Visibility(
                  visible: isEditing,
                  child: ElevatedButton(
                    onPressed: isEditing ? _pickImage : null,
                    child: Text('Change Profile Picture'),
                  )),
              const SizedBox(height: 16.0),
              buildEditableField('Username', username, usernameController,
                  usernameError, username,
                  obscureText: false),
              const SizedBox(height: 16.0),
              buildEditableField(
                  'Email:', email, emailController, emailError, email,
                  obscureText: false),
              const SizedBox(height: 16.0),
              buildEditableField('First name :', firstname, firstnameController,
                  firstnameError, firstname,
                  obscureText: false),
              const SizedBox(height: 16.0),
              buildEditableField('Last name :', lastname, lastnameController,
                  lastnameError, lastname,
                  obscureText: false),
              const SizedBox(height: 16.0),
              buildEditableField(
                  'current Password : ',
                  '********',
                  currentPasswordController,
                  currentPasswordError,
                  'current Password',
                  obscureText: true),
              const SizedBox(height: 16.0),
              Visibility(
                visible: isEditing,
                child: buildEditableField('Password : ', '********',
                    passwordController, passwordError, 'new Password',
                    obscureText: true),
              ),
              const SizedBox(height: 16.0),
              Visibility(
                visible: isEditing,
                child: buildEditableField(
                    'Confirm Password',
                    'Confirm Password',
                    confirmPasswordController,
                    confirmPasswordError,
                    'Confirm Password',
                    obscureText: true),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                child: Icon(isEditing ? Icons.save : Icons.edit),
                onPressed: isEditing ? EditUserProfile : toggleEditMode,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                  onPressed: DeleteProfile, child: Text("Delete Account"))
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEditableField(String label, String value,
      TextEditingController controller, String? error, String hintText,
      {required bool obscureText}) {
    if (isEditing) {
      return Visibility(
          visible: isEditing,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: label,
              hintText: hintText,
              border: const OutlineInputBorder(),
              errorText: error,
            ),
          ));
    } else {
      return Row(
        children: <Widget>[
          Text('$label$value'),
          if (isEditing)
            ElevatedButton(
              onPressed: () {
                controller.text = value;
              },
              child: Text('Edit'),
            ),
        ],
      );
    }
  }

  void toggleEditMode() {
    setState(() {
      isEditing = !isEditing;
    });
  }
}
