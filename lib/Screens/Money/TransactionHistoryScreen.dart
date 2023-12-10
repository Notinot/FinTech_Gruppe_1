import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/dashBoardScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_search_bar/flutter_search_bar.dart' as search_bar;
import 'RequestMoneyScreen.dart';
import 'SendMoneyScreen.dart';
import 'package:flutter_application_1/Screens/Money/TransactionHistoryScreen.dart';

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
  late search_bar.SearchBar searchBar;

  List<Transaction> allTransactions = [];

  @override
  void initState() {
    super.initState();
    transactionsFuture = fetchTransactions();
    searchBar = search_bar.SearchBar(
      showClearButton: true,
      inBar: false,
      setState: setState,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      onCleared: onCleared,
      onClosed: onClosed,
      buildDefaultAppBar: buildAppBar,
      hintText: "Search",
    );
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

  // Function to build the AppBar
  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: Text('Transaction History'),
      actions: [searchBar.getSearchAction(context)],
    );
  }

  Future<void> onSubmitted(String value) async {
    // Apply the filter only if the user has entered a search query
    if (value.isNotEmpty) {
      List<Transaction> filteredTransactions = allTransactions
          .where((transaction) =>
              transaction.transactionType
                  .toLowerCase()
                  .contains(value.toLowerCase()) ||
              transaction.senderUsername
                  .toLowerCase()
                  .contains(value.toLowerCase()) ||
              transaction.message.toLowerCase().contains(value.toLowerCase()) ||
              transaction.receiverUsername
                  .toLowerCase()
                  .contains(value.toLowerCase()))
          .toList();
      setState(() {
        transactionsFuture = Future.value(filteredTransactions);
      });
    } else {
      setState(() {
        transactionsFuture = fetchTransactions();
      });
    }
  }

  Future<void> onChanged(String value) async {
    // Handle search value changes
    // Update the UI or filter the list dynamically
    if (value.isNotEmpty) {
      List<Transaction> filteredTransactions = allTransactions
          .where((transaction) =>
              transaction.transactionType
                  .toLowerCase()
                  .contains(value.toLowerCase()) ||
              transaction.senderUsername
                  .toLowerCase()
                  .contains(value.toLowerCase()) ||
              transaction.message.toLowerCase().contains(value.toLowerCase()) ||
              transaction.receiverUsername
                  .toLowerCase()
                  .contains(value.toLowerCase()))
          .toList();
      setState(() {
        transactionsFuture = Future.value(filteredTransactions);
      });
    } else {
      setState(() {
        transactionsFuture = fetchTransactions();
      });
    }
  }

  Future<void> onCleared() async {
    // Handle search bar cleared
    // Update the UI to show the original list without filtering
    setState(() {
      transactionsFuture = fetchTransactions();
    });
  }

  Future<void> onClosed() async {
    //update the UI to show the original list without filtering
    setState(() {
      transactionsFuture = fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the buildAppBar function to build the AppBar
      appBar: searchBar.build(context),
      //add a floating action button to refresh the transaction history screen.make it elevated and add an icon
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            transactionsFuture = fetchTransactions();
          });
        },
        child: const Icon(Icons.refresh),
      ),
      //add a navigation bar at the bottom of the screen to navigate to the send money and request money screens respectively
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.send),
            label: 'Send Money',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: 'Request Money',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SendMoneyScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequestMoneyScreen(),
              ),
            );
          }
        },
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        // Fetch user profile data
        future: ApiService.fetchUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final Map<String, dynamic> user = snapshot.data!;
            return FutureBuilder<List<Transaction>>(
              future: transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No transactions found.'));
                } else {
                  // Save all transactions for reference
                  allTransactions = snapshot.data!;
                  return ListView.builder(
                    itemCount: allTransactions.length,
                    itemBuilder: (context, index) {
                      return TransactionItem(
                        transaction: allTransactions[index],
                        userId: user['user_id'],
                      );
                    },
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}

// Transaction class represents a financial transaction with relevant details
class Transaction {
  int transactionId;
  int senderId;
  int receiverId;
  String senderUsername;
  String receiverUsername;
  double amount;
  String transactionType;
  DateTime createdAt;
  String message;
  int? eventId;
  int processed;

  Transaction({
    required this.transactionId,
    required this.senderId,
    required this.receiverId,
    required this.senderUsername,
    required this.receiverUsername,
    required this.amount,
    required this.transactionType,
    required this.createdAt,
    required this.message,
    required this.eventId,
    required this.processed,
  });

  // Factory method to create a Transaction object from JSON data
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transaction_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      senderUsername: json['sender_username'],
      receiverUsername: json['receiver_username'],
      amount: double.parse(json['amount'].toString()),
      transactionType: json['transaction_type'],
      createdAt: DateTime.parse(json['created_at']),
      message: json['message'],
      eventId: json['event_id'],
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
    bool isReceived = transaction.receiverId == userId;

    //Determine if request is processed or denied or unprocessed
    bool isProcessed = transaction.processed == 1;
    bool isDenied = transaction.processed == 2;

    // Determine the color based on transaction type
    Color iconColor;
    Color textColor;
    if (transaction.transactionType == 'Request') {
      if (isProcessed) {
        if (isReceived) {
          iconColor = Colors.red[400]!;
          textColor = Colors.black;
        } else {
          iconColor = Colors.green[400]!;
          textColor = Colors.black;
        }
      } else if (isDenied) {
        iconColor = Colors.black;
        textColor = Colors.black;
      } else {
        iconColor = Colors.orange[400]!;
        textColor = Colors.black;
      }
    } else {
      // For money transactions, determine the color based on whether the user received or sent money
      if (isReceived) {
        iconColor = Colors.green[400]!;
        textColor = Colors.black;
      } else {
        iconColor = Colors.red[400]!;
        textColor = Colors.black;
      }
    }

    return ListTile(
      key: ValueKey<int>(transaction.transactionId), // Add a key

      // Display the icon based on the transaction type
      leading: Icon(
        transaction.transactionType == 'Request'
            ? Icons.request_page_rounded
            : Icons.monetization_on_rounded,
        color: iconColor,
      ),
      // Display the username of the sender or receiver based on the transaction type
      title: Text(
        transaction.transactionType == 'Request'
            ? isReceived
                //  ? 'From: ${transaction.senderUsername}'
                //  : 'To: ${transaction.receiverUsername}'
                ? '${transaction.senderUsername}'
                : '${transaction.receiverUsername}'
            : isReceived
                //   ? 'From: ${transaction.senderUsername}'
                //   : 'To: ${transaction.receiverUsername}',
                ? '${transaction.senderUsername}'
                : '${transaction.receiverUsername}',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display the amount of the transaction based on the transaction type and whether the user received or sent money
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: transaction.transactionType == 'Request'
                  ? isProcessed
                      ? isReceived
                          ? Colors.red[300]
                          : Colors.green[300]
                      : Colors.transparent
                  : isReceived
                      ? Colors.green[300]
                      : Colors.red[300],
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              transaction.transactionType == 'Request'
                  ? isProcessed
                      ? isReceived
                          ? '-${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}\€'
                          : '+${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}\€'
                      : '${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}\€'
                  : isReceived
                      ? '+${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}\€'
                      : '-${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}\€',
              style: TextStyle(
                color: transaction.transactionType == 'Request'
                    ? isProcessed
                        ? isReceived
                            ? Colors.black
                            : Colors.black
                        : Colors.black
                    : isReceived
                        ? Colors.black
                        : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Display the event name if the transaction is associated with an event
          if (transaction.eventId != null)
            Text(
              'Event: ${transaction.eventId}',
              style: TextStyle(color: textColor),
            ),

          // Display the message if the transaction has a message. If the message is too long, display only the first 20 characters
          if (transaction.message.isNotEmpty)
            Text(
              '${transaction.message.length > 30 ? transaction.message.substring(0, 30) + '...' : transaction.message}',
              style: TextStyle(color: textColor, fontStyle: FontStyle.italic),
            ),
          // Display the status if the transaction is a request
          if (transaction.transactionType == 'Request')
            Text(
              '${getStatusText(transaction)}',
              style: TextStyle(
                color: getStatusColor(transaction),
              ),
            ),
        ],
      ),
      // Display the date and time of the transaction in the trailing position
      trailing: Text(
        '${DateFormat('dd/MM/yyyy').format(transaction.createdAt)}\n${DateFormat('HH:mm').format(transaction.createdAt)}',
        textAlign: TextAlign.right,
        style: TextStyle(color: textColor),
      ),

      //Add a divider between each transaction. Remove the divider for the last transaction
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey, width: 0.5),
        borderRadius: BorderRadius.circular(0),
      ),

      // Navigate to the transaction details screen when the transaction is tapped
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(
                transaction: transaction, userId: userId),
          ),
        );
      },
    );
  }

  // Function to get the status text for a transaction
  String getStatusText(Transaction transaction) {
    if (transaction.transactionType == 'Request') {
      // For request transactions, display the status
      if (transaction.processed == 1) {
        return 'Processed';
      } else if (transaction.processed == 2) {
        return 'Denied';
      } else {
        return 'Pending';
      }
    } else if (transaction.transactionType == 'Payment') {
      // For money transactions, display the status based on the sender and receiver
      if (transaction.senderId == userId) {
        return 'Sent';
      } else {
        return 'Received';
      }
    }
    // For money transactions, no additional status text needed
    return '';
  }
}

