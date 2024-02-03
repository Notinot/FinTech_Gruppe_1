import 'dart:async';
import 'dart:convert';
//import 'dart:ffi';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/Screens/Dashboard/appDrawer.dart';
import 'package:flutter_application_1/Screens/Dashboard/dashBoardScreen.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_application_1/Screens/Login & Register/LoginScreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:http/http.dart' as http;
import 'dart:io' as io;

import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import for web support
import 'package:flutter_application_1/Screens/api_service.dart';

class EditUser extends StatefulWidget {
  EditUser({super.key});

  @override
  _EditUserState createState() => _EditUserState();
}

class _EditUserState extends State<EditUser> {
  bool isEditing = false;

  late Future<Map<String, dynamic>> user = ApiService.fetchUserProfile();
  Map<String, dynamic> userData = {};

  late ImageProvider<Object> _imageProvider;

  late String email_old;
  late String username;
  late String firstname_old;
  late String lastname_old;
  late int user_id;
  late Uint8List? profileImage;
  late String currentPassword;

  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  late TextEditingController firstnameController;
  late TextEditingController lastnameController;

  String? passwordError;
  String? emailError;
  String? usernameError;
  String? firstnameError;
  String? lastnameError;
  String? confirmPasswordError;
  Map<String, dynamic>? userT;

