import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

// TransactionHistoryScreen is a StatefulWidget that displays a user's transaction history.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  _TransactionHistoryScreenState createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  // Future to hold a list of transactions
  late Future<List<Transaction>> transactionsFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the Future to fetch transactions
    transactionsFuture = fetchTransactions();
  }

  // Function to fetch transactions from the API
  Future<List<Transaction>> fetchTransactions() async {
    try {
      // Retrieve the user's authentication token from secure storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      // Handle the case where the token is not available
      if (token == null) {
        throw Exception('Token not found');
      }

      // Make an HTTP GET request to fetch transactions
      final response = await http.get(
        Uri.parse('http://localhost:3000/transactions'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the JSON response and create a list of Transaction objects
        final List<dynamic> data = json.decode(response.body);
        final List<dynamic> transactionsData = data[0];
        List<Transaction> transactions =
            transactionsData.map((transactionData) {
          return Transaction.fromJson(transactionData as Map<String, dynamic>);
        }).toList();

        // Sort transactions in descending order based on the createdAt field
        transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return transactions;
      } else {
        // Handle errors if the request is not successful
        throw Exception(
            'Error fetching transactions. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the UI using FutureBuilder for asynchronous data loading
    return FutureBuilder<Map<String, dynamic>>(
      // Fetch user profile data
      future: ApiService.fetchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while fetching data
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          // Handle errors
          return Text('Error: ${snapshot.error}');
        } else {
          // Once data is loaded, display the screen
          final Map<String, dynamic> user = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Transaction History'),
            ),
            body: FutureBuilder<List<Transaction>>(
              future: transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Show a loading indicator while fetching transaction data
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  // Display an error message if the transaction data cannot be loaded
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  // Display a message if there are no transactions
                  return const Center(child: Text('No transactions found.'));
                } else {
                  // Display the list of transactions
                  List<Transaction> transactions = snapshot.data!;
                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      return TransactionItem(
                          transaction: transactions[index],
                          userId: user['user_id']);
                    },
                  );
                }
              },
            ),
          );
        }
      },
    );
  }
}

// Transaction class represents a financial transaction with relevant details
class Transaction {
  int transactionId;
  int sender_id;
  int receiver_id;
  String senderUsername;
  String receiverUsername;
  double amount;
  String transactionType;
  DateTime createdAt;
  String message;

  Transaction({
    required this.transactionId,
    required this.sender_id,
    required this.receiver_id,
    required this.senderUsername,
    required this.receiverUsername,
    required this.amount,
    required this.transactionType,
    required this.createdAt,
    required this.message,
  });

  // Factory method to create a Transaction object from JSON data
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transaction_id'],
      sender_id: json['sender_id'],
      receiver_id: json['receiver_id'],
      senderUsername: json['sender_username'],
      receiverUsername: json['receiver_username'],
      amount: double.parse(json['amount'].toString()),
      transactionType: json['transaction_type'],
      createdAt: DateTime.parse(json['created_at']),
      message: json['message'],
    );
  }
}

// TransactionItem is a widget that displays a single transaction in a list
class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final int userId;

  const TransactionItem(
      {Key? key, required this.transaction, required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine if the transaction is a received or sent transaction
    bool isReceived = transaction.receiver_id == userId;
    return ListTile(
      key: ValueKey<int>(transaction.transactionId), // Add a key

      leading: Icon(
        Icons.monetization_on,
        color: isReceived ? Colors.green : Colors.red,
      ),
      title: Text(isReceived
          ? 'Received from ${transaction.senderUsername}'
          : 'Payment to ${transaction.receiverUsername}'),
      subtitle: Text(
        '\€${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}',
      ),
      trailing: Text(
        DateFormat('dd/MM/yyyy').format(transaction.createdAt),
        style: const TextStyle(fontSize: 12),
      ),
      onTap: () {
        // Navigate to the TransactionDetailScreen when tapped
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

// TransactionDetailScreen displays detailed information about a transaction
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
                Text(
                    transaction.transactionType == 'Payment'
                        ? 'From: ${transaction.senderUsername}'
                        : 'To: ${transaction.receiverUsername}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
                SizedBox(height: 10),
                Text(
                    transaction.transactionType == 'Payment'
                        ? 'To: ${transaction.receiverUsername}'
                        : 'From: ${transaction.senderUsername}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
                SizedBox(height: 10),
                Text(
                    'Amount: \€${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}',
                    style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text('Type: ${transaction.transactionType}',
                    style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text(
                    'Date: ${DateFormat('dd/MM/yyyy').format(transaction.createdAt)}',
                    style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text(
                    'Time: ${DateFormat('HH:mm:ss').format(transaction.createdAt)}',
                    style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                if (transaction.message.isNotEmpty)
                  Text('Message: ${transaction.message}',
                      style: TextStyle(fontSize: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
