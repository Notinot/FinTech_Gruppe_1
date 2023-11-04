import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SendMoneyScreen extends StatelessWidget {
  final TextEditingController recipientController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  SendMoneyScreen({super.key});

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
              decoration: const InputDecoration(
                hintText: 'Enter recipient name or email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
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
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.chat),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final recipient = recipientController.text;
                  final amount = double.tryParse(amountController.text
                          .replaceAll('€', '') // Remove euro sign
                          .replaceAll('.', '') // Remove periods
                          .replaceAll(',', '') // Remove commas
                          .trim()) ??
                      0.0;
                  final message = messageController.text;

                  if (recipient.trim().isEmpty) {
                    showErrorSnackBar(context, 'Recipient cannot be empty');
                  } else if (amount <= 0) {
                    showErrorSnackBar(context, 'Enter a valid amount');
                  }else {
                    // Implement the logic to send money
                    // Once money is sent, you can show a success message
                    showSuccessSnackBar(
                        context, 'Money sent successfully to $recipient');

                    // Clear the input fields after sending money
                    recipientController.clear();
                    amountController.clear();
                    messageController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Send Money',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      ),
    );
  }
}
