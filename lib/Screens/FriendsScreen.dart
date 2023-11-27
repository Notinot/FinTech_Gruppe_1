import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<Map<String, dynamic>> friendData = [];
  List<Map<String, dynamic>> pendingFriends = [];
  int? user_id = null; //correct way?

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchPendingFriends();
  }

  Future<void> fetchData() async {
    try {
      //read jwt
      Map<String, dynamic> user = await ApiService.fetchUserProfile();
      user_id = user['user_id'];
      final response =
          await http.get(Uri.parse('http://localhost:3000/friends/$user_id'));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> friends = data['friends'];

        setState(() {
          friendData = friends.cast<Map<String, dynamic>>();
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> fetchPendingFriends() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:3000/friends/pending/$user_id'));

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pending Friend Requests:',
            ),
            Expanded(
              child: ListView.builder(
                itemCount: pendingFriends.length,
                itemBuilder: (context, index) {
                  final pendingFriend = pendingFriends[index];
                  return ListTile(
                    title: Text('${pendingFriend['username']}'),
                    subtitle: Text(
                      '${pendingFriend['first_name']} ${pendingFriend['last_name']}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          //accept friend requests
                          onPressed: () {
                            //change variable name in backend
                            handleFriendRequest(
                                pendingFriend['requester_id'], true);
                          },
                          child: Text('Accept'),
                        ),
                        SizedBox(width: 8),
                        TextButton(
                          //decline friend request
                          onPressed: () {
                            //change variable name in backend
                            handleFriendRequest(
                                pendingFriend['requester_id'], false);
                          },
                          child: Text('Decline'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Text(
              'Your Friends:',
            ),
            Expanded(
              child: ListView.builder(
                itemCount: friendData.length,
                itemBuilder: (context, index) {
                  final friend = friendData[index];
                  return ListTile(
                    title: Text('${friend['friend_username']}'),
                    subtitle: Text(
                        '${friend['friend_first_name']} ${friend['friend_last_name']}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void handleFriendRequest(int friendId, bool accepted) async {
    try {
      Map<String, dynamic> requestBody = {
        'friendId': friendId,
        'accepted': accepted,
      };

      final response = await http.post(
        Uri.parse('http://localhost:3000/friends/request/$user_id'),
        body: json.encode(requestBody),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        fetchPendingFriends();
        //fetch friends as well
        fetchData(); //reads JWT again which is kina unnecessary
      } else {
        print(
            'Failed to accept friend request. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error accepting friend request: $e');
    }
  }
}
