import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Money/TransactionHistoryScreen.dart';
import 'package:flutter_application_1/Screens/Money/TransactionDetailsScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class Notifications extends StatefulWidget {
  @override
  _NotificationsState createState() => _NotificationsState();

  static Future<List<Transaction>> fetchTransactions() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.serverUrl}/transactions'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<dynamic> transactionsData = data[0];
        List<Transaction> transactions =
            transactionsData.map((transactionData) {
          return Transaction.fromJson(transactionData as Map<String, dynamic>);
        }).toList();

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
}

class _NotificationsState extends State<Notifications> {
  final Future<Map<String, dynamic>> user = ApiService.fetchUserProfile();
  int? user_id;

  void initState() {
    super.initState();

    // Use the user Future's result to initialize the controllers
    user.then((userData) {
      setState(() {
        user_id = userData['user_id'];
      });
    });
  }

  static Future<List<Transaction>> fetchTransactions() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.serverUrl}/transactions'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<dynamic> transactionsData = data[0];
        List<Transaction> transactions =
            transactionsData.map((transactionData) {
          return Transaction.fromJson(transactionData as Map<String, dynamic>);
        }).toList();

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
    return FutureBuilder<List<Transaction>>(
      future: fetchTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No transactions found.'));
        } else {
          final List<Transaction> transactions = snapshot.data!;

          final DateTime now = DateTime.now();
          final DateTime startOfLastSevenDays = now.subtract(Duration(days: 6));
          final DateTime endOfToday = now.add(Duration(days: 1));

          final List<Transaction> transactionsLastSevenDays = transactions
              .where((transaction) =>
                      transaction.createdAt.isAfter(startOfLastSevenDays) &&
                      transaction.createdAt.isBefore(endOfToday) &&
                      transaction.transactionType != 'Deposit'
                  /* && !(transaction.processed == 1 &&
                      transaction.transactionType == 'Request')*/
                  )
              .toList();

          return SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  if (transactionsLastSevenDays.length > 6)
                    LimitedBox(
                      maxHeight: 100, // Adjust the height as needed
                      child: ListView.builder(
                        itemCount: transactionsLastSevenDays.length,
                        itemBuilder: (context, index) {
                          final transaction = transactionsLastSevenDays[index];
                          return NotificationItem(
                            icon: getNotificationIcon(transaction),
                            text: getNotificationText(transaction),
                            transaction: transaction,
                            user: user,
                          );
                        },
                      ),
                    )
                  else
                    for (var transaction in transactionsLastSevenDays)
                      NotificationItem(
                        icon: getNotificationIcon(transaction),
                        text: getNotificationText(transaction),
                        transaction: transaction,
                        user: user,
                      ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  String getNotificationText(Transaction transaction) {
    if (transaction.transactionType == 'Payment' &&
        transaction.receiverId == user_id) {
      return 'Received ${transaction.amount}€ from ${transaction.senderUsername}';
    } else if ((transaction.transactionType == 'Payment' &&
            transaction.senderId == user_id) ||
        (transaction.transactionType == 'Request' &&
            transaction.receiverId == user_id &&
            transaction.processed == 1)) {
      return 'Sent ${transaction.amount}€ to ${transaction.receiverUsername}';
    } else if (transaction.transactionType == 'Request' &&
        transaction.senderId != user_id &&
        transaction.processed == 0) {
      return '${transaction.senderUsername} requested ${transaction.amount}€ from you.';
    } else if (transaction.transactionType == 'Request' &&
        transaction.senderId == user_id &&
        transaction.processed == 0) {
      return 'You requested ${transaction.amount}€ from ${transaction.receiverUsername}.';
    } else if (transaction.transactionType == 'Request' &&
        transaction.senderId == user_id &&
        transaction.processed == 1) {
      return '${transaction.receiverUsername} accepted your request and sent ${transaction.amount}€';
    } else if (transaction.transactionType == 'Request' &&
        transaction.senderId == user_id &&
        transaction.processed == 2) {
      return '${transaction.receiverUsername} rejected your request';
    } else if (transaction.transactionType == 'Request' &&
        transaction.receiverId == user_id &&
        transaction.processed == 2) {
      return 'You rejected the request from ${transaction.senderUsername}';
    } else {
      return 'Unknown notification';
    }
  }

  Icon getNotificationIcon(Transaction transaction) {
    if (transaction.transactionType == 'Request' &&
        transaction.processed == 0) {
      return Icon(Icons.request_page, color: Colors.orange);
    } else if (transaction.transactionType == 'Request' &&
        transaction.senderId == user_id &&
        transaction.processed == 1) {
      return Icon(Icons.request_page, color: Colors.green);
    } else if (transaction.transactionType == 'Request' &&
        transaction.receiverId == user_id &&
        transaction.processed == 1) {
      return Icon(Icons.request_page, color: Colors.red);
    } else if (transaction.transactionType == 'Request' &&
        transaction.senderId == user_id &&
        transaction.processed == 1) {
      return Icon(Icons.request_page, color: Colors.red);
    } else if (transaction.transactionType == 'Request' &&
        transaction.senderId == user_id &&
        transaction.processed == 2) {
      return Icon(Icons.request_page, color: Colors.black);
    } else if (transaction.transactionType == 'Payment' &&
        transaction.receiverId == user_id) {
      return Icon(Icons.attach_money, color: Colors.green);
    } else if (transaction.transactionType == 'Request' &&
        transaction.receiverId == user_id &&
        transaction.processed == 2) {
      return Icon(Icons.request_page, color: Colors.black);
    } else if (transaction.transactionType == 'Payment' &&
        transaction.senderId == user_id) {
      return Icon(Icons.attach_money, color: Colors.red);
    } else {
      return Icon(Icons.info_sharp);
    }
  }
}

class NotificationItem extends StatelessWidget {
  final Future<Map<String, dynamic>> user;
  final Icon icon;
  final String text;
  final Transaction transaction;

  NotificationItem({
    Key? key,
    required this.icon,
    required this.text,
    required this.transaction,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else {
          final userData = snapshot.data!;
          final userId = userData['user_id'];
          final username = userData['username'];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionDetailsScreen(
                    transaction: transaction,
                    userId: userId,
                    username: username,
                  ),
                ),
              );
            },
            child: Row(
              children: <Widget>[
                icon,
                const SizedBox(width: 8),
                Text(text),
              ],
            ),
          );
        }
      },
    );
  }
}
