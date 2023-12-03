import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

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
        Uri.parse('${ApiService.serverUrl}/transactions'),
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
  int transaction_id;
  int sender_id;
  int receiver_id;
  String senderUsername;
  String receiverUsername;
  double amount;
  String transactionType;
  DateTime createdAt;
  String message;
  int? event_id;
  int processed;

  Transaction({
    required this.transaction_id,
    required this.sender_id,
    required this.receiver_id,
    required this.senderUsername,
    required this.receiverUsername,
    required this.amount,
    required this.transactionType,
    required this.createdAt,
    required this.message,
    required this.event_id,
    required this.processed,
  });

  // Factory method to create a Transaction object from JSON data
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transaction_id: json['transaction_id'],
      sender_id: json['sender_id'],
      receiver_id: json['receiver_id'],
      senderUsername: json['sender_username'],
      receiverUsername: json['receiver_username'],
      amount: double.parse(json['amount'].toString()),
      transactionType: json['transaction_type'],
      createdAt: DateTime.parse(json['created_at']),
      message: json['message'],
      event_id: json['event_id'],
      processed: json['processed'],
    );
  }
}

// TransactionItem is a widget that displays a single transaction in a list
class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final int userId;

  const TransactionItem({
    Key? key,
    required this.transaction,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine if the transaction is a received or sent transaction
    bool isReceived = transaction.receiver_id == userId;

    // Determine the color based on transaction type
    Color iconColor;
    Color textColor;
    if (transaction.transactionType == 'Request') {
      // Request transaction
      iconColor = Colors.orange;
      textColor =
          Colors.black; // You can customize the color for request transactions
    } else {
      // Money transaction
      iconColor = isReceived ? Colors.green : Colors.red;
      textColor =
          Colors.black; // You can customize the color for money transactions
    }

    return ListTile(
      key: ValueKey<int>(transaction.transaction_id), // Add a key

      leading: Icon(
        Icons.monetization_on,
        color: iconColor,
      ),
      title: Text(
        isReceived
            ? '${transaction.transactionType} from ${transaction.senderUsername}'
            : '${transaction.transactionType} to ${transaction.receiverUsername}',
        style: TextStyle(color: textColor),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\€${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}',
            style: TextStyle(color: textColor),
          ),
          Text(
            'Type: ${transaction.transactionType}',
            style: TextStyle(
              color: textColor,
            ),
          ),
          Text(
            'Status: ${getStatusText(transaction)}',
            style: TextStyle(
              color: getStatusColor(transaction),
            ),
          ),
        ],
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

  String getStatusText(Transaction transaction) {
    if (transaction.transactionType == 'Request') {
      // For request transactions, display the status
      if (transaction.processed == 1) {
        return 'Processed';
      } else if (transaction.processed == 2) {
        return 'Denied';
      } else {
        return 'Unprocessed';
      }
    } else {
      // For money transactions, no additional status text needed
      return '';
    }
  }

  Color getStatusColor(Transaction transaction) {
    if (transaction.transactionType == 'Request') {
      // For request transactions, determine the color based on the status
      if (transaction.processed == 1) {
        return Colors.green;
      } else if (transaction.processed == 2) {
        return Colors.red;
      } else {
        return Colors
            .black; // You can customize the color for unprocessed requests
      }
    } else {
      // For money transactions, no additional status color needed
      return Colors.black;
    }
  }
}

// TransactionDetailScreen displays detailed information about a transaction
class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({Key? key, required this.transaction})
      : super(key: key);

  // Function to handle accepting the request
  Future<void> acceptRequest(BuildContext context) async {
    // Make an API request to accept the request
    // Implement  API call to update the processed column to 1 and handle the money transfer

    // Show a success message or handle errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request accepted successfully'),
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate back to the transaction history screen
    Navigator.pop(context);
  }

  // Function to handle denying the request
  Future<void> denyRequest(BuildContext context) async {
    // Make an API request to deny the request
    // Implement API call to update the processed column to 2

    // Show a success message or handle errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request denied successfully'),
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate back to the transaction history screen
    Navigator.pop(context);
  }

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
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  transaction.transactionType == 'Payment'
                      ? 'To: ${transaction.receiverUsername}'
                      : 'From: ${transaction.senderUsername}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Amount: \€${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),
                Text(
                  'Type: ${transaction.transactionType}',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),
                Text(
                  'Date: ${DateFormat('dd/MM/yyyy').format(transaction.createdAt)}',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),
                Text(
                  'Time: ${DateFormat('HH:mm:ss').format(transaction.createdAt)}',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),
                if (transaction.message.isNotEmpty)
                  Text('Message: ${transaction.message}',
                      style: TextStyle(fontSize: 20)),

                // Add buttons for accepting and denying the request
                // buttons only appear when the transaction is a request and the transaction is unprocessed and the sender is not the current user
                if (transaction.transactionType == 'Request' &&
                    transaction.processed == 0 &&
                    transaction.sender_id != ApiService.fetchUserId)
                  Column(
                    children: [
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => acceptRequest(context),
                        child: Text('Accept Request'),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => denyRequest(context),
                        child: Text('Deny Request'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
