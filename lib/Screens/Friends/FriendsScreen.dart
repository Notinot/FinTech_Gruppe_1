import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_application_1/Screens/Dashboard/appDrawer.dart';
import 'package:flutter_application_1/Screens/Money/TransactionHistoryScreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Money/RequestMoneyScreen.dart';
import 'package:flutter_application_1/Screens/Money/SendMoneyScreen.dart';
import 'package:flutter_application_1/fonts/custom_icons_icons.dart';

import '../api_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  callback() {
    setState(() {});
  }

  String? token = "";

  Future readToken() async {
    try {
      token = await FlutterSecureStorage().read(key: 'token');
    } catch (error) {
      print('Error reading token: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: readToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            resizeToAvoidBottomInset:
                false, //avoids overflow when keyboard is opened
            appBar: AppBar(
              titleSpacing: 15.0,
              title: Text('Friends'),
              actions: [
                IconButton(
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: FriendsSearchBar(
                          callbackFunction: callback, token: token),
                    );
                  },
                  icon: Icon(
                    Icons.search,
                    size: MediaQuery.of(context).size.width *
                        0.07, //Dynamic Icon size depending on screen res
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlockedUsersScreen(token: token),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.person_off,
                    size: MediaQuery.of(context).size.width *
                        0.07, //Dynamic Icon size depending on screen res
                  ),
                  // padding: EdgeInsets.only(right: 15), //Distance to the right
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Info"),
                            content: const Text(
                                "To add a friend, click on the Search Icon and enter the username of the person you want to add.\n\nTo remove a friend, click on a friend in the list, then click the 'Delete' button.\n\nYou can also block a friend by clicking on the 'Block' button.\n\n To send or request money from a friend, click on the 'Exchange' button next to the friend's name.\n\nTo see the transaction history of a friend, click on the friend's name.\n\nTo unblock a friend, click on the 'Unblock' button in the blocked users list."),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text("Close"))
                            ],
                          );
                        });
                  },
                )
              ],
            ),
            drawer: FutureBuilder<Map<String, dynamic>>(
              future: ApiService.fetchUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Drawer(
                    child: ListTile(
                      title: Text('Loading...'),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Drawer(
                    child: ListTile(
                      title: Text('Error: ${snapshot.error}'),
                    ),
                  );
                } else {
                  final Map<String, dynamic> user = snapshot.data!;
                  return AppDrawer(user: user);
                }
              },
            ),
            body: Column(
              children: [
                PendingFriends(callbackFunction: callback, token: token),
                Friends(callbackFunction: callback, token: token),
              ],
            ),
          );
        } else {
          return Container(
            child: Text('Kaputt'),
          );
        }
      },
    );
  }

  /*@override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, //avoids overflow when keyboard is opened
      appBar: AppBar(
        titleSpacing: 15.0,
        title: Text('Friends'),
        actions: [
          IconButton(
              onPressed: () {
                showSearch(
                    context: context,
                    delegate: FriendsSearchBar(callbackFunction: callback));
              },
              icon: Icon(Icons.search)),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlockedUsersScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.person_off,
              size: MediaQuery.of(context).size.width *
                  0.07, //Dynamic Icon size depending on screen res
            ),
            padding: EdgeInsets.only(right: 15), //Distance to the right
          )
        ],
      ),
      body: Column(
        children: [
          PendingFriends(callbackFunction: callback),
          Friends(callbackFunction: callback),
        ],
      ),
    );
  }*/
}

class PendingFriends extends StatelessWidget {
  final Function callbackFunction;
  final String? token;
  PendingFriends(
      {super.key, required this.callbackFunction, required this.token});

  List<Friend> pendingFriends = [];

  Future getPendingFriends() async {
    pendingFriends = [];

    var response = await http
        .get(Uri.parse('${ApiService.serverUrl}/friends/pending/'), headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    });
//    print(jsonDecode(response.body));
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
                          return FriendItem(
                            token: token,
                            callbackFunction: callbackFunction,
                            isStillPending: true,
                            friend: pendingFriends[index],
                          );
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
  final String? token;
  Friends({super.key, required this.callbackFunction, required this.token});

  List<Friend> friends = [];

