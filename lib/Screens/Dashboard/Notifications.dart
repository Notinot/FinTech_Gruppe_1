import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/dashBoardScreen.dart';
import 'package:flutter_application_1/Screens/Money/TransactionHistoryScreen.dart';
import 'package:flutter_application_1/Screens/Money/TransactionDetailsScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class Notifications extends StatelessWidget {
  final Future<Map<String, dynamic>> user = ApiService.fetchUserProfile();
  final Future userid = ApiService.getUserId();

  Future<List<Transaction>> fetchTransactions() async {
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
                  transaction.transactionType != 'Deposit')
              .toList();
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              //     color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  'Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                for (var transaction in transactionsLastSevenDays)
                  NotificationItem(
                    icon: getNotificationIcon(transaction),
                    text: getNotificationText(transaction),
                    transaction: transaction,
                    user: user,
                  ),
              ],
            ),
          );
        }
      },
    );
  }

  String getNotificationText(Transaction transaction) {
    if (transaction.transactionType == 'Payment' &&
        transaction.senderId != userid) {
      return '${transaction.receiverUsername} sent you  ${transaction.amount}€.';
    } else if (transaction.transactionType == 'Payment' &&
        transaction.senderId == userid) {
      return 'Your Payment of ${transaction.amount}€ to ${transaction.receiverUsername} was successful';
    } else if (transaction.transactionType == 'Request' &&
        transaction.senderId != userid) {
      return '${transaction.senderUsername} requested ${transaction.amount}€ from you.';
    } else {
      return 'Unknown notification';
    }
  }

  IconData getNotificationIcon(Transaction transaction) {
    if (transaction.transactionType == 'Request') {
      return Icons.request_page;
    } else if (transaction.transactionType == 'Payment' &&
        transaction.senderId != userid) {
      return Icons.attach_money;
    } else if (transaction.transactionType == 'Payment' &&
        transaction.senderId == userid) {
      return Icons.money_sharp;
    } else {
      return Icons.info_sharp;
    }
  }
}

class NotificationItem extends StatelessWidget {
  final Future<Map<String, dynamic>> user;
  late final String username;
  late final int userId;

  final IconData icon;
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
          userId = userData['user_id'];
          username = userData['username'];

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
                Icon(
                  icon, //color: Colors.blue
                ),
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
