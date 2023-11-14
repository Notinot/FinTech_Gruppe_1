import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
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
      final storage = FlutterSecureStorage();
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
        final List<Transaction> transactions =
            transactionsData.map((transactionData) {
          return Transaction.fromJson(transactionData as Map<String, dynamic>);
        }).toList();

        return transactions;
      } else {
        throw Exception(
            'Error fetching transactions. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching transactions: $error');
      // Handle error
      throw error;
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
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // If the Future throws an error, display the error message
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // If the Future completes successfully but with no data, show a message
            return Center(child: Text('No transactions found.'));
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
  int senderId;
  int receiverId;
  double amount;
  String transactionType;
  DateTime createdAt;
  String message;

  Transaction({
    required this.transactionId,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.transactionType,
    required this.createdAt,
    required this.message,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transaction_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
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
            : Icons.attach_money,
        color: transaction.transactionType == 'Payment'
            ? Colors.red
            : Colors.green,
      ),
      title: Text(transaction.transactionType),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount: \$${transaction.amount.toStringAsFixed(2)}',
          ),
          if (transaction.message.isNotEmpty)
            Text('Message: ${transaction.message}'),
        ],
      ),
      trailing: Text(
        DateFormat('dd/MM/yyyy').format(transaction.createdAt),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
