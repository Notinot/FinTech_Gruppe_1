import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/appDrawer.dart';
import 'package:flutter_application_1/Screens/Dashboard/Notifications.dart';
import 'package:flutter_application_1/Screens/Dashboard/accountSummary.dart';
import 'package:flutter_application_1/Screens/Friends/FriendsScreen.dart';
import 'package:flutter_application_1/Screens/Friends/FriendsScreenTEMP.dart';
import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:flutter_application_1/Screens/Dashboard/quickActionsMenu.dart';
import 'package:flutter_application_1/Screens/Dashboard/userProfileSection.dart';
import 'package:flutter_application_1/Screens/dashBoardScreen.dart';
import 'package:http/http.dart' as http;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  static List<PopupMenuItem<String>> items = [];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      // Fetch user profile data here
      future: ApiService.fetchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Handle errors
          return Text('Error: ${snapshot.error}');
        } else {
          // Once data is loaded, display the dashboard
          final Map<String, dynamic> user = snapshot.data!;
          List<Map<String, dynamic>> PendingFriends = [];
          // Fetch pending friends asynchronously
          fetchPendingFriends(user['user_id']).then((friends) {
            PendingFriends = friends;
          });

          return Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
              actions: [
                // Bell icon to trigger notifications menu
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    // Fetch and show notifications menu
                    fetchAndBuildNotifications(context, user);
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Display user's profile information
                    UserProfileSection(user),
                    // Display user's account summary
                    AccountSummary(user['balance'].toDouble()),
                    // Show user notifications
                    Notifications(),
                    // Display upcoming events
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
            // Add the AppDrawer to the dashboard screen
            drawer: AppDrawer(user: user),
            floatingActionButton: QuickMenu(
              user: user,
            ),
          );
        }
      },
    );
  }

  void handleFriendRequest(int friendId, bool accepted, int user_id) async {
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
        // Fetch pending friends after handling the request
        await fetchPendingFriends(user_id);
      } else {
        print(
            'Failed to accept friend request. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error accepting friend request: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPendingFriends(int user_id) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiService.serverUrl}/friends/pending/$user_id'));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> pending = data['pendingFriends'];
        List<Map<String, dynamic>> pendingFriends =
            pending.cast<Map<String, dynamic>>();
        print('Pending Friends: $pendingFriends');
        return pendingFriends;
      } else {
        throw Exception('Failed to load pending friend requests');
      }
    } catch (e) {
      print('Error fetching pending friend requests: $e');
      // Return an empty list to handle the error case
      return [];
    }
  }

  void fetchAndBuildNotifications(
      BuildContext context, Map<String, dynamic> user) async {
    List<Map<String, dynamic>> pendingFriends =
        await fetchPendingFriends(user['user_id']);
    List<PopupMenuItem<String>> items = [];

    for (int i = 0; i < pendingFriends.length; i++) {
      PopupMenuItem<String> item =
          await buildNotificationItem(context, pendingFriends[i], user);
      items.add(item);
    }

    // Display notifications in the AppBar
    showNotificationsMenu(context, items, user);
  }

  void showNotificationsMenu(BuildContext context,
      List<PopupMenuItem<String>> items, Map<String, dynamic> user) {
    // Use a PopupMenuButton for the notifications
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(10, 10, 0, 0),
      items: items,
    ).then((String? value) {
      // Handle menu item selection if needed
      if (value != null) {
        // You can perform additional actions based on the selected value
      }
    });
  }

  Future<PopupMenuItem<String>> buildNotificationItem(BuildContext context,
      Map<String, dynamic> friendRequest, Map<String, dynamic> user) async {
    String requesterName =
        await ApiService.fetchFriendUsername(friendRequest['requester_id']);

    return PopupMenuItem<String>(
      key: Key(friendRequest['requester_id'].toString()), // Add a unique key
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
              // Handle green tick action
              handleFriendRequest(
                  friendRequest['requester_id'], true, user['user_id']);
              // Remove the item from the list
              items.removeWhere((item) =>
                  item.key == Key(friendRequest['requester_id'].toString()));
              Navigator.pop(context);
              fetchAndBuildNotifications(context, user);
            },
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: () {
              // Handle red cross action
              handleFriendRequest(
                  friendRequest['requester_id'], false, user['user_id']);
              // Remove the item from the list
              items.removeWhere((item) =>
                  item.key == Key(friendRequest['requester_id'].toString()));
              Navigator.pop(context);
              fetchAndBuildNotifications(context, user);
            },
          ),
        ],
      ),
    );
  }
}