  //get Friend from DB and saves into friends List
  Future getFriends() async {
    var response =
        await http.get(Uri.parse('${ApiService.serverUrl}/friends/'), headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    });

    Map<String, dynamic> data = jsonDecode(response.body);
    //debugPrint(data['friends'].runtimeType.toString());
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
          return friends.isEmpty
              ? Center(
                  child: Text('No friends found'),
                )
              : Expanded(
                  child: Column(
                    children: [
                      Text("Your Friends", style: TextStyle(fontSize: 25)),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            return FriendItem(
                                token: token,
                                callbackFunction: callbackFunction,
                                friend: friends[index],
                                isStillPending: false);
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

class BlockedUsersScreen extends StatefulWidget {
  final String? token;
  const BlockedUsersScreen({super.key, required this.token});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  callback() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, //avoids overflow when keyboard is opened
      appBar: AppBar(
        titleSpacing: 15.0,
        title: Text('Blocked Users'),
      ),
      body: Column(
        children: [
          BlockedUsers(token: widget.token),
        ],
      ),
    );
  }
}

///Gets all blocked users from backend and displays them with option to un-block them again
class BlockedUsers extends StatelessWidget {
  final String? token;
  BlockedUsers({super.key, required this.token});

  List<Friend> blockedUsers = [];

  //get blocked users from DB and saves into List
  Future getBlockedUsers() async {
    var response = await http
        .get(Uri.parse('${ApiService.serverUrl}/friends/block/'), headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    });

    Map<String, dynamic> data = jsonDecode(response.body);

    for (var user in data['blockedUsers']) {
      final blockedUserTemp = Friend(
          userID: user['addressee_id'],
          requestTime: DateTime.parse(user['request_time']).toLocal(),
          profileImage: (user['picture'] != null &&
                  user['picture']['data'] != null) //idk if this is necessary
              ? Uint8List.fromList(user['picture']['data'].cast<int>())
              : null,
          username: user['username'],
          firstName: user['first_name'],
          lastName: user['last_name']);
      blockedUsers.add(blockedUserTemp);
    }
    blockedUsers.sort(
        //vllt nach time sorten? so dass neuster block ganz oben ist
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getBlockedUsers(),
      builder: (context, snapshot) {
        //if users are loaded
        if (snapshot.connectionState == ConnectionState.done) {
          return blockedUsers.isNotEmpty
              ? Expanded(
                  child: Column(
                    children: [
                      //Text("Blocked Users", style: TextStyle(fontSize: 25)),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: blockedUsers.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: BlockedUserItem(
                                token: token,
                                user: blockedUsers[index],
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                )
              : Center(
                  child: Text(
                  "No blocked users",
                  style: TextStyle(fontSize: 18),
                ));
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

///contains all relevant user information of a user
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

/// displays a single friend object in a ListTile
class FriendItem extends StatelessWidget {
  final String? token;
  final Friend friend;
  final bool isStillPending;
  final Function callbackFunction;
  const FriendItem(
      {super.key,
      required this.token,
      required this.friend,
      required this.isStillPending,
      required this.callbackFunction});

  @override
  Widget build(BuildContext context) {
    var trailing = isStillPending
        ? Row(
            //build item with accept and decline buttons
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                child: Row(
                  children: [
                    Icon(Icons.person_add,
                        size: MediaQuery.of(context).size.height * 0.025),
                    Padding(padding: EdgeInsets.only(right: 7)),
                    Text(
                      'Accept',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                onPressed: () {
                  handleFriendRequestResponse(
                      userID: friend.userID, accepted: true, token: token);
                  callbackFunction();
                },
              ),
              TextButton(
                child: Icon(Icons.close),
                onPressed: () {
                  handleFriendRequestResponse(
                      userID: friend.userID, accepted: false, token: token);
                  callbackFunction();
                },
              ),
            ],
          )
        //build item WITHOUT accept/decline buttons BUT with Icon Button
        : ElevatedButton(
            onPressed: () {
              requestOrSendMoneyDialog(context);
            },
            child: Icon(
              MyFlutterApp.exchange,
              //Icons.add,
              //Icons.currency_exchange_outlined,
              size: 25,
            ));

    return Card(
      child: ListTile(
        leading: ShowProfilePicture(
            image: friend.profileImage,
            initial: friend.firstName[0] + friend.lastName[0],
            size: 25),
        title:
            Text(friend.username, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${friend.firstName} ${friend.lastName}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: trailing,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  //isStillPending
                  // ? UserInfoScreen(
                  //     userID: friend.userID,
                  //     userName: friend.username,
                  //     callbackFunction: callbackFunction,
                  //     friendRequestSend: false,
                  //   )
                  //:
                  FriendInfoScreen(
                token: token,
                friend: friend,
                callbackFunction: callbackFunction,
                pendingFriendRequestReceived: isStillPending,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<dynamic> requestOrSendMoneyDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(friend.username),
          //title: Text('Send/Request money'),
          content: Text('Send or Request money?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
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
          ],
        );
      },
    );
  }
}

Future<void> handleFriendRequestResponse(
    {required int userID,
    required bool accepted,
    required String? token}) async {
  try {
    Map<String, dynamic> requestBody = {
      'friendId': userID, //hier friendID senden
      'accepted': accepted,
    };
    final response = await http.post(
      Uri.parse('${ApiService.serverUrl}/friends/request/'),
      body: json.encode(requestBody),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
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

//PendingFriendItem
class BlockedUserItem extends StatelessWidget {
  final String? token;
  final Friend user;
  const BlockedUserItem({super.key, required this.user, required this.token});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.person, size: 40),
      // ShowProfilePicture(
      //     image: user.profileImage,
      //     initial: user.firstName[0] + user.lastName[0],
      //     size: 20),
      title: Text(user.username),
      //subtitle: Text('${user.firstName} ${user.lastName}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          //Text('Hier Werbung'), //blocked at hier anzeigen?
          ElevatedButton(
            child: Text('Unblock'),
            onPressed: () {
              //Dialog -> nav pop
              // handleUnblockUser(user.userID);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Block'),
                  content: Text("Do you want to unblock ${user.username}?"),
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    ElevatedButton(
                      child: Text('Unblock'),
                      onPressed: () {
                        handleUnblockUser(userID: user.userID, token: token);
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BlockedUsersScreen(token: token),
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
        ],
      ),
    );
  }

  void handleUnblockUser({required int userID, required String? token}) async {
    try {
      Map<String, dynamic> requestBody = {'friendId': userID};
      final response = await http.post(
        Uri.parse('${ApiService.serverUrl}/friends/unblock/'),
        body: json.encode(requestBody),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        debugPrint('Friend $userID unblocked');
      } else {
        debugPrint('Friend unblocking FAILED ${response.body}');
      }
    } catch (e) {
      print('Error unblocking friend: $e');
    }
  }
}

//Show an info screen of a befriended user (has option to delete them & shows how long user is friends with them)
class FriendInfoScreen extends StatelessWidget {
  final Friend friend;
  final Function callbackFunction; // not necessary?
  final bool pendingFriendRequestReceived;
  final String? token;

  const FriendInfoScreen(
      {super.key,
      required this.token,
      required this.friend,
      required this.callbackFunction,
      required this.pendingFriendRequestReceived});

  @override
  Widget build(BuildContext context) {
    //debugPrint('profile picture: ${friend.profileImage?.length}');

    return FutureBuilder<String>(
      future: ApiService.fetchUserId(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Handle errors
          return Text('Error: ${snapshot.error}');
        } else {
          if (snapshot.connectionState == ConnectionState.done) {
            final int userId = int.parse(snapshot.data!);

            return Scaffold(
              appBar: AppBar(
                title: Text('Friend Details'),
              ),
              body: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  children: [
                    ShowProfilePicture(
                        image: friend.profileImage,
                        initial: friend.firstName[0] + friend.lastName[0],
                        size: 60),
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
                    pendingFriendRequestReceived
                        ? Container()
                        : Text(
                            'Friends since: ${friend.requestTime?.month}-${friend.requestTime?.day}-${friend.requestTime?.year}',
                            style: TextStyle(fontSize: 20)),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Actions: "),
                        pendingFriendRequestReceived
                            ? Container()
                            : OutlinedButton(
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
                                            deleteFriend(
                                                userID: friend.userID,
                                                token: token);
                                            //I mean, dadurch wird das Pop up & der Info Screen geschlossen
                                            //und der Context für navigation ist wieder richtig. Gibt vllt ne bessere Lösung
                                            // Navigator.of(context).pop();
                                            Navigator.of(context).pop();
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    FriendsScreen(),
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
                        BlockUserButton(
                            token: token,
                            userID: friend.userID,
                            userName: friend.username),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Transaction History: ',
                      style: TextStyle(fontSize: 30),
                    ),
                    //show transaction history of friend with widget
                    Expanded(
                      child: TransactionListWidget(
                        userId: userId,
                        friendId: friend.userID,
                        friendUsername:
                            friend.username, // Pass friend's username
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        }
      },
    );
  }

  //   child: Scaffold(

  //     appBar: AppBar(
  //       title: Text('Friend Details'),
  //     ),
  //     body: SizedBox(
  //       width: double.infinity,
  //       height: double.infinity,
  //       child: Column(
  //         children: [
  //           ShowProfilePicture(
  //               image: friend.profileImage,
  //               initial: friend.firstName[0] + friend.lastName[0],
  //               size: 60),
  //           SizedBox(height: 20),
  //           Text(
  //             friend.username,
  //             style: TextStyle(fontSize: 30),
  //           ),
  //           SizedBox(height: 20),
  //           Text(
  //             '${friend.firstName} ${friend.lastName}',
  //             style: TextStyle(fontSize: 20),
  //           ),
  //           SizedBox(height: 20),
  //           pendingFriendRequestReceived
  //               ? Container()
  //               : Text(
  //                   'Friends since: ${friend.requestTime?.month}-${friend.requestTime?.day}-${friend.requestTime?.year}',
  //                   style: TextStyle(fontSize: 20)),

  //           SizedBox(height: 20),
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Text("Actions: "),
  //               pendingFriendRequestReceived
  //                   ? Container()
  //                   : OutlinedButton(
  //                       child: Text("Delete"),
  //                       onPressed: () {
  //                         showDialog(
  //                           context: context,
  //                           builder: (context) => AlertDialog(
  //                             title: Text('Delete'),
  //                             content: Text(
  //                                 "Do you want to remove ${friend.username} as your friend?"),
  //                             actions: [
  //                               TextButton(
  //                                 child: Text('Cancel'),
  //                                 onPressed: () {
  //                                   Navigator.of(context).pop();
  //                                 },
  //                               ),
  //                               ElevatedButton(
  //                                 child: Text('Delete'),
  //                                 onPressed: () {
  //                                   deleteFriend(
  //                                       userID: friend.userID, token: token);
  //                                   //I mean, dadurch wird das Pop up & der Info Screen geschlossen
  //                                   //und der Context für navigation ist wieder richtig. Gibt vllt ne bessere Lösung
  //                                   // Navigator.of(context).pop();
  //                                   Navigator.of(context).pop();
  //                                   Navigator.pushReplacement(
  //                                     context,
  //                                     MaterialPageRoute(
  //                                       builder: (context) => FriendsScreen(),
  //                                     ),
  //                                   );
  //                                   //callbackFunction();
  //                                 },
  //                               ),
  //                             ],
  //                           ),
  //                         );
  //                       },
  //                     ),
  //               BlockUserButton(
  //                   token: token,
  //                   userID: friend.userID,
  //                   userName: friend.username),
  //             ],
  //           ),
  //           SizedBox(height: 20),
  //           Text(
  //             'Transaction History: ',
  //             style: TextStyle(fontSize: 30),
  //           ),
  //           // show transaction history of friend with widget
  //           SingleChildScrollView(

  //             child: TransactionListWidget(
  //               userId: userId,
  //               friendId: friend.userID,
  //               friendUsername: friend.username, // Pass friend's username
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   ),
  // );
  // }

  void deleteFriend({required int userID, required String? token}) async {
    //snackbar anzeigen mit deleted/error?
    //delete Friend and return to FriendScreen with updated List

    try {
      Map<String, dynamic> requestBody = {'friendId': userID};
      final response = await http.delete(
        Uri.parse('${ApiService.serverUrl}/friends/'),
        body: json.encode(requestBody),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
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
}

//testing --------------------------
class UserInfoScreen extends StatelessWidget {
  //final Friend user;
  final int userID;
  final String userName;
  final Function callbackFunction; // not necessary?
  final bool friendRequestSend;
  final String? token;
  //noEntry, requestAlreadySend,
  //TheySendYouRequest -< nicht anzeigen

  const UserInfoScreen(
      {super.key,
      required this.token,
      required this.userID,
      required this.userName,
      required this.callbackFunction,
      required this.friendRequestSend});

  @override
  Widget build(BuildContext context) {
    //debugPrint('profile picture: ${friend.profileImage?.length}');
    return FutureBuilder<String>(
      future: ApiService.fetchUserId(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Handle errors
          return Text('Error: ${snapshot.error}');
        } else {
          if (snapshot.connectionState == ConnectionState.done) {
            final int userId = int.parse(snapshot.data!);

            return Scaffold(
              appBar: AppBar(
                title: Text('User Details'),
              ),
              body: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  children: [
                    //not even show initiales?
                    // ShowProfilePicture(
                    //     image: null, //dont show profile picture of strangers
                    //     initial: user.firstName[0] + user.lastName[0],
                    //     size: 60),
                    SizedBox(height: 20),
                    Text(
                      userName,
                      style: TextStyle(fontSize: 30),
                    ),
                    SizedBox(height: 20),
                    // Text(
                    //   '${user.firstName} ${user.lastName}',
                    //   style: TextStyle(fontSize: 20),
                    // ),
                    // SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Actions: "),

                        //ADD FrIned button als statefull und denn dann ändern wenn man den gedrückt hat???

                        AddFriendButton(
                            userID: userID,
                            userName: userName,
                            token: token,
                            friendRequestSend: friendRequestSend),

                        BlockUserButton(
                            userID: userID, userName: userName, token: token),

                        //hier kommen buttons hin, block zb
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Transaction History: ',
                      style: TextStyle(fontSize: 30),
                    ),
                    Expanded(
                      child: TransactionListWidget(
                        userId: userId,
                        friendId: userID,
                        friendUsername: userName,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        }
      },
    );
  }
}

class BlockUserButton extends StatelessWidget {
  int userID;
  String userName;
  final String? token;

  BlockUserButton(
      {super.key,
      required this.userID,
      required this.userName,
      required this.token});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      child: Text("Block"),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Block'),
            content: Text("Do you want to block $userName?"),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: Text('Block'),
                onPressed: () {
                  blockFriend(userID: userID, token: token);
                  //I mean, dadurch wird das Pop up & der Info Screen geschlossen
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
    );
  }

  void blockFriend({required int userID, required String? token}) async {
    //insert here DialogShow to Block Friend?

    try {
      Map<String, dynamic> requestBody = {'friendId': userID};
      final response = await http.post(
        Uri.parse('${ApiService.serverUrl}/friends/block/'),
        body: json.encode(requestBody),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
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

//SearchBar - --
class FriendsSearchBar extends SearchDelegate {
  final Function callbackFunction;
  final String? token;
  List<dynamic> suggestedUsers = [];

  FriendsSearchBar(
      {super.searchFieldLabel,
      required this.token,
      super.searchFieldStyle,
      super.searchFieldDecorationTheme,
      super.keyboardType,
      super.textInputAction,
      required this.callbackFunction}); //testing

  //Leading Icon (back arrow)
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back));

  //Tailing Icon (X to clear query)
  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
            onPressed: () {
              if (query.isEmpty) {
                close(context, null);
              } else {
                query = ''; //Clears query when X is pressed
              }
            },
            icon: Icon(Icons.clear))
      ];

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }
  //UserInfo mit Add Button?

  @override
  Widget buildSuggestions(BuildContext context) {
    suggestedUsers = [];

    if (query.length >= 4 && query.length <= 20) {
      return FutureBuilder(
        future: getSuggestions(query: query, token: token),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            //sort suggestions by status so friends are displayed first
            suggestedUsers.sort(
              (a, b) {
                if (b['status'] == 'friend') {
                  return 1;
                } else {
                  return 0;
                }
              },
            );
            return ListView.builder(
              itemCount: suggestedUsers.length,
              itemBuilder: (context, index) {
                //I mean, es funktioniert
                Uint8List? pictureData;
                if (suggestedUsers[index]['status'] == 'friend') {
                  pictureData = (suggestedUsers[index]['picture'] != null &&
                          suggestedUsers[index]['picture']['data'] != null)
                      ? Uint8List.fromList(
                          suggestedUsers[index]['picture']['data'].cast<int>())
                      : null;
                }
                //debugPrint(suggestedUsers[index].toString());
                return Card(
                  child: ListTile(
                    leading: suggestedUsers[index]['status'] == 'friend'
                        ? ShowProfilePicture(
                            image: pictureData,
                            initial:
                                '${suggestedUsers[index]['first_name'][0]}${suggestedUsers[index]['last_name'][0]}',
                            size: 20)
                        : Icon(Icons.person, size: 40),
                    title: Text(suggestedUsers[index]['username']),
                    subtitle: suggestedUsers[index]['status'] ==
                            'friend' //when already friends - show full name
                        ? Text(
                            '${suggestedUsers[index]['first_name']} ${suggestedUsers[index]['last_name']}')
                        : null,
                    onTap: () {
                      //hier entweder FriendInfo oder UserInfo (mit add oder mit send)

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              suggestedUsers[index]['status'] == 'friend'
                                  ? FriendInfoScreen(
                                      token: token,
                                      pendingFriendRequestReceived: false,
                                      friend: Friend(
                                          userID: suggestedUsers[index]
                                              ['user_id'],
                                          profileImage: (suggestedUsers[index]
                                                          ['picture'] !=
                                                      null &&
                                                  suggestedUsers[index]
                                                          ['picture']['data'] !=
                                                      null) //idk if this is necessary
                                              ? Uint8List.fromList(suggestedUsers[index]
                                                      ['picture']['data']
                                                  .cast<int>())
                                              : null,
                                          username: suggestedUsers[index]
                                              ['username'],
                                          firstName: suggestedUsers[index]
                                              ['first_name'],
                                          lastName: suggestedUsers[index]
                                              ['last_name'],
                                          requestTime:
                                              DateTime.parse(suggestedUsers[index]['request_time'])
                                                  .toLocal()),

                                      callbackFunction: callbackFunction, //!!,
                                    )
                                  : UserInfoScreen(
                                      token: token,
                                      userID: suggestedUsers[index]['user_id'],
                                      userName: suggestedUsers[index]
                                          ['username'],
                                      callbackFunction: callbackFunction, //!!
                                      friendRequestSend: suggestedUsers[index]
                                                  ['status'] ==
                                              'requested'
                                          ? true
                                          : false,
                                    ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          } else {
            return Container();
          }
        },
      );
    } else {
      return Center(
        child: Text(
            'Can´t find the user you are looking for? \n\nTake a look at your pending friend requests. \nOr you might have blocked them.',
            style: TextStyle(fontSize: 20)),
      );
    }
  }

  Future getSuggestions({required String query, required String? token}) async {
    Map<String, dynamic> requestBody = {'query': query}; //!

    var response = await http.post(
      Uri.parse('${ApiService.serverUrl}/users/'),
      body: json.encode(requestBody),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    Map<String, dynamic> data = jsonDecode(response.body);
    // debugPrint('dataMatchingUsers: ${data['matchingUsersFinal']}');
    // debugPrint('TYPE: ${data['matchingUsersFinal'].runtimeType}');

    suggestedUsers = [];
    for (var user in data['matchingUsersFinal']) {
      //var user testing
      suggestedUsers.add(user);
    }

    // debugPrint('suggestedUsers: $suggestedUsers');
  }

  // void showSuccessSnackBar(BuildContext context, String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     content: Text(message),
  //     backgroundColor: Colors.green,
  //   ));
  // }

  // void showErrorSnackBar(BuildContext context, String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     content: Text(message),
  //     backgroundColor: Colors.red,
  //   ));
  // }
}

class AddFriendButton extends StatefulWidget {
  int userID;
  String userName;
  final String? token;

  bool friendRequestSend;

  AddFriendButton(
      {super.key,
      required this.userID,
      required this.token,
      required this.userName,
      required this.friendRequestSend});

  @override
  State<AddFriendButton> createState() => _AddFriendButtonState();
}

class _AddFriendButtonState extends State<AddFriendButton> {
  @override
  Widget build(BuildContext context) {
    return widget.friendRequestSend
        ? OutlinedButton(onPressed: null, child: Text('Requested'))
        : ElevatedButton(
            child: Text("Add"),
            onPressed: () {
              addFriend(
                  username: widget.userName,
                  context: context,
                  token: widget.token);
              setState(() {
                widget.friendRequestSend =
                    true; //ist das so korrekt mit widget. ?
              });
              //Navigator.of(context).pop();
              //callbackFunction();
            },
          );
  }
}

void addFriend(
    {required String username,
    required BuildContext context,
    required String? token}) async {
  try {
    Map<String, dynamic> requestBody = {
      'friendUsername': username,
    };
    final response = await http.post(
      Uri.parse('${ApiService.serverUrl}/friends/add/'),
      body: json.encode(requestBody),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      debugPrint('Added friend successful');
      //hier lieber true/false mit message return?
      showSuccessSnackBarr(context, 'Friend request sent to User: $username');
    } else {
      print('Error MEssaage: ${response.body}');
      showErrorSnackBarr(context, json.decode(response.body));
    }
  } catch (e) {
    print('Error accepting friend request: $e');
  }
}

void showSuccessSnackBarr(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: Colors.green,
  ));
}

void showErrorSnackBarr(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: Colors.red,
  ));
}

class ShowProfilePicture extends StatelessWidget {
  final Uint8List? image;
  final String initial;
  final double size;

  const ShowProfilePicture(
      {super.key,
      required this.image,
      required this.initial,
      required this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => image != null
          ? showDialog(
              context: context,
              builder: (context) => Animate(
                effects: [FadeEffect()],
                child: AlertDialog(
                  content: Image.memory(
                    image!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            )
          : null,
      child: CircleAvatar(
        radius: size,
        backgroundImage: image != null ? Image.memory(image!).image : null,
        //backgroundColor:
        // Colors.grey,
        child: image == null
            ? Text(
                initial.toUpperCase(),
                style: TextStyle(fontSize: size * 0.8),
              )
            : null,
      ),
    );
  }
}

class TransactionListWidget extends StatefulWidget {
  final int userId;
  final String friendUsername;
  final int friendId;
  const TransactionListWidget(
      {Key? key,
      required this.userId,
      required this.friendId,
      required this.friendUsername})
      : super(key: key);

  @override
  _TransactionListWidgetState createState() => _TransactionListWidgetState();
}

class _TransactionListWidgetState extends State<TransactionListWidget> {
  late Future<List<Transaction>> transactionsFuture;
  List<Transaction> allTransactions = [];

  @override
  void initState() {
    super.initState();
    transactionsFuture = fetchTransactions();
  }

  Future<List<Transaction>> fetchTransactions() async {
    // Fetch and process transactions just like in TransactionHistoryScreen
    try {
      // Retrieve the user's authentication token from secure storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      // Handle the case where the token is not available
      if (token == null) {
        throw Exception('Token not found');
      }

      // Make an HTTP GET request to fetch transactions
      final response = await http.get(
        Uri.parse('${ApiService.serverUrl}/transactions'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the JSON response and create a list of Transaction objects
        final List<dynamic> data = json.decode(response.body);
        final List<dynamic> transactionsData = data[0];
        List<Transaction> transactions =
            transactionsData.map((transactionData) {
          return Transaction.fromJson(transactionData as Map<String, dynamic>);
        }).toList();

        // Sort transactions in descending order based on the createdAt field
        transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Filter transactions to only include those involving the friend
        transactions = transactions.where((transaction) {
          return transaction.senderId == widget.friendId ||
              transaction.receiverId == widget.friendId;
        }).toList();
        return transactions;
      } else {
        // Handle errors if the request is not successful
        throw Exception(
            'Error fetching transactions. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle errors if the request fails
      throw Exception('Error fetching transactions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Transaction>>(
      future: transactionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No transactions found.'));
        } else {
          // Save all transactions for reference
          allTransactions = snapshot.data!;
          return ListView.builder(
            itemCount: allTransactions.length,
            itemBuilder: (context, index) {
              return TransactionItem(
                transaction: allTransactions[index],
                userId: widget.userId,
                username: widget.friendUsername,
              );
            },
          );
        }
      },
    );
  }
}
