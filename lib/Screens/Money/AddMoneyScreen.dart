import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/accountSummary.dart';
import 'package:flutter_application_1/Screens/Dashboard/appDrawer.dart';
import 'package:flutter_application_1/Screens/Dashboard/dashBoardScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:intl/intl.dart';

class AddMoneyScreen extends StatefulWidget {
  @override
  _AddMoneyScreenState createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  late Future<Map<String, dynamic>> _userFuture;
  double balance = 0.0;
  final TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userFuture = ApiService.fetchUserProfile();
    _fetchUserBalance();
  }

  void _fetchUserBalance() async {
    final value = await ApiService.fetchUserBalance();
    setState(() {
      balance = value;
    });
  }

  void _showAddMoneyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Money'),
          content: Container(
            width: 250,
            child: TextFormField(
              controller: amountController,
              decoration: InputDecoration(
                hintText: '0.00 €',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                  final intValue = int.tryParse(cleanedValue) ?? 0;
                  final formattedAmount = NumberFormat.currency(
                    decimalDigits: 2,
                    symbol: '€',
                    locale: 'de_DE',
                  ).format(intValue / 100);

                  amountController.text = formattedAmount;
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _addMoney(),
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

  void _addMoney() async {
    final amount = amountController.text;
    final cleanedAmountText =
        amount.replaceAll('€', '').replaceAll(' ', '').replaceAll('.', '');
    final normalizedAmountText = cleanedAmountText.replaceAll(',', '.');
    final parsedAmount = double.tryParse(normalizedAmountText) ?? 0.0;

    //set limit for adding money to 50.000,00
    if (parsedAmount > 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can add maximum 50.000,00 €'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await ApiService.addMoney(parsedAmount);

    if (success) {
      _fetchUserBalance();

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Money added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add money'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Money'),
      ),
      drawer: FutureBuilder<Map<String, dynamic>>(
        // Fetch user profile data for the drawer
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Drawer(); // You can return a loading state or an empty drawer
          } else if (snapshot.hasError) {
            return Drawer(); // Handle error state or return an empty drawer
          } else {
            final Map<String, dynamic> user = snapshot.data!;
            return AppDrawer(user: user);
          }
        },
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display user's account summary
              AccountSummary(balance.toDouble()),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showAddMoneyDialog,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Add'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
