import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/dashBoardScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:intl/intl.dart';

class AddMoneyScreen extends StatefulWidget {
  @override
  _AddMoneyScreenState createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  double balance = 0.0;
  final TextEditingController amountController = TextEditingController();
  //fetch the user's balance from the database, use the fetchUserBalance function from api_service.dart
  @override
  void initState() {
    super.initState();
    ApiService.fetchUserBalance().then((value) {
      setState(() {
        balance = value;
      });
    });
  }

  //show the add money dialo

  void _showAddMoneyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Money'),
          content: TextFormField(
            controller: amountController,
            decoration: const InputDecoration(
              hintText: '0,00 €', // Initial value
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

                // Update the text field
                amountController.text = formattedAmount;
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                final amount = amountController.text;
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
                //add the money to the user's balance in the database
                ApiService.addMoney(parsedAmount).then((value) {
                  if (value) {
                    // Update the balance
                    ApiService.fetchUserBalance().then((value) {
                      setState(() {
                        balance = value;
                      });
                    });

                    // Close the dialog
                    Navigator.of(context).pop();

                    // Show a success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Money added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    //Navigate to the dashboard
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DashboardScreen()));
                  } else {
                    // Show an error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add money'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                });
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Money'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Balance: \€${balance.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showAddMoneyDialog,
              child: Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
