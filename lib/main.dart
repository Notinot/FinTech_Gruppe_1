//import 'dart:html';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/themeNotifier.dart';
import 'package:flutter_application_1/assets/color_schemes.g.dart';
import 'package:provider/provider.dart';
import 'Screens/Login & Register/LoginScreen.dart';
import 'package:http/http.dart' as http;
import 'Screens/Dashboard/dashBoardScreen.dart';
import 'Screens/api_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: PayfriendzApp(),
    ),
  );
}

class PayfriendzApp extends StatefulWidget {
  @override
  _PayfriendzAppState createState() => _PayfriendzAppState();
}

class _PayfriendzAppState extends State<PayfriendzApp> {
  bool serverAvailable = false;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkServerAvailability();

    //checkStayLoggedIn(); //COMMENT THIS OUT TO STAY LOGGED IN (in theory)
  }

  Future<void> checkServerAvailability() async {
    final response =
        await http.get(Uri.parse('${ApiService.serverUrl}/health'));
    setState(() {
      serverAvailable = response.statusCode == 200;
    });
  }

  //Testing Stay Logged in function for future implementation
  // Future<void> checkStayLoggedIn() async {
  //   const secureStorage = FlutterSecureStorage();
  //   String? authToken = await secureStorage.read(key: 'token');
  //   print(authToken);
  //   if (authToken != null && authToken.isNotEmpty) {
  //     setState(() {
  //       isLoggedIn = true;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      themeMode: themeNotifier.darkTheme ? ThemeMode.dark : ThemeMode.light,
      home: serverAvailable
          ? isLoggedIn
              ? const DashboardScreen()
              : const LoginScreen()
          : ServerUnavailableScreen(
              onRetry: () {
                checkServerAvailability();
              },
            ),
    );
  }
}

class ServerUnavailableScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const ServerUnavailableScreen({Key? key, required this.onRetry})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Unavailable'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('The server is currently unavailable.'),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
