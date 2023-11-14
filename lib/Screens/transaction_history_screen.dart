import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _TransactionHistoryScreenState createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<Transaction>> transactionsFuture;

  @override
  void initState() {
    super.initState();
    transactionsFuture = fetchTransactions();
  }

  Future<List<Transaction>> fetchTransactions() async {
    try {
      // Retrieve the token from secure storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        // Handle the case where the token is not available
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('http://localhost:3000/transactions'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        final List<dynamic> data = json.decode(response.body);
        print('Response Body: ${response.body}');
        final List<dynamic> transactionsData = data[0]; // Access the inner list
        List<Transaction> transactions =
            transactionsData.map((transactionData) {
          return Transaction.fromJson(transactionData as Map<String, dynamic>);
        }).toList();

        // Sort the transactions in descending order of the createdAt field
        transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return transactions;
      } else {
        throw Exception(
            'Error fetching transactions. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: FutureBuilder<List<Transaction>>(
        future: transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // If the Future is still running, show a loading indicator
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // If the Future throws an error, display the error message
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // If the Future completes successfully but with no data, show a message
            return const Center(child: Text('No transactions found.'));
          } else {
            // If the Future completes successfully with data, display the list
            List<Transaction> transactions = snapshot.data!;
            return ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                return TransactionItem(transaction: transactions[index]);
              },
            );
          }
        },
      ),
    );
  }
}

class Transaction {
  int transactionId;
  String senderUsername;
  String receiverUsername;
  double amount;
  String transactionType;
  DateTime createdAt;
  String message;

  Transaction({
    required this.transactionId,
    required this.senderUsername,
    required this.receiverUsername,
    required this.amount,
    required this.transactionType,
    required this.createdAt,
    required this.message,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transaction_id'],
      senderUsername: json['sender_username'],
      receiverUsername: json['receiver_username'],
      amount: double.parse(json['amount'].toString()),
      transactionType: json['transaction_type'],
      createdAt: DateTime.parse(json['created_at']),
      message: json['message'],
    );
  }
}

class TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionItem({Key? key, required this.transaction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey<int>(transaction.transactionId), // Add a key

      leading: Icon(
        transaction.transactionType == 'Payment'
            ? Icons.payment
            : Icons.money_off,
        color: transaction.transactionType == 'Payment'
            ? Colors.red
            : Colors.green,
      ),
      title: Text(
          '${transaction.transactionType} to ${transaction.receiverUsername}'),
      subtitle: Text(
        '\€${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}',
      ),
      trailing: Text(
        DateFormat('dd/MM/yyyy').format(transaction.createdAt),
        style: const TextStyle(fontSize: 12),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TransactionDetailScreen(transaction: transaction),
          ),
        );
      },
    );
  }
}

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({Key? key, required this.transaction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Details'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(Icons.person_outline, color: Colors.blue),
                  title: Text('From: ${transaction.senderUsername}',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: Icon(Icons.person_pin, color: Colors.blue),
                  title: Text('To: ${transaction.receiverUsername}',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: Icon(Icons.euro_symbol, color: Colors.blue),
                  title: Text(
                      'Amount: \€${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}',
                      style: TextStyle(fontSize: 20)),
                ),
                ListTile(
                  leading: Icon(
                      transaction.transactionType == 'Payment'
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: Colors.blue),
                  title: Text('Type: ${transaction.transactionType}',
                      style: TextStyle(fontSize: 20)),
                ),
                ListTile(
                  leading: Icon(Icons.date_range, color: Colors.blue),
                  title: Text(
                      'Date: ${DateFormat('dd/MM/yyyy').format(transaction.createdAt)}',
                      style: TextStyle(fontSize: 20)),
                ),
                ListTile(
                  leading: Icon(Icons.access_time, color: Colors.blue),
                  title: Text(
                      'Time: ${DateFormat('HH:mm:ss').format(transaction.createdAt)}',
                      style: TextStyle(fontSize: 20)),
                ),
                if (transaction.message.isNotEmpty)
                  ListTile(
                    leading: Icon(Icons.message, color: Colors.blue),
                    title: Text('Message: ${transaction.message}',
                        style: TextStyle(fontSize: 20)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
