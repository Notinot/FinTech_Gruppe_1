import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/appDrawer.dart';
import 'package:flutter_application_1/Screens/Dashboard/dashBoardScreen.dart';
import 'package:flutter_application_1/Screens/Money/TransactionHistoryScreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../api_service.dart';

class RequestMoneyScreen extends StatefulWidget {
  final String requester;
  RequestMoneyScreen({
    super.key,
    this.requester = '',
  });

  @override
  _RequestMoneyScreenState createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends State<RequestMoneyScreen> {
  final TextEditingController requesterController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  late Color requesterBorderColor;
  late Color amountBorderColor;

  @override
  Widget build(BuildContext context) {
    widget.requester.isNotEmpty //used in FriendsSreen
        ? requesterController.text = widget.requester
        : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Money'),
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
                          "This feature allows you to request money from other users. You need to enter the recipient's username and the amount you want to request. The message is optional. The recipient will receive a notification and can accept or decline your request."),
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
              'Send request to:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: requesterController,
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
                hintText: '0,00 €', // Initial value
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
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
                  print('amountController.text: ${amountController.text}');
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
                  final recipient = requesterController.text;
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
// Check if the recipient is empty
                  if (recipient.trim().isEmpty) {
                    setState(() {
                      requesterBorderColor = Colors.red;
                    });
                    showErrorSnackBar(context, 'Recipient cannot be empty');
                    return;
                  } else {
                    setState(() {
                      requesterBorderColor = Colors.grey;
                    });
                  }
// Check if the amount is valid
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
                  // check if user is requesting money from himself (username or email)
                  final Map<String, dynamic> user =
                      await ApiService.fetchUserProfile();

                  if (recipient == user['username'] ||
                      recipient == user['email']) {
                    showErrorSnackBar(
                        context, 'You cannot request money from yourself');
                    return;
                  }
                  // wait for user to confirm the transaction
                  final confirmed = await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Request Money'),
                        content: Text(
                          'Are you sure you want to request €$parsedAmount from $recipient?',
                        ),
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
                  // Call the request money function
                  bool success =
                      await requestMoney(recipient, parsedAmount, message);

                  if (success) {
                    // Clear the text fields
                    requesterController.clear();
                    amountController.clear();
                    messageController.clear();

                    // Show success snackbar
                    showSuccessSnackBar(context, 'Request sent to $recipient');

                    //navigate to transaction history
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionHistoryScreen(),
                      ),
                    );
                  } else {
                    // Show error snackbar
                    showErrorSnackBar(context, 'Error requesting money');
                  }
                },
                style: ElevatedButton.styleFrom(
                  //  foregroundColor: Colors.white,
                  //  backgroundColor: Colors.blue, // Text color
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Request Money',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> requestMoney(
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

      // Continue with the request money request
      final requestMoneyResponse = await http.post(
        Uri.parse('${ApiService.serverUrl}/request-money'),
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

      if (requestMoneyResponse.statusCode == 200) {
        // Request for money sent successfully
        return true;
      } else {
        // Request for money failed, handle accordingly
        print('Error requesting money: ${requestMoneyResponse.body}');
        return false;
      }
    } catch (e) {
      // Exception occurred, handle accordingly
      print('Error requesting money: $e');
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
}
