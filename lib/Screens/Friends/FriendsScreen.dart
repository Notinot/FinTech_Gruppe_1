import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<Map<String, dynamic>> friendData = [];
  List<Map<String, dynamic>> pendingFriends = [];

  int? user_id = null; //not the right way, needs to be updated

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchPendingFriends();
  }

  /*
  Reads JWT to get user_id
  Then fetches Friends
  */
  Future<void> fetchData() async {
    try {
      //read jwt
      Map<String, dynamic> user = await ApiService.fetchUserProfile();
      user_id = user['user_id'];
      final response =
          await http.get(Uri.parse('${ApiService.serverUrl}/friends/$user_id'));

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

  /*
  Fetches Pending Friend Requests
  */
  Future<void> fetchPendingFriends() async {
    try {
      //reads JWT again (need to be updated)
      Map<String, dynamic> user = await ApiService.fetchUserProfile();
      user_id = user['user_id'];
      final response = await http
          .get(Uri.parse('${ApiService.serverUrl}/friends/pending/$user_id'));

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

  /*
  Actual Screen
  */
  /* Vllt hier alles bisschen mehr aufteilen
      Searchbar(),
        Column(
          children[
            PendingFriends(),
            Friends(),
          ]
        )
   
  */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SearchBar(),
      ),
      body: Center(
        child: Column(
          children: [
            _buildPendingFriendRequests(),
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

  Widget _buildPendingFriendRequests() {
    if (pendingFriends.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Friend Requests:',
          ),
          Container(
            height: 200, // Set a fixed height or use Flexible
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
                        onPressed: () {
                          handleFriendRequest(
                            pendingFriend['requester_id'],
                            true,
                          );
                        },
                        child: Text('Accept'),
                      ),
                      SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          handleFriendRequest(
                            pendingFriend['requester_id'],
                            false,
                          );
                        },
                        child: Text('Decline'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  void handleFriendRequest(int friendId, bool accepted) async {
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
        fetchPendingFriends();
        //fetch friends as well
        fetchData(); //reads JWT again which is kinda unnecessary
      } else {
        print(
            'Failed to accept friend request. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error accepting friend request: $e');
    }
  }
}

class SearchBar extends StatefulWidget {
  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white),
      ),
      style: TextStyle(color: Colors.white),
      onChanged: (inputQuery) {
        //hier könnten Vorschläge gemacht werden
        print('Search query: $inputQuery');
      }, //add friend hier? oder erstmal anzeigen und dannach adden?
      onSubmitted: (value) {
        print('Submitted: $value');
        handleAddFriend(value);
        // showSuccessSnackBar(context, 'Friend request send to: $value');
      },
    );
  }

  void handleAddFriend(friendName) async {
    try {
      //reads JWT again (need to be updated)
      Map<String, dynamic> user = await ApiService.fetchUserProfile();
      int user_id = user['user_id'];

      Map<String, dynamic> requestBody = {
        'friendUsername': friendName,
      };

      final response = await http.post(
        Uri.parse('${ApiService.serverUrl}/friends/add/$user_id'),
        body: json.encode(requestBody),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        showSuccessSnackBar(
            context, 'Friend request sended to User: $friendName');
      } else {
        print('Error MEssaage: ${response.body}');
        showErrorSnackBar(context, json.decode(response.body));
      }
    } catch (e) {
      print('Error accepting friend request: $e');
    }
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
