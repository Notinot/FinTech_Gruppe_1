import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Events/EditEventScreen.dart';
import 'package:flutter_application_1/Screens/Money/TransactionHistoryScreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../api_service.dart';

class SendMoneyScreen extends StatefulWidget {
  final String recipient;

  SendMoneyScreen({
    super.key,
    this.recipient = '',
  });

  @override
  _SendMoneyScreenState createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final TextEditingController recipientController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  Color recipientBorderColor = Colors.grey;
  Color amountBorderColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    widget.recipient.isNotEmpty //used in FriendsSreen
        ? recipientController.text = widget.recipient
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
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
                          "This is the send money screen. Here you can send money to other users.\nPlease enter the recipient's username, the amount and an optional message.\nAfter clicking the 'Send Money' button, you will be asked to confirm the transaction."),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Send money to:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: recipientController,
              decoration: InputDecoration(
                hintText: 'Enter username',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Amount:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(
                hintText: '0,00', // Initial value
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true), // Allow decimals
              onChanged: (value) {
                if (value.isNotEmpty) {
                  // Remove any non-numeric characters
                  final cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');

                  // Convert the cleaned value to an integer
                  final intValue = int.tryParse(cleanedValue) ?? 0;

                  // Format the integer as a currency value with the correct pattern
                  final formattedAmount = NumberFormat.currency(
                    decimalDigits: 2,
                    symbol: '€', // Euro sign
                    locale: 'de_DE', // German locale for correct separators
                  ).format(intValue / 100);

                  amountController.text = formattedAmount;
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Message:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Enter a message (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.chat),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final recipient = recipientController.text;
                  final amount = amountController.text;
                  print(amount);
                  final message = messageController.text;

                  //message limit of 250 characters
                  if (message.length > 250) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Message limit of 250 characters reached'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Remove euro sign, periods and spaces
                  final cleanedAmountText = amount
                      .replaceAll('€', '')
                      .replaceAll(' ', '')
                      .replaceAll('.', '');

                  // Replace commas with periods
                  final normalizedAmountText =
                      cleanedAmountText.replaceAll(',', '.');

                  // Parse the amount
                  final parsedAmount =
                      double.tryParse(normalizedAmountText) ?? 0.0;

                  print(parsedAmount);
                  //set limit for adding money to 50.000,00
                  if (parsedAmount > 50000) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Limit of 50.000,00€ reached'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (recipient.trim().isEmpty) {
                    setState(() {
                      recipientBorderColor = Colors.red;
                    });
                    showErrorSnackBar(context, 'Recipient cannot be empty');
                    return;
                  } else {
                    setState(() {
                      recipientBorderColor = Colors.grey;
                    });
                  }

                  if (parsedAmount <= 0) {
                    setState(() {
                      amountBorderColor = Colors.red;
                    });
                    showErrorSnackBar(context, 'Enter a valid amount');
                    return;
                  } else {
                    setState(() {
                      amountBorderColor = Colors.grey;
                    });
                  }
                  // wait for user to confirm the transaction
                  final confirmed = await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Confirm'),
                        content: Text('send €$parsedAmount to $recipient?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            child: const Text('Confirm'),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirmed == null || !confirmed) {
                    // User cancelled the transaction
                    return;
                  }
                  // check if user is sending money to himself
                  final Map<String, dynamic> user =
                      await ApiService.fetchUserProfile();

                  if (recipient == user['username']) {
                    showErrorSnackBar(
                        context, 'You cannot send money to yourself');
                    return;
                  }

                  bool success = false;
                  bool correctPassword = await verifyPassword();

                  // if user confirms the transaction, send the money
                  if (correctPassword) {
                    success = await sendMoney(recipient, parsedAmount, message);
                  } else {}

                  if (success) {
                    // Clear the input fields after sending money
                    recipientController.clear();
                    amountController.clear();
                    messageController.clear();

                    // Show success snackbar
                    showSuccessSnackBar(context,
                        '€$parsedAmount sent successfully to $recipient');

                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionHistoryScreen(),
                      ),
                    );
                  } else {
                    // Show error snackbar
                    showErrorSnackBar(context, 'Failed to send money');
                  }
                },
                child: Text('Send Money'), // Add this line
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> sendMoney(
      String recipient, double amount, String message) async {
    try {
      // Retrieve the JWT token from secure storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        if (kDebugMode) {
          print('JWT token not found.');
        }
        return false;
      }
      if (kDebugMode) {
        print('token: $token');
      }
      // Continue with the send money request
      final sendMoneyResponse = await http.post(
        Uri.parse('${ApiService.serverUrl}/send-money-checkBlocked'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(<String, dynamic>{
          'recipient': recipient,
          'amount': amount,
          'message': message,
          'event_id': null,
        }),
      );
      print(sendMoneyResponse);
      if (sendMoneyResponse.statusCode == 200) {
        // Money sent successfully
        return true;
      } else {
        // Money transfer failed, handle accordingly
        print('Error sending money: ${sendMoneyResponse.body}');
        return false;
      }
    } catch (e) {
      // Exception occurred, handle accordingly
      print('Error sending money: $e');
      return false;
    }
  }

  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
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
            ElevatedButton(
              onPressed: () async {
                try {
                  // Make an HTTP request to verify the password on the backend
                  Map<String, dynamic> request = {
                    'userid': await ApiService.getUserId(),
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
                        context: context);
                  }
                } catch (error) {
                  // Handle error or show an error message
                  showSnackBar(
                      isError: true,
                      message: 'Error verifying password: $error',
                      context: context);
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
