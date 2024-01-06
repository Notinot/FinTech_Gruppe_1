import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_application_1/Screens/Events/CreateEventScreen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Money/RequestMoneyScreen.dart';
import 'package:flutter_application_1/Screens/Money/SendMoneyScreen.dart';
import 'package:intl/intl.dart';
import '../Money/TransactionHistoryScreen.dart';
import '../api_service.dart';
/* Things to do:

  Dynamic pending Friends length? oder zwischen 0-80-160 und 240?

  -search 
    -show recommendation after typing 3-4 characters in
    -Filter Friends as well?

  -Profile Picture als Avatar oder so? 
  -dynamic spacing, width, heigth etc

  -Adding Friends
    -only when not declined? cooldown?
    -dont consider blocked users !! (in searchbar as well)

  -FriendInfoScreen
    -Block or Delete Friends (block pending Friends as well?)
    -show transaction history of Friend and yourself

  -Try Catch blocks everywhere    
*/

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  //anstatt alles neuzuladen gucken ob man einfach aus der ListView eins entfernt
  //und in die andere ListView hinzufügt (ohne http request)
  callback() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, //avoids overflow when keyboard is opened
      appBar: AppBar(
        titleSpacing: 15.0,
        title: FriendsSearchBar(),
      ),
      body: Column(
        children: [
          PendingFriends(callbackFunction: callback),
          Friends(callbackFunction: callback),
        ],
      ),
    );
  }
}

class PendingFriends extends StatelessWidget {
  final Function callbackFunction;
  PendingFriends({super.key, required this.callbackFunction});

  List<Friend> pendingFriends = [];

