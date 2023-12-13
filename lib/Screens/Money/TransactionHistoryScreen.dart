import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/dashBoardScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_search_bar/flutter_search_bar.dart' as search_bar;
import 'RequestMoneyScreen.dart';
import 'SendMoneyScreen.dart';
import 'package:flutter_application_1/Screens/Money/quickMenuTransaction.dart';

import 'package:flutter_application_1/Screens/Dashboard/quickActionsMenu.dart';
import 'package:flutter_application_1/Screens/Money/TransactionHistoryScreen.dart';
import 'package:flutter_application_1/Screens/Friends/FriendsScreen.dart';

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
      showClearButton: false,
      inBar: true,
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
      appBar: searchBar.build(context),
      //floating action button to refresh the transaction history screen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            transactionsFuture = fetchTransactions();
          });
        },
        child: const Icon(Icons.refresh),
      ),
      //navigation bar at the bottom of the screen to navigate to the send money and request money screens respectively
      /* bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on),
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
      */
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
                        username: user['username'],
                      );
                    },
                  );
                }
              },
            );
          }
        },
      ),
      // Bottom navigation bar
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue[400],
        child: FutureBuilder<Map<String, dynamic>>(
          // Fetch user profile data
          future: ApiService.fetchUserProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final Map<String, dynamic> user = snapshot.data!;
              return Container(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Display the user's balance
                    Text(
                      'Balance: ${NumberFormat("#,##0.00", "de_DE").format(user['balance'])}\€',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    // Button to navigate to the send money screen
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          textStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          )),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SendMoneyScreen(),
                          ),
                        );
                      },
                      child: Icon(Icons.monetization_on_rounded),
                    ),
                    // Button to navigate to the request money screen
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          textStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          )),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RequestMoneyScreen(),
                          ),
                        );
                      },
                      child: Icon(Icons.request_page_rounded),
                    ),
                  ],
                ),
              );
            }
          },
        ),
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
  final String username;
  const TransactionItem({
    Key? key,
    required this.transaction,
    required this.userId,
    required this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine if the transaction is a received or sent transaction
    bool isReceived = transaction.receiverId == userId;
    bool isDeposit = transaction.transactionType == 'Deposit';
    bool userIsSender = transaction.senderId == userId;
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
        iconColor = Colors.grey[400]!;
        textColor = Colors.black;
      } else if (userIsSender) {
        iconColor = Colors.orange[600]!;
        textColor = Colors.black;
      } else {
        iconColor = Colors.orange[300]!;
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

      // if deposit, change color to green
    }

    return ListTile(
      key: ValueKey<int>(transaction.transactionId), // Add a key

      // Display the icon based on the transaction type. Use a red icon for requests and a green icon for money transactions and a differenct green icon for deposits
      leading: transaction.transactionType == 'Request'
          ? isProcessed
              ? isReceived
                  ? Icon(
                      Icons.request_page_rounded,
                      color: iconColor,
                    )
                  : Icon(
                      Icons.request_page_rounded,
                      color: iconColor,
                    )
              : Icon(
                  Icons.request_page_rounded,
                  color: iconColor,
                )
          : isDeposit
              ? Icon(
                  Icons.add,
                  color: Colors.green[400],
                )
              : isReceived
                  ? Icon(
                      Icons.monetization_on_rounded,
                      color: iconColor,
                    )
                  : Icon(
                      Icons.monetization_on_rounded,
                      color: iconColor,
                    ),

      // Display the username of the sender or receiver based on the transaction type.
      // if it is a request, display the sender username if the user received money and the receiver username if the user sent money.
      // if it is a money transaction, display the sender username if the user received money and the receiver username if the user sent money.
      //if it is a deposit, display nothing in the title
      // use userisSender to determine if the user is the sender of the transaction or request
      title: transaction.transactionType == 'Request'
          ? isProcessed
              ? isReceived
                  ? Text(
                      '${transaction.senderUsername}',
                      style: TextStyle(color: textColor),
                    )
                  : Text(
                      '${transaction.receiverUsername}',
                      style: TextStyle(color: textColor),
                    )
              : userIsSender
                  ? Text(
                      '${transaction.receiverUsername}',
                      //'To: ${transaction.receiverUsername}', // Display receiver's username if the user is the sender
                      style: TextStyle(color: textColor),
                    )
                  : Text(
                      '${transaction.senderUsername}', // Display sender's username if the user is the receiver
                      // 'From: ${transaction.senderUsername}',
                      style: TextStyle(color: textColor),
                    )
          : isDeposit
              ? Text(
                  'Deposit',
                  style: TextStyle(color: textColor),
                )
              : isReceived
                  ? Text(
                      '${transaction.senderUsername}',
                      style: TextStyle(color: textColor),
                    )
                  : Text(
                      '${transaction.receiverUsername}',
                      style: TextStyle(color: textColor),
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
                      : isReceived
                          ? isDenied
                              ? Colors.grey[300]
                              : Colors.orange[300]
                          : isDenied
                              ? Colors.grey[300]
                              : Colors.orange[300]
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
                      : isReceived
                          ? '-${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}\€'
                          : '+${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}\€'
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
                transaction: transaction, userId: userId, username: username),
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
  final String username;
  const TransactionDetailScreen(
      {Key? key,
      required this.transaction,
      required this.userId,
      required this.username})
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
    bool isReceived = transaction.receiverId == userId;
    bool userIsSender = transaction.senderId == userId;
    bool userIsReceiver = transaction.receiverId == userId;
    bool isProcessed = transaction.processed == 1;
    bool isDenied = transaction.processed == 2;

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Details'),
        backgroundColor: Colors.blue,
      ),

      // Display the transaction details
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 20,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the date of the transaction
                Text(
                  '${DateFormat('dd.MM.yyyy').format(transaction.createdAt)}',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),

                // Display the time of the transaction
                Text(
                  '${DateFormat('HH:mm').format(transaction.createdAt)}',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),

                // Display the type of the transaction, unless it is a deposit
                transaction.transactionType != 'Deposit'
                    ? Text(
                        'Type: ${transaction.transactionType}',
                        style: TextStyle(fontSize: 20),
                      )
                    : SizedBox(height: 0),
                SizedBox(height: 10),

                // Display the username of the sender or receiver based on the transaction type.
                // if it is a request, display the sender username if the user received money and the receiver username if the user sent money.
                // if it is a money transaction, display the sender username if the user received money and the receiver username if the user sent money.
                //if it is a deposit, display nothing in the title

                GestureDetector(
                  onTap: () =>
                      //check if the actively displayed username is the logged in user. if so, dont show the modal
                      transaction.transactionType == 'Request'
                          ? isProcessed
                              ? isReceived
                                  ? transaction.senderUsername == username
                                      ? null
                                      : _showUserOptions(
                                          context, transaction.senderUsername)
                                  : transaction.receiverUsername == username
                                      ? null
                                      : _showUserOptions(
                                          context, transaction.receiverUsername)
                              : userIsSender
                                  //Request is unprocessed and user is sender
                                  ? transaction.senderUsername == username
                                      ? null
                                      : _showUserOptions(
                                          context, transaction.receiverUsername)
                                  : transaction.senderUsername == username
                                      ? null
                                      : _showUserOptions(
                                          context, transaction.receiverUsername)
                          : isReceived
                              ? transaction.senderUsername == username
                                  ? null
                                  : _showUserOptions(
                                      context, transaction.senderUsername)
                              : transaction.receiverUsername == username
                                  ? null
                                  : _showUserOptions(
                                      context, transaction.receiverUsername),
                  child: transaction.transactionType == 'Request'
                      ? isProcessed
                          ? isReceived
                              ? Text(
                                  'Sender: ${transaction.senderUsername}',
                                  style: TextStyle(fontSize: 20),
                                )
                              : Text(
                                  'Receiver: ${transaction.receiverUsername}',
                                  style: TextStyle(fontSize: 20),
                                )
                          : Text(
                              'Sender: ${transaction.senderUsername}',
                              style: TextStyle(fontSize: 20),
                            )
                      : transaction.transactionType == 'Deposit'
                          ? SizedBox(height: 0)
                          : isReceived
                              ? Text(
                                  'Sender: ${transaction.senderUsername}',
                                  style: TextStyle(fontSize: 20),
                                )
                              : Text(
                                  'Receiver: ${transaction.receiverUsername}',
                                  style: TextStyle(fontSize: 20),
                                ),
                ),
                //If deposit, display "Deposit" instead of sender and receiver
                transaction.transactionType == 'Deposit'
                    ? Text(
                        'Deposit',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      )
                    : SizedBox(height: 0),
                SizedBox(height: 10),
                // Making usernames interactive

                // Display the amount of the transaction based on the transaction type and whether the user received or sent money
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: transaction.transactionType == 'Request'
                        ? isProcessed
                            ? isReceived
                                ? Colors.red[300]
                                : Colors.green[300]
                            : isReceived
                                ? isDenied
                                    ? Colors.grey[300]
                                    : Colors.orange[300]
                                : isDenied
                                    ? Colors.grey[300]
                                    : Colors.orange[300]
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
                            : isReceived
                                ? '-${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}\€'
                                : '+${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}\€'
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

                // Display the event name if the transaction is associated with an event
                if (transaction.eventId != null)
                  TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Event',
                      hintText: '${transaction.eventId}',
                    ),
                    readOnly: true,
                  ),

                // Display the message if the transaction has a message
                if (transaction.message.isNotEmpty)
                  Text.rich(TextSpan(children: [
                    TextSpan(
                      text: 'Message: ',
                      style: TextStyle(fontSize: 20),
                    ),
                    TextSpan(
                      text: '${transaction.message}',
                      style:
                          TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
                    ),
                  ])),
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
                        style: ElevatedButton.styleFrom(
                            primary: Colors.green[400],
                            textStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            )),
                        onPressed: () => acceptRequest(context),
                        child: Text('Accept'),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: Colors.red[400],
                            textStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            )),
                        onPressed: () => denyRequest(context),
                        child: Text('Deny'),
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
                // Additional UI elements for user interactions (sending money, requests, adding as friend)
                //_buildUserOptionsModal(context),
              ],
            ),
          ),
        ),
        //Floating action button quickMenuTransaction
      ),
      //Display bottom appbar for sending money, requesting money and adding as a friend. dont show the balance
      //adding as a friend only appears when the current user and the user displayed in the transaction details screen are not friends
      //Bottom appbar
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue[400],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Display the user's balance
            // Text(
            //   'Balance: ${NumberFormat("#,##0.00", "de_DE").format(user['balance'])}\€',
            //   style: TextStyle(
            //     fontWeight: FontWeight.bold,
            //     fontSize: 20,
            //     color: Colors.white,
            //   ),
            // ),
            // Button to navigate to the send money screen
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  )),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SendMoneyScreen(),
                  ),
                );
              },
              child: Icon(Icons.monetization_on_rounded),
            ),
            // Button to navigate to the request money screen
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  )),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RequestMoneyScreen(),
                  ),
                );
              },
              child: Icon(Icons.request_page_rounded),
            ),
            // Button to add as a friend
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  )),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FriendsScreen(),
                  ),
                );
              },
              child: Icon(Icons.person_add),
            ),
          ],
        ),
      ),
      //Display floating action button  quickMenuTransaction, with the same conditions as the GestureDetector above
      floatingActionButton: transaction.transactionType == 'Request'
          ? isProcessed
              ? isReceived
                  ? transaction.senderUsername == username
                      ? null
                      : FloatingActionButton(
                          onPressed: () => _showUserOptions(
                              context, transaction.senderUsername),
                          child: Icon(Icons.more_vert),
                        )
                  : transaction.receiverUsername == username
                      ? null
                      : FloatingActionButton(
                          onPressed: () => _showUserOptions(
                              context, transaction.receiverUsername),
                          child: Icon(Icons.more_vert),
                        )
              : userIsSender
                  //Request is unprocessed and user is sender
                  ? transaction.senderUsername == username
                      ? null
                      : FloatingActionButton(
                          onPressed: () => _showUserOptions(
                              context, transaction.receiverUsername),
                          child: Icon(Icons.more_vert),
                        )
                  : transaction.senderUsername == username
                      ? null
                      : FloatingActionButton(
                          onPressed: () => _showUserOptions(
                              context, transaction.receiverUsername),
                          child: Icon(Icons.more_vert),
                        )
          : isReceived
              ? transaction.senderUsername == username
                  ? null
                  : FloatingActionButton(
                      onPressed: () =>
                          _showUserOptions(context, transaction.senderUsername),
                      child: Icon(Icons.more_vert),
                    )
              : transaction.receiverUsername == username
                  ? null
                  : FloatingActionButton(
                      onPressed: () => _showUserOptions(
                          context, transaction.receiverUsername),
                      child: Icon(Icons.more_vert),
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

  getStatusColor(Transaction transaction) {
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

  void _showUserOptions(BuildContext context, String username) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 200,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.person_add),
                title: Text('Add as Friend'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.monetization_on_rounded),
                title: Text('Send Money'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SendMoneyScreen(
                        recipient: username,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.request_page_rounded),
                title: Text('Request Money'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestMoneyScreen(
                        requester: username,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserOptionsModal(BuildContext context) {
    // Placeholder for modal or dropdown UI
    return Container();
  }
}
