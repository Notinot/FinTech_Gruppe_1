import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Money/RequestMoneyScreen.dart';
import 'package:flutter_application_1/Screens/Money/SendMoneyScreen.dart';

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
  const PendingFriends({super.key});

  @override
  Widget build(BuildContext context) {
    return Text('Pending friends:');
  }
}

class Friends extends StatelessWidget {
  const Friends({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Your friends:'),
        FriendItem(
          friend: Friend(
              username: "user1", firstName: 'Hund', lastName: 'ert', userID: 1),
        ),
        FriendItem(
          friend: Friend(
              username: "lumein",
              firstName: 'Lukas',
              lastName: 'Meinberg',
              userID: 51),
        ),
      ],
    );
  }
}

//contains all relevant user information of a friend
class Friend {
  final int userID;
  final String username;
  final String firstName;
  final String lastName;
  //email
  //picture

  Friend(
      {required this.username,
      required this.userID,
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
      //trailing: Icon(Icons.info), //hier noch eine onPressed Funktion für Friend Info/del/block etc
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
        requestOrSendDialog(context);
      },
    );
  }

  Future<dynamic> requestOrSendDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(friend.username),
          content: Text('Send or request money'),
          actions: <Widget>[
            TextButton(
              child: Text('Send'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SendMoneyScreen(
                      recipient: friend.username,
                    ),
                  ),
                );
              },
            ),
            TextButton(
              child: Text('Request'),
              onPressed: () {
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

class FriendInfoScreen extends StatelessWidget {
  final Friend friend;

  const FriendInfoScreen({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friend Details'),
        backgroundColor: Colors.blue,
      ),
      body: Card(
        child: FriendItem(friend: friend), //das muss natürlich geändert werden
      ),
    );
  }
}
