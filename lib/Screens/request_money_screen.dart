import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class RequestMoneyScreen extends StatefulWidget {
  RequestMoneyScreen({super.key});

  @override
  _RequestMoneyScreenState createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends State<RequestMoneyScreen> {
  final TextEditingController requesterController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  Color requesterBorderColor = Colors.grey;
  Color amountBorderColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Money'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Request from:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: requesterController,
              decoration: InputDecoration(
                hintText: 'Enter your name or email',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: requesterBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: requesterBorderColor),
                ),
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
                hintText: 'Enter a message for the payer',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                prefixIcon: Icon(Icons.chat),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final requester = requesterController.text;
                  final amount = double.tryParse(amountController.text
                          .replaceAll('€', '') // Remove euro sign
                          .replaceAll('.', '') // Remove periods
                          .replaceAll(',', '') // Remove commas
                          .trim()) ??
                      0.0;
                  final message = messageController.text;

                  if (requester.trim().isEmpty) {
                    setState(() {
                      requesterBorderColor = Colors.red;
                    });
                    showErrorSnackBar(context, 'Requester cannot be empty');
                  } else {
                    setState(() {
                      requesterBorderColor = Colors.grey;
                    });
                  }

                  if (amount <= 0) {
                    setState(() {
                      amountBorderColor = Colors.red;
                    });
                    showErrorSnackBar(context, 'Enter a valid amount');
                  } else {
                    setState(() {
                      amountBorderColor = Colors.grey;
                    });
                  }

                  if (requester.trim().isEmpty || amount <= 0) {
                    return;
                  }

                  // Use the sendMoney method
                  bool success = await requestMoney(requester, amount, message);

                  if (success) {
                    // Clear the input fields after sending money
                    requesterController.clear();
                    amountController.clear();
                    messageController.clear();

                    // Show success snackbar
                    showSuccessSnackBar(context, 'Request sent to $requester');
                  } else {
                    // Show error snackbar
                    showErrorSnackBar(context, 'Error requesting money');
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue, // Text color
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
        Uri.parse('http://localhost:3000/request-money'),
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
