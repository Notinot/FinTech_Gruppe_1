import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Money/RequestMoneyScreen.dart';
import 'package:flutter_application_1/Screens/Money/SendMoneyScreen.dart';
import '../api_service.dart';

class FriendsScreenTEMP extends StatelessWidget {
  const FriendsScreenTEMP({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SearchBar(hintText: "Search..."),
      ),
      body: Column(
        children: [
          PendingFriends(),
          Friends(),
        ],
      ),
    );
  }
}

class PendingFriends extends StatelessWidget {
  PendingFriends({super.key});

  List<Friend> pendingFriends = [];

  Future getPendingFriends() async {
    Map<String, dynamic> user = await ApiService.fetchUserProfile();
    int user_id = user['user_id'];

    var response = await http
        .get(Uri.parse('${ApiService.serverUrl}/friends/pending/$user_id'));
    Map<String, dynamic> data = jsonDecode(response.body);

    for (var user in data['pendingFriends']) {
      final pendingFriendTemp = Friend(
          profileImage: null,
          username: user['username'],
          firstName: user['first_name'],
          lastName: user['last_name']);
      pendingFriends.add(pendingFriendTemp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getPendingFriends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Column(
            children: [
              Text('Pending Friends', style: TextStyle(fontSize: 25)),
              for (Friend pendingFriend in pendingFriends)
                PendingFriendItem(friend: pendingFriend), //
            ],
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

class Friends extends StatelessWidget {
  Friends({super.key});

  List<Friend> friends = [];

  //get Friend from DB and saves into friends List
  Future getFriends() async {
    //read jwt
    Map<String, dynamic> user = await ApiService.fetchUserProfile();
    int user_id = user['user_id'];

    var response = //hier einfach jwt mitgeben anstatt user id auslesen??
        await http.get(Uri.parse('${ApiService.serverUrl}/friends/$user_id'));

    Map<String, dynamic> data = jsonDecode(response.body);

    for (var user in data['friends']) {
      final friendTemp = Friend(
          //profileImage: friend['friend_picture'], muss noch richtig decoded werden
          profileImage: null,
          username: user['friend_username'],
          firstName: user['friend_first_name'],
          lastName: user['friend_last_name']);

      friends.add(friendTemp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getFriends(),
      builder: (context, snapshot) {
        //if friends are loaded
        if (snapshot.connectionState == ConnectionState.done) {
          return Column(
            children: [
              Text("Your Friends",
                  style: TextStyle(
                      fontSize: 25)), //hier noch n List View Builder??
              for (Friend friend in friends) FriendItem(friend: friend),
              //FriendItem(friend: friends[1]),
            ],
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

//contains all relevant user information of a friend
class Friend {
//  final int userID;
  final String username;
  final String firstName;
  final String lastName;
  final Uint8List? profileImage;
  //hier noch Timestamp von Friend table?

  Friend(
      {required this.profileImage,
      required this.username,
      // required this.userID,
      required this.firstName,
      required this.lastName});
}
//factory constructor for json?

//displays a single friend object in a ListTile
class FriendItem extends StatelessWidget {
  final Friend friend;
  const FriendItem({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.person_sharp),
      title: Text(friend.username),
      subtitle: Text('${friend.firstName} ${friend.lastName}'),
      trailing: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FriendInfoScreen(
                  friend: friend,
                ),
              ),
            );
          },
          icon: Icon(Icons.info)),
      onTap: () {
        //Open Dialog to either Send or Request Money
        requestOrSendMoneyDialog(context);
      },
    );
  }

  Future<dynamic> requestOrSendMoneyDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(friend.username),
          content: Text('Send or request money'),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Send'),
              onPressed: () {
                Navigator.pop(
                    context); //closes dialog so pressing return wont open it again
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SendMoneyScreen(
                      recipient: friend.username,
                    ),
                  ),
                );
              },
            ),
            ElevatedButton(
              child: Text('Request'),
              onPressed: () {
                Navigator.pop(
                    context); //closes dialog so pressing return wont open it again
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RequestMoneyScreen(
                      requester: friend.username,
                    ),
                  ),
                );
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class PendingFriendItem extends StatelessWidget {
  final Friend friend;
  const PendingFriendItem({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.person),
      title: Text(friend.username),
      subtitle: Text('${friend.firstName} ${friend.lastName}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              //acceptPendingFriend();
            },
            child: Text('Accept'),
          ),
          TextButton(
              onPressed: () {
                //declinePendingFriend();
              },
              child: Text('Decline'))
        ],
      ),
    );
  }
}

class FriendInfoScreen extends StatelessWidget {
  final Friend friend;

  const FriendInfoScreen({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friend Details'),
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            Icon(
              Icons.person_sharp,
              size: 150,
            ),
            Text(
              friend.username,
              style: TextStyle(fontSize: 30),
            ),
            SizedBox(height: 20),
            Text(
              '${friend.firstName} ${friend.lastName}',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              'Friends since: ',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Actions: "),
                OutlinedButton(
                  onPressed: () {
                    deleteFriend(friend.username);
                  },
                  child: Text("Delete"),
                ),
                OutlinedButton(
                  onPressed: () {
                    blockFriend(friend.username);
                  },
                  child: Text("Block"),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Transaction History: ',
              style: TextStyle(fontSize: 30),
            ),
          ],
        ),
      ),
    );
  }

  void deleteFriend(String username) async {
    //delete Friend and return to FriendScreen with updated List
  }
  void blockFriend(String username) async {
    //DialogShow to Block Friend
  }
}
