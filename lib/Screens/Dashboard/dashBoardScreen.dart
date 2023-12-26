import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/appDrawer.dart';
import 'package:flutter_application_1/Screens/Dashboard/Notifications.dart';
import 'package:flutter_application_1/Screens/Dashboard/accountSummary.dart';
import 'package:flutter_application_1/Screens/Events/CreateEventScreen.dart';
import 'package:flutter_application_1/Screens/Friends/FriendsScreen.dart';
import 'package:flutter_application_1/Screens/Friends/FriendsScreenTEMP.dart';
import 'package:flutter_application_1/Screens/Dashboard/Notifications.dart';
import 'package:flutter_application_1/Screens/Money/TransactionHistoryScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:flutter_application_1/Screens/Dashboard/quickActionsMenu.dart';
import 'package:flutter_application_1/Screens/Dashboard/userProfileSection.dart';
import 'package:flutter_application_1/Screens/dashBoardScreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:badges/badges.dart' as Badge;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late List<Map<String, dynamic>> pendingFriends = [];
  late Future<Map<String, dynamic>> userProfileFuture;
  static List<PopupMenuItem<String>> items = [];
  late List<Map<String, dynamic>> TransactionRequests = [];
  @override
  void initState() {
    super.initState();
    userProfileFuture = ApiService.fetchUserProfile();
    fetchPendingFriends();
    Notifications.fetchTransactions().then((List<Transaction>? transactions) {
      if (transactions != null) {
        TransactionRequests = transactions
            .where((transaction) =>
                transaction.processed == 0 &&
                transaction.senderId != transaction.receiverId)
            .map((Transaction transaction) {
          return {
            'sender_id': transaction.senderId,
            'amount': transaction.amount,
            'transaction_id': transaction.transactionId,
            'senderName': transaction.senderUsername,
            'createdAt': transaction.createdAt
            // Add more fields as needed
          };
        }).toList();
      } else {
        TransactionRequests = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: userProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final Map<String, dynamic> user = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
              actions: [
                Badge.Badge(
                  badgeContent: Text(
                    (pendingFriends.length + TransactionRequests.length)
                        .toString(),
                    style: TextStyle(color: Colors.white),
                  ),
                  position: Badge.BadgePosition.topEnd(top: 5, end: 5),
                  child: IconButton(
                    icon: Icon(Icons.notifications, size: 40),
                    onPressed: () {
                      fetchAndBuildNotifications(context, user);
                    },
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    UserProfileSection(user),
                    AccountSummary(user['balance'].toDouble()),
                    Notifications(),
                    UpcomingEvents(
                      events: [
                        Event(title: 'Meeting', date: '2023-11-01'),
                        Event(title: 'Workshop', date: '2023-11-05'),
                        Event(title: 'Conference', date: '2023-11-10'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            drawer: AppDrawer(user: user),
            floatingActionButton: QuickMenu(user: user),
          );
        }
      },
    );
  }

  Future<void> handleFriendRequest(
      int friendId, bool accepted, int user_id) async {
    try {
      Map<String, dynamic> requestBody = {
        'friendId': friendId,
        'accepted': accepted,
      };

      final response = await http.post(
        Uri.parse('${ApiService.serverUrl}/friends/request/$user_id'),
        body: json.encode(requestBody),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchPendingFriends();
      } else {
        print(
            'Failed to accept friend request. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error accepting friend request: $e');
      // You may want to throw an exception here or handle the error accordingly
    }
  }

  Future<void> handleTransactionRequest(
      int TransactionId, String action) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      // Make a request to your backend API to accept the request
      final response = await http.post(
        Uri.parse('${ApiService.serverUrl}/transactions/$TransactionId'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'action': action}),
      );

      if (response.statusCode == 200) {
        // Request successful
        showSuccessSnackBar(context, 'Request accepted successfully');
      } else {
        // Request failed, handle the error

        showErrorSnackBar(context, 'Error accepting request, please try again');
      }
    } catch (error) {
      // Handle exceptions
      print('Error accepting request: $error');
    }
  }

  Future<void> fetchPendingFriends() async {
    try {
      final userProfile = await userProfileFuture;
      final response = await http.get(
        Uri.parse(
            '${ApiService.serverUrl}/friends/pending/${userProfile['user_id']}'),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> pending = data['pendingFriends'];
        setState(() {
          pendingFriends = pending.cast<Map<String, dynamic>>();
        });
      } else {
        throw Exception('Failed to load pending friend requests');
      }
    } catch (e) {
      print('Error fetching pending friend requests: $e');
      setState(() {
        pendingFriends = [];
      });
    }
  }

  Future<void> fetchAndBuildNotifications(
      BuildContext context, Map<String, dynamic> user) async {
    await fetchPendingFriends();
    await Notifications.fetchTransactions()
        .then((List<Transaction>? transactions) {
      if (transactions != null) {
        TransactionRequests = transactions
            .where((transaction) =>
                transaction.processed == 0 &&
                transaction.senderId != transaction.receiverId)
            .map((Transaction transaction) {
          return {
            'sender_id': transaction.senderId,
            'amount': transaction.amount,
            'transaction_id': transaction.transactionId,
            'senderName': transaction.senderUsername,
            'createdAt': transaction.createdAt
            // Add more fields as needed
          };
        }).toList();
      } else {
        TransactionRequests = [];
      }
    });

    items.clear(); // Clear the existing items list

    if (pendingFriends.isEmpty && TransactionRequests.isEmpty) {
      items.add(buildNoNotificationsItem());
    } else {
      for (int i = 0; i < pendingFriends.length; i++) {
        PopupMenuItem<String> item =
            await buildNotificationItem(context, pendingFriends[i], user);
        items.add(item);
      }
      if (TransactionRequests.isNotEmpty) {
        for (int i = 0; i < TransactionRequests.length; i++) {
          PopupMenuItem<String> item = await buildNotificationItemTransaction(
            context,
            TransactionRequests[i],
            user,
          );
          items.add(item);
        }
      }
    }

    showNotificationsMenu(context, items, user);
  }

  PopupMenuItem<String> buildNoNotificationsItem() {
    return PopupMenuItem<String>(
      key: Key('noNotifications'),
      child: ListTile(
        title: Text('No notifications'),
      ),
    );
  }

  void showNotificationsMenu(BuildContext context,
      List<PopupMenuItem<String>> items, Map<String, dynamic> user) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(10, 10, 0, 0),
      items: items,
    ).then((String? value) {
      if (value != null) {
        // Handle menu item selection if needed
      }
    });
  }

  Future<PopupMenuItem<String>> buildNotificationItem(
    BuildContext context,
    Map<String, dynamic> friendRequest,
    Map<String, dynamic> user,
  ) async {
    String requesterName =
        await ApiService.fetchFriendUsername(friendRequest['requester_id']);

    return PopupMenuItem<String>(
      key: Key(friendRequest['requester_id'].toString()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ListTile(
              title: Text('Friend request from $requesterName'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.check, color: Colors.green),
            onPressed: () {
              handleFriendRequest(
                friendRequest['requester_id'],
                true,
                user['user_id'],
              ).then((_) {
                items.removeWhere((item) =>
                    item.key == Key(friendRequest['requester_id'].toString()));
                Navigator.pop(context);
                fetchAndBuildNotifications(context, user);
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: () {
              handleFriendRequest(
                friendRequest['requester_id'],
                false,
                user['user_id'],
              ).then((_) {
                items.removeWhere((item) =>
                    item.key == Key(friendRequest['requester_id'].toString()));
                Navigator.pop(context);
                fetchAndBuildNotifications(context, user);
              });
            },
          ),
        ],
      ),
    );
  }

  Future<PopupMenuItem<String>> buildNotificationItemTransaction(
    BuildContext context,
    Map<String, dynamic> transactionRequest,
    Map<String, dynamic> user,
  ) async {
    String requesterName = transactionRequest['senderName'];
    //await ApiService.fetchFriendUsername(transactionRequest['sender_id']);

    double requestAmount = transactionRequest['amount'];

    return PopupMenuItem<String>(
      key: Key(transactionRequest['transaction_id'].toString()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ListTile(
              title: Text('$requesterName requested $requestAmount€'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.check, color: Colors.green),
            onPressed: () {
              handleTransactionRequest(
                transactionRequest['transaction_id'],
                'accept',
              ).then((_) {
                items.removeWhere((item) =>
                    item.key ==
                    Key(transactionRequest['transaction_id'].toString()));

                Navigator.pop(context);
                fetchAndBuildNotifications(context, user);
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: () {
              handleTransactionRequest(
                transactionRequest['transaction_id'],
                'decline',
              ).then((_) {
                items.removeWhere((item) =>
                    item.key ==
                    Key(transactionRequest['transaction_id'].toString()));
                Navigator.pop(context);
                fetchAndBuildNotifications(context, user);
              });
            },
          ),
        ],
      ),
    );
  }
}