  Future getPendingFriends() async {
    pendingFriends = [];

    //fetch user id
    Map<String, dynamic> user = await ApiService.fetchUserProfile();
    int user_id = user['user_id'];

    var response = await http
        .get(Uri.parse('${ApiService.serverUrl}/friends/pending/$user_id'));
    Map<String, dynamic> data = jsonDecode(response.body);

    for (var user in data['pendingFriends']) {
      final pendingFriendTemp = Friend(
          userID: user['requester_id'],
          requestTime: null,
          profileImage:
              (user['picture'] != null && user['picture']['data'] != null)
                  ? Uint8List.fromList(user['picture']['data'].cast<int>())
                  : null,
          username: user['username'],
          firstName: user['first_name'],
          lastName: user['last_name']);
      pendingFriends.add(pendingFriendTemp);
    }
    pendingFriends.sort(
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    //debugPrint('pendingFriends length: ${pendingFriends.length}');
    return FutureBuilder(
      future: getPendingFriends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          double height = 80;
          // if (pendingFriends.length >= 4) height = 320;
          if (pendingFriends.length >= 3) height = 240;
          if (pendingFriends.length == 2) height = 160;

          return pendingFriends
                  .isEmpty //only display Pending Friends when there are any
              ? Container()
              : Column(
                  children: [
                    Text('Pending Friends', style: TextStyle(fontSize: 25)),
                    SizedBox(
                      height: height,
                      child: ListView.builder(
                        shrinkWrap: true, //WICHTIG,
                        itemCount: pendingFriends.length,
                        itemBuilder: (context, index) {
                          //debugPrint('pendingFriendslength: ${pendingFriends.length}');
                          return Card(
                              child: FriendItem(
                            callbackFunction: callbackFunction,
                            isStillPending: true,
                            friend: pendingFriends[index],
                          ));
                        },
                      ),
                    )
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
  final Function callbackFunction;
  Friends({super.key, required this.callbackFunction});

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
          userID: user['friend_user_id'],
          requestTime: DateTime.parse(user['request_time']).toLocal(),
          profileImage: (user['friend_picture'] != null &&
                  user['friend_picture']['data'] !=
                      null) //idk if this is necessary
              ? Uint8List.fromList(user['friend_picture']['data'].cast<int>())
              : null,
          username: user['friend_username'],
          firstName: user['friend_first_name'],
          lastName: user['friend_last_name']);
      friends.add(friendTemp);
    }
    friends.sort(
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getFriends(),
      builder: (context, snapshot) {
        //if friends are loaded
        if (snapshot.connectionState == ConnectionState.done) {
          return Expanded(
            child: Column(
              children: [
                Text("Your Friends", style: TextStyle(fontSize: 25)),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: FriendItem(
                            callbackFunction: callbackFunction,
                            friend: friends[index],
                            isStillPending: false),
                      );
                    },
                  ),
                )
              ],
            ),
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

///contains all relevant user information of a friend
class Friend {
  final int userID;
  final String username;
  final String firstName;
  final String lastName;
  final Uint8List? profileImage;
  final DateTime? requestTime; //ALS DATE SPEICHERNNN
  //hier noch Timestamp von Friend table?

  Friend(
      {this.requestTime,
      required this.userID,
      required this.profileImage,
      required this.username,
      // required this.userID,
      required this.firstName,
      required this.lastName});
}
//factory constructor for json?

/// displays a single friend object in a ListTile
class FriendItem extends StatelessWidget {
  final Friend friend;
  final bool isStillPending;
  final Function callbackFunction;
  const FriendItem(
      {super.key,
      required this.friend,
      required this.isStillPending,
      required this.callbackFunction});

  @override
  Widget build(BuildContext context) {
    var trailing = isStillPending
        //build item with accept and decline buttons
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                child: Text('Accept'),
                onPressed: () {
                  handleFriendRequestResponse(friend.userID, true);
                  callbackFunction();
                },
              ),
              TextButton(
                child: Text('Decline'),
                onPressed: () {
                  handleFriendRequestResponse(friend.userID, false);
                  callbackFunction();
                },
              )
            ],
          )
        //build item without accept and decline buttons
        : IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendInfoScreen(
                    friend: friend,
                    callbackFunction: callbackFunction,
                  ),
                ),
              );
            },
            icon: Icon(Icons.info));

    return ListTile(
      leading: friend.profileImage != null
          ? ClipOval(
              child: Image.memory(
                friend.profileImage!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            )
          : Icon(Icons.person_sharp, size: 40),
      title: Text(friend.username),
      subtitle: Text('${friend.firstName} ${friend.lastName}'),
      trailing: trailing,
      onTap: () {
        //Open Dialog to either Send or Request Money
        requestOrSendMoneyDialog(context);
      },
    );
  }

  void handleFriendRequestResponse(int userID, bool accepted) async {
    //fetch user id
    Map<String, dynamic> user = await ApiService.fetchUserProfile();
    int user_id = user['user_id'];
    try {
      Map<String, dynamic> requestBody = {
        'friendId': userID, //hier friendID senden
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
        //nur updaten wenn es keine Probleme mit DB gab?
      } else {
        print(
            'Failed to accept friend request. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error handling friend request: $e');
    }
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

class FriendInfoScreen extends StatelessWidget {
  final Friend friend;
  final Function callbackFunction; // not necessary?

  const FriendInfoScreen(
      {super.key, required this.friend, required this.callbackFunction});

  @override
  Widget build(BuildContext context) {
    //debugPrint('profile picture: ${friend.profileImage?.length}');
    return Scaffold(
      appBar: AppBar(
        title: Text('Friend Details'),
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            friend.profileImage != null
                ? ClipOval(
                    child: Image.memory(
                      friend.profileImage!,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(Icons.person_sharp, size: 150),
            SizedBox(height: 20),
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
              'Friends since: ${friend.requestTime?.month}-${friend.requestTime?.day}-${friend.requestTime?.year}',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Actions: "),
                OutlinedButton(
                  child: Text("Delete"),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete'),
                        content: Text(
                            "Do you want to remove ${friend.username} as your friend?"),
                        actions: [
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          ElevatedButton(
                            child: Text('Delete'),
                            onPressed: () {
                              deleteFriend(friend.userID);
                              //I mean, dadurch wird das Pop up , der Info Screen geschlossen
                              //und der Context für navigation ist wieder richtig. Gibt vllt ne bessere Lösung
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FriendsScreen(),
                                ),
                              );

                              //callbackFunction();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                OutlinedButton(
                  onPressed: () {
                    blockFriend(friend.userID);
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
            // Container(
            //   child: TransactionHistoryScreen(),
            //   height: 100,
            //   width: 100,
            // ),
          ],
        ),
      ),
    );
  }

  void deleteFriend(int userID) async {
    //snackbar anzeigen mit deleted/error?
    //delete Friend and return to FriendScreen with updated List
    //fetch user id
    Map<String, dynamic> user = await ApiService.fetchUserProfile();
    int user_id = user['user_id'];

    try {
      Map<String, dynamic> requestBody = {'friendId': userID};
      final response = await http.delete(
        Uri.parse('${ApiService.serverUrl}/friends/$user_id'),
        body: json.encode(requestBody),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        debugPrint('Friend $userID deleted');
      } else {
        debugPrint('Friend deleted FAILED ${response.body}');
      }
    } catch (e) {
      print('Error deleting friend: $e');
    }
  }

  void blockFriend(int userID) async {
    //DialogShow to Block Friend
    Map<String, dynamic> user = await ApiService.fetchUserProfile();
    int user_id = user['user_id'];

    try {
      Map<String, dynamic> requestBody = {'friendId': userID};
      final response = await http.post(
        Uri.parse('${ApiService.serverUrl}/friends/block/$user_id'),
        body: json.encode(requestBody),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        debugPrint('Friend $userID blocked');
      } else {
        debugPrint('Friend blocking FAILED ${response.body}');
      }
    } catch (e) {
      print('Error blocking friend: $e');
    }
  }
}

class FriendsSearchBar extends StatefulWidget {
  const FriendsSearchBar({super.key});

  @override
  State<FriendsSearchBar> createState() => _FriendsSearchBarState();
}

class _FriendsSearchBarState extends State<FriendsSearchBar> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search...',
        border: InputBorder.none,
      ),
      onChanged: (query) {
        debugPrint('search query $query');
      },
      onSubmitted: (query) {
        debugPrint('submitted: $query');
        handleAddFriend(username: query);
      },
    );
  }

  void handleAddFriend({required String username}) async {
    try {
      //reads JWT again (need to be updated)
      Map<String, dynamic> user = await ApiService.fetchUserProfile();
      int user_id = user['user_id'];

      Map<String, dynamic> requestBody = {
        'friendUsername': username,
      };
      final response = await http.post(
        Uri.parse('${ApiService.serverUrl}/friends/add/$user_id'),
        body: json.encode(requestBody),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        //hier lieber true/false mit message return?
        showSuccessSnackBar(
            context, 'Friend request sended to User: $username');
      } else {
        print('Error MEssaage: ${response.body}');
        showErrorSnackBar(context, json.decode(response.body));
      }
    } catch (e) {
      print('Error accepting friend request: $e');
    }
  }

  void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }
}
