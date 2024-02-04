import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter_application_1/Screens/EditUser/ChangePasswortScreen.dart';
import 'package:flutter_application_1/Screens/Login%20&%20Register/ForgotPasswortScreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Dashboard/dashBoardScreen.dart';
import 'RegistrationScreen.dart';
import '../api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController verificationCodeController =
      TextEditingController();

  bool requiresVerification = false;
  bool accountLocked = false;

  // Check if the user is active, requires verification, or is locked
  Future<void> checkUserActiveStatus(String email) async {
    final response = await http.post(
      // Uri.parse('http://192.168.178.28:3000/check-active'),
      Uri.parse(
          '${ApiService.serverUrl}/check-active'), // Use the correct route
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final isActive = data['active'];

      if (isActive == 0) {
        setState(() {
          requiresVerification = true;
        });
      } else if (isActive == 1) {
        setState(() {
          requiresVerification = false;
        });
      } else if (isActive == 2) {
        setState(() {
          accountLocked = true;
        });
      }
    } else {}
  }

  void handleLogin() async {
    final String email = emailController.text;
    final String password = passwordController.text;
    if (_formKey.currentState!.validate()) {
      // Call checkUserActiveStatus to determine if the user requires verification
      await checkUserActiveStatus(email);
      if (accountLocked) {
        accountLocked = false;
        //navigate to forgot password screen
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChangePasswordScreen(email: email)),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Account has been locked. Please check your email for a verification code.'),
            backgroundColor: Colors.red,
          ),
        );

        emailController.clear();
        passwordController.clear();
        verificationCodeController.clear();

        return;
      }

      if (requiresVerification) {
        final verificationCode = verificationCodeController.text;
        if (verificationCode.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter the Verification code sent to you'),
              backgroundColor: Colors.red,
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
        // Uri.parse('http://192.168.178.28:3000/login'),
        Uri.parse('${ApiService.serverUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final token = data['token'];
        final userID = data['user_id'];
        // Save the token securely
        const storage = FlutterSecureStorage();
        await storage.write(key: 'token', value: token);
        //save the user id
        await storage.write(key: 'user_id', value: userID.toString());
        print("LoginScreen: user id = " + userID.toString());

        // Navigate to the dashboard with the obtained token
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(),
          ),
        );
      } else if (response.statusCode == 402) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Account has been locked. Please check your email for a verification code.'),
            backgroundColor: Colors.red,
          ),
        );
        emailController.clear();
        passwordController.clear();
        verificationCodeController.clear();
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChangePasswordScreen(email: email)),
        );
        setState(() {
          requiresVerification = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Invalid email, password, or verification code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );

        emailController.clear();
        passwordController.clear();
        verificationCodeController.clear();
        //remove verification code field
        setState(() {
          requiresVerification = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // title: const Text("Login"),
          // titleTextStyle:
          //     const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          // // backgroundColor: Colors.blueAccent,
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
                            "This is the Login Screen. Here you can login with your email and password.\n\nIf you don't have an account yet or forgot your password, you can register or reset your password by clicking on the respective links below the login button."),
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
          //  backgroundColor: Colors.blueGrey,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset('lib/assets/payfriendz_logo.png',
                      width: 320, height: 320),
                  //const SizedBox(height: 10.0),
                  _buildTextFormField(emailController, 'Email', Icons.email,
                      (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    // if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                    //   return 'Please enter a valid email address';
                    // }
                    return null;
                  }),
                  const SizedBox(height: 16.0),
                  _buildTextFormField(
                      passwordController, 'Password', Icons.lock, (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  }, isPassword: true),
                  if (requiresVerification) const SizedBox(height: 12.0),
                  if (requiresVerification)
                    _buildTextFormField(verificationCodeController,
                        'Verification Code', Icons.verified_user, (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the verification code';
                      }
                      return null;
                    }),
                  const SizedBox(height: 30.0),
                  ElevatedButton(
                    onPressed: handleLogin,
                    style: ElevatedButton.styleFrom(
                      // primary: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 18.0), //color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 50.0),
                  _buildRichText("Don't have an account yet? ", "Register here",
                      RegistrationScreen()),
                  SizedBox(height: 12.0),
                  _buildRichText("Forgot password? ", "Click here",
                      ForgotPasswordScreen()),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildTextFormField(TextEditingController controller, String label,
      IconData icon, String? Function(String?)? validator,
      {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(),
        //  fillColor: Colors.blueGrey[50],
        filled: true,
        errorStyle: const TextStyle(color: Colors.red),
      ),
    );
  }

  // Helper method for text fields
  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false}) {
    TextField textField;
    Theme.of(context).brightness == Brightness.dark
        ? textField = TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              labelText: label,
              border: OutlineInputBorder(),
              //  fillColor: Colors.blueGrey[50],
              filled: true,
            ),
          )
        : textField = TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              labelText: label,
              border: OutlineInputBorder(),
              fillColor: Colors.blueGrey[50],
              filled: true,
            ),
          );
    return textField;
  }

  // Helper method for rich text
  Widget _buildRichText(
      String normalText, String clickableText, Widget destination) {
    return RichText(
      text: Theme.of(context).brightness == Brightness.dark
          ? TextSpan(
              //  style: const TextStyle(color: Colors.black, fontSize: 16.0),
              style: const TextStyle(fontSize: 16.0),
              children: [
                TextSpan(text: normalText),
                TextSpan(
                  text: clickableText,
                  style: const TextStyle(
                      color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => Navigator.push(context,
                        MaterialPageRoute(builder: (context) => destination)),
                ),
              ],
            )
          : TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 16.0),
              // style: const TextStyle(fontSize: 16.0),
              children: [
                TextSpan(text: normalText),
                TextSpan(
                  text: clickableText,
                  style: const TextStyle(
                      color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => Navigator.push(context,
                        MaterialPageRoute(builder: (context) => destination)),
                ),
              ],
            ),
    );
  }
}
