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
import 'package:flutter_application_1/Screens/Money/TransactionDetailsScreenTEMP.dart';
import 'package:flutter_application_1/Screens/Money/TransactionDetailsScreen.dart';

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
      senderUsername: json['sender_username'] ?? 'deleted User',
      receiverUsername: json['receiver_username'] ?? 'deleted User',
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

// determine the color of the icon and text based on the transaction type and whether the user received or sent money
    transaction.transactionType == 'Request'
        ? isProcessed
            ? isReceived
                ? (iconColor = Colors.red[400]!, textColor = Colors.black)
                : (iconColor = Colors.green[400]!, textColor = Colors.black)
            : isDenied
                ? (iconColor = Colors.grey[400]!, textColor = Colors.black)
                : userIsSender
                    ? (
                        iconColor = Colors.orange[600]!,
                        textColor = Colors.black
                      )
                    : (
                        iconColor = Colors.orange[300]!,
                        textColor = Colors.black
                      )
        : isReceived
            ? (iconColor = Colors.green[400]!, textColor = Colors.black)
            : (iconColor = Colors.red[400]!, textColor = Colors.black);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: Dismissible(
          key: ValueKey<int>(transaction.transactionId),
          background: Container(color: Colors.blue, child: Icon(Icons.edit)),
          secondaryBackground: Container(
            color: Colors.red,
            child: Icon(Icons.delete),
          ), // Customize as needed
          onDismissed: (direction) {
            // show message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${transaction.transactionType == 'Request' ? 'Request' : 'Transaction'} dismissed'),
              ),
            );
          },
          child: Card(
            elevation: 2.0, // Adjust elevation for shadow effect
            child: ListTile(
              onTap: () {
                // Navigate to the transaction details screen when the transaction is tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionDetailsScreen(
                        transaction: transaction,
                        userId: userId,
                        username: username),
                  ),
                );
              },
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              key: ValueKey<int>(transaction.transactionId), // Add a key
              //Add a divider between each transaction. Remove the divider for the last transaction

              // Display the icon based on the transaction type and whether the user received or sent money
              leading: transaction.transactionType == 'Request'
                  ? isProcessed
                      ? isReceived
                          ? Icon(
                              Icons.request_page_outlined,
                              color: iconColor,
                            )
                          : Icon(
                              Icons.request_page_outlined,
                              color: iconColor,
                            )
                      : Icon(
                          Icons.request_page_outlined,
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

              // Display the amount, event name and message in the subtitle position
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  // Display the message if the transaction has a message. If the message is too long, display only the first 30 characters
                  if (transaction.message.isNotEmpty)
                    Text(
                      '${transaction.message.length > 30 ? transaction.message.substring(0, 30) + '...' : transaction.message}',
                      style: TextStyle(
                          color: textColor, fontStyle: FontStyle.italic),
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
            ),
          )

          // Display the transaction details when the transaction is tapped
          ),
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