  void clearErrors() {
    // Clear any previous error messages
    setState(() {
      passwordError = null;
      confirmPasswordError = null;
      emailError = null;
      usernameError = null;
      firstnameError = null;
      lastnameError = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _imageProvider = AssetImage('lib/assets/profile_image.png');
    profileImage = null;
    // Use the user Future's result to initialize the controllers
    user.then((userData) {
      setState(() {
        emailController = TextEditingController(text: userData['email']);
        usernameController = TextEditingController(text: userData['username']);
        passwordController = TextEditingController();
        confirmPasswordController = TextEditingController();
        firstnameController =
            TextEditingController(text: userData['first_name']);
        lastnameController = TextEditingController(text: userData['last_name']);
        user_id = userData['user_id'];
        username = userData['username'];
        email_old = userData['email'];
        firstname_old = userData['first_name'];
        lastname_old = userData['last_name'];
        currentPassword = userData['password_hash'];

        /*_imageProvider = ((userData['picture'] != null &&
                    userData['picture'] is Map<String, dynamic> &&
                    userData['picture']['data'] != null
                ? MemoryImage(
                    Uint8List.fromList(userData['picture']['data'].cast<int>()))
                : AssetImage('lib/assets/profile_image.png'))
            as ImageProvider<Object>?)!;*/

        if (userData['picture'] != null &&
            userData['picture'] is Map<String, dynamic> &&
            userData['picture']['data'] != null) {
          _imageProvider = MemoryImage(
            Uint8List.fromList(userData['picture']['data'].cast<int>()),
          );
          profileImage =
              Uint8List.fromList(userData['picture']['data'].cast<int>());
        } else {
          // Provide a default value if userData['picture'] is null
          _imageProvider = AssetImage('lib/assets/profile_image.png');
          profileImage = null;
        }
      });
    });
  }

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
          print(pickedFile.path);
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
    // Show a confirmation dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account?'),
          content: Text(
              'Are you sure you want to delete your account?\nBe sure to leave all Events and handle all your businesses beforehand!\nThis can not be undone!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User pressed No
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User pressed Yes
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    // Check user's choice
    if (confirmDelete == true) {
      // User confirmed, proceed with the account deletion
      final Map<String, dynamic> request = {'userid': user_id};
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final response = await http.post(
        Uri.parse('${ApiService.serverUrl}/delete_user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(request),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        print('Failed to delete profile. Status code: ${response.statusCode}');
      }
    } else {
      // User chose not to delete the account
      print('Account deletion canceled by the user.');
    }
  }

  Future<void> EditUserProfile() async {
    // Clear any previous error messages
    clearErrors();

    String username = usernameController.text;
    String email = emailController.text;
    String firstname = firstnameController.text;
    String lastname = lastnameController.text;
    String new_password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;
    bool pw_change = false;
    bool email_change = false;
    //final user_id = userData?['user_id'];
    String code = '';
    late http.Response resp = http.Response('null', 500);

    Uint8List? profileImageBytes;

    if (_imageProvider != null) {
      if (_imageProvider is MemoryImage) {
        final memoryImage = _imageProvider as MemoryImage;
        profileImageBytes = memoryImage.bytes;
      } else if (_imageProvider is AssetImage) {
        // Handle AssetImage or any other ImageProvider types if needed
        // For now, set profileImageBytes to null or a default value
        profileImageBytes = null;
      }
    } else {
      // Handle the case when _imageProvider is null
      // For now, set profileImageBytes to null or a default value
      profileImageBytes = null;
    }

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

    /*if (username.trim().isEmpty) {
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
    } */

    if (email.trim().isEmpty) {
      // Check if email is empty
      setState(() {
        email = email_old;
      });
    }

    if (firstname.trim().isEmpty) {
      // Check if first name is empty
      setState(() {
        firstname = firstname_old;
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
        lastname = lastname_old;
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

    if (new_password.length < 12 && new_password.isNotEmpty) {
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

    if (!new_password.contains(RegExp(r'[$#&@~!@?}\[%!?_*+-]')) &&
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

    if ((new_password == confirmPassword && new_password.isNotEmpty)) {
      pw_change = true;
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
        profileImage == null) {
      // User did not choose a profile picture, set it to null or handle as needed
      profileImageBytes =
          null; // or you can set it to a null value expected by your API
    } else if (_imageProvider == AssetImage('lib/assets/profile_image.png') &&
        profileImage != null) {
      profileImageBytes = profileImage;
    }

//##############################################################################
    bool verificationSuccess = true;

    if (email.isNotEmpty && email != email_old) {
      email_change = true;
      Map<String, dynamic> request;
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      request = {'userid': user_id, 'email': email};
      resp = await http.post(
        Uri.parse('${ApiService.serverUrl}/edit_user/send_code'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request),
      );

      try {
        code = await verify();
        request = {'userid': user_id, 'verificationCode': code};
        const storage = FlutterSecureStorage();
        final token = await storage.read(key: 'token');
        resp = await http.post(
          Uri.parse('${ApiService.serverUrl}/edit_user/verify'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(request),
        );
      } catch (error) {
        verificationSuccess = false;
      }
    }
//##############################################################################
    //print('Picture data: $profileImageBytes');

    final Map<String, dynamic> requestBody;
    // Create a JSON payload to send to the API

    if (verificationSuccess || resp.body == 'null') {
      if (profileImageBytes != null) {
        requestBody = {
          //'username': username,
          'email': email,
          'firstname': firstname,
          'lastname': lastname,
          'new_password': new_password,
          'userid': user_id,
          'pw_change': pw_change,
          'email_change': email_change,
          'code': code,
          'picture': profileImageBytes != null
              ? base64Encode(
                  profileImageBytes) // Convert to base64-encoded string
              : null
        };
      } else {
        requestBody = {
          //'username': username,
          'email': email,
          'firstname': firstname,
          'lastname': lastname,
          'new_password': new_password,
          'userid': user_id,
          'email_change': email_change,
          'code': code,
          'pw_change': pw_change
        };
      }
      if (pw_change == false) {
        requestBody.remove('password');
      }

      print('Picture data: $requestBody');
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      // Make an HTTP POST request to your backend API
      final response = await http.post(
        Uri.parse('${ApiService.serverUrl}/edit_user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        showSnackBar(message: ' Profile update successful!');

        /*Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EditUser(),
          ),
        );*/

        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => EditUser()));
      } else if (response.statusCode == 401) {
        showSnackBar(isError: true, message: 'Current password is invalid!');
      } /*else if (response.statusCode == 402) {
      showSnackBar(isError: true, message: 'Username is already taken');
    }*/
      else if (response.statusCode == 403) {
        showSnackBar(isError: true, message: 'Email is already in  use');
      } else if (response.statusCode == 406) {
        showSnackBar(
            isError: true,
            message: 'Your new password cannot be your old password');
      } else if (response.statusCode == 409) {
        showSnackBar(
            isError: true,
            message: 'Your entered verification Code is incorrect');
      } else {
        print(response.statusCode);
        print(response.body);
        showSnackBar(isError: true, message: 'Editing profile failed');
      }
    } else {}
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
    return FutureBuilder<Map<String, dynamic>>(
      // Fetch user profile data here
      future: ApiService.fetchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while fetching data
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Handle errors
          return Text('Error: ${snapshot.error}');
        } else {
          // Once data is loaded, display the dashboard
          final Map<String, dynamic> user = snapshot.data!;

          //user['picture'] = _imageProvider; //AUSKOMMENTIERT. NOTEWENDIG ??????????----

          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit Profile'),
              /*leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    // Custom behavior when the back button is pressed
                    // For example, you can navigate to a different screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DashboardScreen()),
                    );
                  }),*/
              //automaticallyImplyLeading: false,

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
                                "Here you can edit your profile. You can change your email, first name, last name and your profile picture."),
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
            //drawer: AppDrawer(user: user),

            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ClipOval(
                      child: CircleAvatar(
                        radius: 80,
                        backgroundImage: user['picture'] != null &&
                                user['picture'] is Map<String, dynamic> &&
                                user['picture']['data'] != null
                            ? MemoryImage(Uint8List.fromList(
                                user['picture']['data'].cast<int>()))
                            : null,
                        //_imageProvider,
                        child: Text(
                          '${user["first_name"][0].toUpperCase()}${user["last_name"][0].toUpperCase()}',
                          style: TextStyle(
                              fontSize: 75), // Change the size of initials
                        ),
                      ),
                    ),
                    Visibility(
                        visible: isEditing,
                        child: ElevatedButton(
                          onPressed: isEditing ? _pickImage : null,
                          child: Text('Change Profile Picture'),
                        )),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        enabled: false,
                        border: const OutlineInputBorder(),
                        errorText: usernameError,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        enabled: isEditing,
                        border: const OutlineInputBorder(),
                        errorText: emailError,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: firstnameController,
                      decoration: InputDecoration(
                        labelText: 'First name',
                        enabled: isEditing,
                        border: const OutlineInputBorder(),
                        errorText: firstnameError,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: lastnameController,
                      decoration: InputDecoration(
                        labelText: 'Last name',
                        enabled: isEditing,
                        border: const OutlineInputBorder(),
                        errorText: lastnameError,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Visibility(
                        visible: isEditing,
                        child: TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'New password',
                            enabled: isEditing,
                            border: const OutlineInputBorder(),
                            errorText: passwordError,
                          ),
                        )),
                    const SizedBox(height: 16.0),
                    Visibility(
                        visible: isEditing,
                        child: TextField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirm password',
                            enabled: isEditing,
                            border: const OutlineInputBorder(),
                            errorText: usernameError,
                          ),
                        )),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      child: Icon(isEditing ? Icons.save : Icons.edit),
                      onPressed: isEditing ? EditUserProfile : toggleEditMode,
                    ),
                    const SizedBox(height: 16.0),
                    Visibility(
                        visible: isEditing,
                        child: ElevatedButton(
                          onPressed: DeleteProfile,
                          child: Text("Delete Account"),
                        ))
                  ],
                ),
              ),
            ),
            drawer: AppDrawer(user: user),
          );
        }
      },
    );
  }

  void toggleEditMode() async {
    bool correctPassword = await verifyPassword();
    if (!isEditing && correctPassword) {
      setState(() {
        isEditing = true;
      });
    } else if (isEditing) {
      setState(() {
        isEditing = false;
      });
    }
  }

  Future<String> verify() async {
    Completer<String> completer = Completer<String>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter verification code'),
          content: OtpTextField(
            numberOfFields: 6,
            //       borderColor: Color(0xFF512DA8),
            showFieldAsBox: true,
            keyboardType: TextInputType.number,
            //       focusedBorderColor: Colors.blue,
            autoFocus: true,
            onSubmit: (String verificationCode) {
              if (double.tryParse(verificationCode) == null) {
                showSnackBar(
                  isError: true,
                  message: 'Verification code needs to consist of digits',
                );
                return;
              }
              Navigator.of(context).pop(); // Close the AlertDialog
              completer
                  .complete(verificationCode); // Complete with entered code
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                completer.completeError('User cancelled');
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );

    try {
      return await completer.future; // Wait for the Future to complete
    } catch (error) {
      return ''; // Handle error or return a default value
    }
  }

  Future<bool> verifyPassword() async {
    Completer<bool> completer = Completer<bool>();
    TextEditingController currentPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter your current password'),
          content: TextField(
            controller: currentPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Password',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                completer.completeError('User cancelled');
              },
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Make an HTTP request to verify the password on the backend
                  Map<String, dynamic> request = {
                    'userid': user_id,
                    'password': currentPasswordController.text,
                  };

                  const storage = FlutterSecureStorage();
                  final token = await storage.read(key: 'token');

                  final response = await http.post(
                    Uri.parse('${ApiService.serverUrl}/verifyPassword'),
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $token',
                    },
                    body: json.encode(request),
                  );

                  print(
                      'Verification Response: ${response.statusCode} - ${response.body}');

                  if (response.statusCode == 200) {
                    // Password is correct, set completer to true
                    Navigator.of(context).pop(); // Close the AlertDialog
                    completer.complete(true);
                  } else {
                    // Password is incorrect, show an error message
                    showSnackBar(
                      isError: true,
                      message: 'Incorrect password',
                    );
                  }
                } catch (error) {
                  // Handle error or show an error message
                  showSnackBar(
                    isError: true,
                    message: 'Error verifying password: $error',
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );

    try {
      return await completer.future;
    } catch (error) {
      return false; // Handle error or return a default value
    }
  }
}
