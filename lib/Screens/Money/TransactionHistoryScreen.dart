import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/appDrawer.dart';
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
  List<Transaction> originalTransactions = [];

  bool isSearchMode = false;
  final TextEditingController searchController = TextEditingController();

  late Future<List<Transaction>> transactionsFuture;
  late search_bar.SearchBar searchBar;
  String currentSortOrder = 'Date (↓)'; // Default sort order
  List<String> sortOptions = [
    'Date (↑)',
    'Date (↓)',
    'Amount (↑)',
    'Amount (↓)',
    // 'User (A-Z)',
    // 'User (Z-A)',
    'Requests',
    'Payments',
    'Deposits',
    'Event',
  ];
  List<String> sortOptions2 = [
    'Requests',
    'Payments',
    'Deposits',
  ];

  List<Transaction> allTransactions = [];

  @override
  void initState() {
    super.initState();
    transactionsFuture = fetchTransactions().then((transactions) {
      originalTransactions =
          List.from(transactions); // Store the original transactions
      return transactions;
    });
    // searchBar = search_bar.SearchBar(
    //   showClearButton: true,
    //   closeOnSubmit: false,
    //   clearOnSubmit: false,
    //   inBar: true,
    //   setState: setState,
    //   onSubmitted: onSubmitted,
    //   onChanged: onChanged,
    //   onCleared: onCleared,
    //   onClosed: onClosed,
    //   buildDefaultAppBar: buildAppBar,
    //   hintText: "Search by username, message, type",
    // );
  }

  // Function to sort transactions
  void sortTransactions(String sortOrder) {
    //reset the transactions list to the original list
    allTransactions = List.from(originalTransactions);

    // Sort the transactions based on the sort order
    if (sortOrder == 'Date (↑)') {
      originalTransactions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      allTransactions = originalTransactions;
    } else if (sortOrder == 'Date (↓)') {
      originalTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      allTransactions = originalTransactions;
    } else if (sortOrder == 'Amount (↑)') {
      originalTransactions.sort((a, b) => a.amount.compareTo(b.amount));
      allTransactions = originalTransactions;
    } else if (sortOrder == 'Amount (↓)') {
      originalTransactions.sort((a, b) => b.amount.compareTo(a.amount));
      allTransactions = originalTransactions;
    } else if (sortOrder == 'Requests') {
      allTransactions = allTransactions
          .where((transaction) => transaction.transactionType == 'Request')
          .toList();
    } else if (sortOrder == 'Payments') {
      allTransactions = originalTransactions
          .where((transaction) => transaction.transactionType == 'Payment')
          .toList();
    } else if (sortOrder == 'Deposits') {
      allTransactions = originalTransactions
          .where((transaction) => transaction.transactionType == 'Deposit')
          .toList();
    } else if (sortOrder == 'Event') {
      allTransactions = originalTransactions
          .where((transaction) => transaction.eventId != null)
          .toList();
    }

    // Update the Future to reflect the new sorted list
    transactionsFuture = Future.value(allTransactions);
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
      title: isSearchMode
          ? TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Search transactions...",
                border: InputBorder.none,
              ),
              onChanged: onSearchTextChanged,
            )
          : Text(' History'),
      actions: isSearchMode
          ? [
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    isSearchMode = false;
                    searchController.clear();
                    onSearchTextChanged('');
                  });
                },
              ),
              // DropdownButton<String>(
              //   value: currentSortOrder,
              //   // icon: Icon(Icons.sort),
              //   onChanged: (String? newValue) {
              //     if (newValue != null) {
              //       setState(() {
              //         currentSortOrder = newValue;
              //         sortTransactions(currentSortOrder);
              //       });
              //     }
              //   },
              //   items:
              //       sortOptions.map<DropdownMenuItem<String>>((String value) {
              //     return DropdownMenuItem<String>(
              //       value: value,
              //       child: Text(value),
              //       onTap: () {
              //         setState(() {
              //           currentSortOrder = value;
              //           sortTransactions(currentSortOrder);
              //         });
              //       },
              //     );
              //   }).toList(),
              // ),
            ]
          : [
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    isSearchMode = true;
                    currentSortOrder = 'Date (↓)';
                  });
                },
              ),
              DropdownButton<String>(
                value: currentSortOrder,
                icon: Icon(Icons.sort),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      currentSortOrder = newValue;
                      sortTransactions(currentSortOrder);
                    });
                  }
                },
                items:
                    sortOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                    onTap: () {
                      setState(() {
                        currentSortOrder = value;
                        sortTransactions(currentSortOrder);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
    );
  }

  void onSearchTextChanged(String query) {
    List<Transaction> filteredTransactions = [];
    if (query.isEmpty) {
      filteredTransactions = originalTransactions;
    } else {
      filteredTransactions = originalTransactions.where((transaction) {
        return transaction.senderUsername
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            transaction.receiverUsername
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            transaction.message.toLowerCase().contains(query.toLowerCase()) ||
            transaction.transactionType
                .toLowerCase()
                .contains(query.toLowerCase());
      }).toList();
    }
    setState(() {
      transactionsFuture = Future.value(filteredTransactions);
    });
  }

  // Future<void> onSubmitted(String value) async {
  //   // Apply the filter only if the user has entered a search query
  //   if (value.isNotEmpty) {
  //     List<Transaction> filteredTransactions = allTransactions
  //         .where((transaction) =>
  //             transaction.transactionType
  //                 .toLowerCase()
  //                 .contains(value.toLowerCase()) ||
  //             transaction.senderUsername
  //                 .toLowerCase()
  //                 .contains(value.toLowerCase()) ||
  //             transaction.message.toLowerCase().contains(value.toLowerCase()) ||
  //             transaction.receiverUsername
  //                 .toLowerCase()
  //                 .contains(value.toLowerCase()))
  //         .toList();
  //     setState(() {
  //       transactionsFuture = Future.value(filteredTransactions);
  //     });
  //   } else {
  //     setState(() {
  //       transactionsFuture = fetchTransactions();
  //     });
  //   }
  // }

  // Future<void> onChanged(String value) async {
  //   if (value.isNotEmpty) {
  //     List<Transaction> filteredTransactions = originalTransactions
  //         .where((transaction) =>
  //             transaction.transactionType
  //                 .toLowerCase()
  //                 .contains(value.toLowerCase()) ||
  //             transaction.senderUsername
  //                 .toLowerCase()
  //                 .contains(value.toLowerCase()) ||
  //             transaction.message.toLowerCase().contains(value.toLowerCase()) ||
  //             transaction.receiverUsername
  //                 .toLowerCase()
  //                 .contains(value.toLowerCase()))
  //         .toList();
  //     setState(() {
  //       transactionsFuture = Future.value(filteredTransactions);
  //     });
  //   } else {
  //     setState(() {
  //       transactionsFuture = Future.value(List.from(originalTransactions));
  //     });
  //   }
  // }

  // Future<void> onCleared() async {
  //   // Handle search bar cleared
  //   // Update the UI to show the original list without filtering
  //   setState(() {
  //     transactionsFuture = fetchTransactions();
  //   });
  // }

  // Future<void> onClosed() async {
  //   //update the UI to show the original list without filtering
  //   setState(() {
  //     transactionsFuture = fetchTransactions();
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: searchBar.build(context),
      appBar: buildAppBar(context),
      drawer: FutureBuilder<Map<String, dynamic>>(
        // Fetch user profile data for the drawer
        future: ApiService.fetchUserProfile(),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            transactionsFuture = fetchTransactions();
            currentSortOrder = 'Date (↓)';
          });
        },
        child: const Icon(Icons.refresh),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        // Fetch user profile data for the main body
        future: ApiService.fetchUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
      bottomNavigationBar: BottomAppBar(
        // Your existing bottom navigation bar code
        child: FutureBuilder<Map<String, dynamic>>(
          // Fetch user profile data for the bottom navigation bar
          future: ApiService.fetchUserProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final Map<String, dynamic> user = snapshot.data!;
              return Container(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(Icons.euro), // Display the user's balance
                    Text(
                      '${NumberFormat("#,##0.00", "de_DE").format(user['balance'])}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SendMoneyScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.monetization_on),
                      label: Text('Send'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RequestMoneyScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.request_page),
                      label: Text('Request'),
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

  /*@override
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

      body: FutureBuilder<Map<String, dynamic>>(
        // Fetch user profile data
        future: ApiService.fetchUserProfile(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
        child: FutureBuilder<Map<String, dynamic>>(
          // Fetch user profile data
          future: ApiService.fetchUserProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final Map<String, dynamic> user = snapshot.data!;
              return Container(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(Icons.euro), // Display the user's balance
                    Text(
                      '${NumberFormat("#,##0.00", "de_DE").format(user['balance'])}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    // Button to navigate to the send money screen with icon and text
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
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
                      icon: Icon(Icons.monetization_on),
                      label: Text('Send'),
                    ),
                    // Button to navigate to the request money screen with icon on left and text "Request" on right
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
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
                      icon: Icon(Icons.request_page),
                      label: Text('Request'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }*/
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
    Color? iconColor;
    Color? textColor;

// determine the color of the icon and text based on the transaction type and whether the user received or sent money
    transaction.transactionType == 'Request'
        ? isProcessed
            ? isReceived
                ? (iconColor = Colors.red, textColor = null)
                : (iconColor = Colors.green, textColor = null)
            : isDenied
                ? (iconColor = null, textColor = null)
                : userIsSender
                    ? (
                        iconColor = Colors.orange,
                        textColor = null,
                      )
                    : (
                        iconColor = Colors.orange,
                        textColor = null,
                      )
        : isReceived
            ? (iconColor = Colors.green, textColor = null)
            : (iconColor = Colors.red, textColor = null);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
      child: Hero(
        tag:
            'transaction_${transaction.transactionId}', // Unique tag for Hero transition
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
                      // color: transaction.transactionType == 'Request'
                      //     ? isProcessed
                      //         ? isReceived
                      //             ? Colors.red[300]
                      //             : Colors.green[300]
                      //         : isReceived
                      //             ? isDenied
                      //                 ? null
                      //                 : Colors.orange[200]
                      //             : isDenied
                      //                 ? null
                      //                 : Colors.orange[200]
                      //     : isReceived
                      //         ? Colors.green[300]
                      //         : Colors.red[300],
                      // borderRadius: BorderRadius.circular(5),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Display the event name if the transaction is associated with an event
                if (transaction.eventId != null)
                  Row(
                    children: [
                      Icon(Icons.event_rounded, size: 20),
                      SizedBox(width: 2),
                      Text(
                        '${transaction.message}',
                      ),
                    ],
                  ),
                // Display the message if the transaction has a message. If the message is too long, display only the first 30 characters
                if (transaction.message.isNotEmpty &&
                    transaction.eventId == null)
                  Text(
                    '${transaction.message.length > 30 ? transaction.message.substring(0, 30) + '...' : transaction.message}',
                    style: TextStyle(
                        color: textColor, fontStyle: FontStyle.italic),
                  ),
              ],
            ),

            // add one hour to the transaction time to adjust for timezone
            // Display the date and time of the transaction in the trailing position
            trailing: Text(
              '${DateFormat('dd/MM/yyyy').format(transaction.createdAt)}\n${DateFormat('HH:mm').format(transaction.createdAt.add(Duration(hours: 1)))}',
              textAlign: TextAlign.right,
              style: TextStyle(color: textColor),
            ),
          ),
        ),
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
    // For request transactions, determine the color based on the status (subtle green for processed, subtle red for denied, no change for unprocessed)
    if (transaction.processed == 1) {
      return Colors.green;
    } else if (transaction.processed == 2) {
      return Colors.red;
    } else if (transaction.processed == 0) {
      return Colors.orange;
    } else {
      return null as Color;
    }
  } else {
    // For money transactions, no additional status color needed
    return null as Color;
  }
}
