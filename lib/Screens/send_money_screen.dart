import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class SendMoneyScreen extends StatefulWidget {
  SendMoneyScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Recipient:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: recipientController,
              decoration: InputDecoration(
                hintText: 'Enter recipient name or email',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: recipientBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: recipientBorderColor),
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
                hintText: 'Enter a message for the recipient',
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
                  final recipient = recipientController.text;
                  final amount = amountController.text;
                  print(amount);
                  final message = messageController.text;

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
                  // Use the sendMoney method
                  bool success =
                      await sendMoney(recipient, parsedAmount, message);

                  if (success) {
                    // Clear the input fields after sending money
                    recipientController.clear();
                    amountController.clear();
                    messageController.clear();

                    // Show success snackbar
                    showSuccessSnackBar(
                        context, 'Money sent successfully to $recipient');
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
        Uri.parse('http://localhost:3000/send-money'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(<String, dynamic>{
          'recipient': recipient,
          'amount': amount,
          'message': message,
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
}
