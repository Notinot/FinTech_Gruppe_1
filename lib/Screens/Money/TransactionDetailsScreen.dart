// TransactionDetailScreen displays detailed information about a transaction
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/dashBoardScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'RequestMoneyScreen.dart';
import 'SendMoneyScreen.dart';
import 'package:flutter_application_1/Screens/Money/TransactionHistoryScreen.dart';
import 'package:flutter_application_1/Screens/Friends/FriendsScreen.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final Transaction transaction;
  final int userId;
  final String username;
  const TransactionDetailsScreen(
      {Key? key,
      required this.transaction,
      required this.userId,
      required this.username})
      : super(key: key);

  // Build the UI
  @override
  Widget build(BuildContext context) {
    bool isReceived = transaction.receiverId == userId;
    bool userIsSender = transaction.senderId == userId;
    bool userIsReceiver = transaction.receiverId == userId;
    bool isProcessed = transaction.processed == 1;
    bool isDenied = transaction.processed == 2;
    int friendId = 0;
    String friendUsername = '';

    //get friendId and friendUsername based on transaction type and whether the user received or sent money
    transaction.transactionType == 'Request'
        ? isProcessed
            ? isReceived
                ? friendId = transaction.senderId
                : friendId = transaction.receiverId
            : userIsSender
                ? friendId = transaction.receiverId
                : friendId = transaction.senderId
        : transaction.transactionType == 'Payment'
            ? isReceived
                ? friendId = transaction.senderId
                : friendId = transaction.receiverId
            : transaction.transactionType == 'Deposit'
                ? SizedBox(height: 10)
                : SizedBox(height: 10);

    transaction.transactionType == 'Request'
        ? isProcessed
            ? isReceived
                ? friendUsername = transaction.senderUsername
                : friendUsername = transaction.receiverUsername
            : userIsSender
                ? friendUsername = transaction.receiverUsername
                : friendUsername = transaction.senderUsername
        : transaction.transactionType == 'Payment'
            ? isReceived
                ? friendUsername = transaction.senderUsername
                : friendUsername = transaction.receiverUsername
            : transaction.transactionType == 'Deposit'
                ? friendUsername = ''
                : SizedBox(height: 10);
    //check if the user is already a friend

    //check if the user is already a friend
    return FutureBuilder<bool>(
        future: ApiService.checkIfFriends(friendId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show loading indicator while fetching data
            return CircularProgressIndicator(
              value: 0.5,
            );
          } else if (snapshot.hasError) {
            // Handle errors
            return Text('Error: ${snapshot.error}');
          } else {
            // Once data is loaded, display the Transaction Details
            final bool isFriend = snapshot.data!;

            return Scaffold(
              appBar: AppBar(
                title: Text('Transaction Details'),
              ),

              // Display the transaction details
              body: Padding(
                padding: const EdgeInsets.all(5),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display the date of the transaction with icon
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded),
                            SizedBox(width: 10),
                            Text(
                              '${DateFormat('dd.MM.yyyy').format(transaction.createdAt)}',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),

                        // Display the time of the transaction
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded),
                            SizedBox(width: 10),
                            Text(
                              '${DateFormat('HH:mm').format(transaction.createdAt)}',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),

                        // Display the type of the transaction
                        Row(
                          children: [
                            Icon(Icons.money_rounded),
                            SizedBox(width: 10),
                            Text(
                              '${transaction.transactionType}',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),

                        // Display the username of the sender or receiver based on the transaction type and whether the user received or sent money
                        Container(
                          child: transaction.transactionType == 'Request'
                              ? isProcessed
                                  ? isReceived
                                      ? Row(
                                          children: [
                                            Icon(Icons.person_rounded),
                                            SizedBox(width: 10),
                                            Text(
                                              '${transaction.senderUsername}',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Icon(Icons.person_rounded),
                                            SizedBox(width: 10),
                                            Text(
                                              '${transaction.receiverUsername}',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          ],
                                        )
                                  : userIsSender
                                      ? Row(
                                          children: [
                                            Icon(Icons.person_rounded),
                                            SizedBox(width: 10),
                                            Text(
                                              '${transaction.receiverUsername}',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Icon(Icons.person_rounded),
                                            SizedBox(width: 10),
                                            Text(
                                              '${transaction.senderUsername}',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          ],
                                        )
                              : transaction.transactionType == 'Deposit'
                                  ? SizedBox(height: 10)
                                  : isReceived
                                      ? Row(
                                          children: [
                                            Icon(Icons.person_rounded),
                                            SizedBox(width: 10),
                                            Text(
                                              '${transaction.senderUsername}',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Icon(Icons.person_rounded),
                                            SizedBox(width: 10),
                                            Text(
                                              '${transaction.receiverUsername}',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          ],
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
                          child: Row(
                            children: [
                              Icon(Icons.euro_rounded),
                              SizedBox(width: 10),
                              Text(
                                transaction.transactionType == 'Request'
                                    ? isProcessed
                                        ? isReceived
                                            ? '-${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}'
                                            : '+${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}'
                                        : isReceived
                                            ? '-${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}'
                                            : '+${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}'
                                    : isReceived
                                        ? '+${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}'
                                        : '-${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)}',
                                style: TextStyle(
                                    color:
                                        transaction.transactionType == 'Request'
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
                            ],
                          ),
                        ),
                        SizedBox(height: 10),

                        // Display the status if the transaction is a request
                        if (transaction.transactionType == 'Request')
                          Row(
                            children: [
                              Icon(Icons.info_rounded),
                              SizedBox(width: 10),
                              Text(
                                '${getStatusText(transaction)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: getStatusColor(transaction),
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: 10),
// Display the message if the transaction has a message
                        if (transaction.message.isEmpty == false)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.message_rounded),
                              SizedBox(width: 10),
                              Text(
                                '${transaction.message}',
                                style: TextStyle(fontSize: 20),
                              ),
                            ],
                          ),

                        SizedBox(height: 10),
                        // Display the event name if the transaction is associated with an event
                        if (transaction.eventId != null)
                          Row(
                            children: [
                              Icon(Icons.event_rounded),
                              SizedBox(width: 10),
                              Text(
                                'Event:" transaction.eventName"',
                                style: TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        SizedBox(height: 10),
                        // buttons for accepting and denying the request
                        // buttons only appear when the transaction is a request and the transaction is unprocessed and the sender is not the current user
                        if (transaction.transactionType == 'Request' &&
                            transaction.processed == 0 &&
                            transaction.senderId != userId)
                          Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    primary: Colors.green[300],
                                    textStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    )),
                                onPressed: () => acceptRequest(context),
                                child: Text('Accept Request'),
                              ),
                              SizedBox(width: 20),
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      primary: Colors.red[300],
                                      textStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      )),
                                  onPressed: () => denyRequest(context),
                                  child: Text('Deny Request')),
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
                                        builder: (context) =>
                                            DashboardScreen()),
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

              floatingActionButton: friendUsername != ''
                  ? FloatingActionButton(
                      onPressed: () {
                        _showUserOptions(
                            context, isFriend, friendUsername, friendId);
                      },
                      child: Icon(Icons.more_horiz_rounded),
                    )
                  : SizedBox(height: 10),
            );
          }
        });
  }

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

  void _showUserOptionss(BuildContext context, String username) {
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

  void _showUserOptions(
      BuildContext context, isFriend, String friendUsername, int friendId) {
    //show modal bottom sheet with different options if the user is already a friend
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 200,
          child: Column(
            children: [
              if (isFriend == false)
                ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('Add as Friend'),
                  onTap: () async {
                    if (await ApiService.addUser(friendId)) {
                      showErrorSnackBar(
                          context, 'Error adding friend, please try again');
                    } else {
                      showSuccessSnackBar(
                          context, 'Friend request sent successfully');
                      //close modal bottom sheet
                      Navigator.pop(context);
                    }
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
                        recipient: friendUsername,
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
                        requester: friendUsername,
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

  void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