// Function to get the status color for a transaction
Color getStatusColor(Transaction transaction) {
  if (transaction.transactionType == 'Request') {
    // For request transactions, determine the color based on the status (subtle green for processed, subtle red for denied, black for unprocessed)
    if (transaction.processed == 1) {
      return Colors.green;
    } else if (transaction.processed == 2) {
      return Colors.red;
    } else if (transaction.processed == 0) {
      return Colors.orange;
    } else {
      return Colors.black;
    }
  } else {
    // For money transactions, no additional status color needed
    return Colors.black;
  }
}

// TransactionDetailScreen displays detailed information about a transaction
class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;
  final int userId;
  const TransactionDetailScreen(
      {Key? key, required this.transaction, required this.userId})
      : super(key: key);

  // Function to accept a request
  Future<void> acceptRequest(BuildContext context) async {
    // wait for user to confirm the transaction
    final confirmed = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm'),
          content: Text(
              'Are you sure you want to send \n${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}\€ to ${transaction.senderUsername}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
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
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      // Make a request to your backend API to accept the request
      final response = await http.post(
        Uri.parse(
            '${ApiService.serverUrl}/transactions/${transaction.transactionId}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'action': 'accept'}),
      );

      if (response.statusCode == 200) {
        // Request successful, you can update the UI or navigate to a different screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request accepted successfully')),
        );
      } else {
        // Request failed, handle the error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting request')),
        );
      }
    } catch (error) {
      // Handle exceptions
      print('Error accepting request: $error');
    }

    //navigate back to transaction history screen
    Navigator.pop(context);

    //refresh transaction history screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionHistoryScreen(),
      ),
    );
  }

  // Function to deny a request
  Future<void> denyRequest(BuildContext context) async {
    // wait for user to confirm the transaction
    final confirmed = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm'),
          content: Text('Are you sure you want to deny the Request?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
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
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      print('Transaction ID: ${transaction.transactionId}');
      // Make a request to your backend API to deny the request
      final response = await http.post(
        Uri.parse(
            '${ApiService.serverUrl}/transactions/${transaction.transactionId}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'action': 'decline'}),
      );
      print('Response: ${response.body}');
      if (response.statusCode == 200) {
        // Request successful, you can update the UI or navigate to a different screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request denied successfully')),
        );
      } else {
        // Request failed, handle the error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (error) {
      // Handle exceptions
      print('Error denying request: $error');
    }

    //navigate back to transaction history screen
    Navigator.pop(context);

    //refresh transaction history screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionHistoryScreen(),
      ),
    );
  }

  // Build the UI
  @override
  Widget build(BuildContext context) {
    // Determine if the transaction is a received or sent transaction
    bool isReceived = transaction.receiverId == userId;

    //Determine if request is processed or denied or unprocessed
    bool isProcessed = transaction.processed == 1;
    bool isDenied = transaction.processed == 2;
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Details'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the username of the sender or receiver based on the transaction type
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

                // Display the amount of the transaction based on the transaction type and whether the user received or sent money
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

                // Display the amount of the transaction based on the transaction type and whether the user received or sent money
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: transaction.transactionType == 'Request'
                        ? isProcessed
                            ? isReceived
                                ? Colors.red[300]
                                : Colors.green[300]
                            : Colors.transparent
                        : isReceived
                            ? Colors.green[300]
                            : Colors.red[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    transaction.transactionType == 'Request'
                        ? isProcessed
                            ? isReceived
                                ? '-${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}\€'
                                : '+${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}\€'
                            : '${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}\€'
                        : isReceived
                            ? '+${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}\€'
                            : '-${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}\€',
                    style: TextStyle(
                        color: transaction.transactionType == 'Request'
                            ? isProcessed
                                ? isReceived
                                    ? Colors.black
                                    : Colors.black
                                : Colors.black
                            : isReceived
                                ? Colors.black
                                : Colors.black,
                        fontSize: 20),
                  ),
                ),
                SizedBox(height: 10),

                // Display the type of the transaction
                Text(
                  'Type: ${transaction.transactionType}',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),

                // Display the date of the transaction
                Text(
                  'Date: ${DateFormat('dd.MM.yyyy').format(transaction.createdAt)}',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),

                // Display the time of the transaction
                Text(
                  'Time: ${DateFormat('HH:mm:ss').format(transaction.createdAt)}',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),

                // Display the event name if the transaction is associated with an event
                if (transaction.eventId != null)
                  Text('Event: ${transaction.eventId}',
                      style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),

                // Display the message if the transaction has a message
                if (transaction.message.isNotEmpty)
                  Text('Message: ${transaction.message}',
                      style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),

                // Display the status if the transaction is a request
                if (transaction.transactionType == 'Request')
                  Text(
                    'Status: ${getStatusText(transaction)}',
                    style: TextStyle(
                        fontSize: 20,
                        color: getStatusColor(transaction),
                        fontWeight: FontWeight.bold),
                  ),
                SizedBox(height: 10),

                // buttons for accepting and denying the request
                // buttons only appear when the transaction is a request and the transaction is unprocessed and the sender is not the current user
                if (transaction.transactionType == 'Request' &&
                    transaction.processed == 0 &&
                    transaction.senderId != userId)
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
                // Add a link to the event details screen if the transaction is associated with an event and the event is not null (Go to dashboard while event details screen is not implemented)
                if (transaction.eventId != null)
                  Column(
                    children: [
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DashboardScreen()),
                          );
                        },
                        child: Text('View Event Details'),
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

  getStatusText(Transaction transaction) {
    if (transaction.transactionType == 'Request') {
      // For request transactions, display the status
      if (transaction.processed == 1) {
        return 'Processed';
      } else if (transaction.processed == 2) {
        return 'Denied';
      } else {
        return 'Unprocessed';
      }
    } else if (transaction.transactionType == 'Payment') {
      // For money transactions, display the status based on the sender and receiver
      if (transaction.senderId == userId) {
        return 'Sent';
      } else {
        return 'Received';
      }
    }
    // For money transactions, no additional status text needed
    return '';
  }
}
