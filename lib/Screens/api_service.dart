import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String serverUrl = 'http://10.0.2.2:3000';
  //static const String serverUrl = 'http://localhost:3000';

  //static const serverUrl = '192.168.56.1:3000';
  //

  //static const String serverUrl = 'http://192.168.178.28:3000';

  //uni wlan
  // static const String serverUrl = 'http://10.53.135.55:3000';
  static Future<Map<String, dynamic>> fetchUserProfile() async {
    // Retrieve the token from secure storage
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      throw Exception('Token not found');
    }

    //print('FetchUserProfile() called');
    final response = await http.get(
      Uri.parse('${ApiService.serverUrl}/user/profile'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['user'];
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  //fetch username of the user
  static Future<String> fetchUsername(int senderId) async {
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
        Uri.parse('${ApiService.serverUrl}/user/profile'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the JSON response and create a list of Transaction objects
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> user = data['user'];
        return user['username'];
      } else {
        // Handle errors if the request is not successful
        throw Exception(
            'Error fetching transactions. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      rethrow;
    }
  }

  // async function to fetch the user_id from the flutter secure storage
  static Future<String> fetchUserId() async {
    const storage = FlutterSecureStorage();
    final userId = await storage.read(key: 'user_id');
    print("APIService: user id = " + userId.toString());
    return userId.toString();
  }

  static Future<int> getUserId() async {
    const storage = FlutterSecureStorage();
    final userId = await storage.read(key: 'user_id');
    print("APIService: user id = " + userId.toString());
    return int.parse(userId!);
  }

  //async function to check user password
  static Future<bool> checkUserPassword(String password) async {
    try {
      // Retrieve the token from secure storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.post(
        Uri.parse('${ApiService.serverUrl}/verifyPassword_Token'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(<String, dynamic>{
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final bool passwordCorrect = data['passwordCorrect'];
        return passwordCorrect;
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      print('checkUserPassword: Error fetching data: $e');
      return false;
    }
  }

  // async function to get the users balance with token
  static Future<double> fetchUserBalance() async {
    try {
      // Retrieve the token from secure storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.serverUrl}/balance'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final double balance = data['balance'].toDouble();
        return balance;
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      print('fetchUserBalance: Error fetching data: $e');
      return 0;
    }
  }

  static Future<String> fetchFriendUsername(int friendId) async {
    try {
      // Retrieve the user's authentication token from secure storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      // Handle the case where the token is not available
      if (token == null) {
        throw Exception('Token not found');
      }

      // Make an HTTP GET request to fetch transactions
      final response =
          await http.post(Uri.parse('${ApiService.serverUrl}/friendName'),
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(<String, dynamic>{
                'friend': friendId,
              }));

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the JSON response and create a list of Transaction objects
        final Map<String, dynamic> data = json.decode(response.body);
        return data['friendname'];
      } else {
        // Handle errors if the request is not successful
        throw Exception(
            'Error fetching transactions. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      rethrow;
    }
  }

  //async function to add money to the users account
  static Future<bool> addMoney(double amount) async {
    try {
      print("APIService: addMoney: amount = $amount");
      // Retrieve the token from secure storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.post(
        Uri.parse('${ApiService.serverUrl}/addMoney'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(<String, dynamic>{
          'amount': amount,
        }),
      );
      print("APIService: addMoney: response = $response");
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final bool success = data['success'];
        return success;
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      print('addMoney function: Error fetching data: $e');
      return false;
    }
  }

  //async function to check it user is already friends with another user. check with token and userId of other user
  static Future<bool> checkIfFriends(int friendId) async {
    print("APIService: checkIfFriends: userId = $friendId");
    try {
      // Retrieve the token from secure storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.serverUrl}/checkIfFriends?friendId=$friendId'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );
      print("APIService: checkIfFriends: response = $response");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("APIService: checkIfFriends: data = $data");
        return data['isFriend'] ?? false; // Safely handle potential null values
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('checkIfFriends function: Error fetching data: $e');
      return false;
    }
  }

  //async function to check it user is already friends with another user. check with token and userId of other user
  static Future<bool> addUserId(int friendId) async {
    print("APIService: addFriend: friendId = $friendId");
    try {
      // Retrieve the token from secure storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.post(
        Uri.parse('${ApiService.serverUrl}/addFriendId'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(<String, dynamic>{
          'friendId': friendId,
        }),
      );
      print("APIService: addFriend: response = $response");
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final bool success = data['success'];
        return success;
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      print('addFriend function: Error fetching data: $e');
      return false;
    }
  }

  static Future<Uint8List?> fetchProfilePicture(int userId) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.serverUrl}/profilePicture?userId=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['picture'] != null && data['picture']['data'] != null) {
          // Use the byte array from the 'data' field to create the Uint8List
          return Uint8List.fromList(data['picture']['data'].cast<int>());
        }
      } else {
        throw Exception('Failed to load profile picture');
      }
    } catch (e) {
      print('fetchProfilePicture function: Error fetching data: $e');
      return null;
    }
  }

  static Future<bool> EventService(String body) async {
    try {
      print("Starting EventService()");
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token not found');
      }

      final EventServiceResponse =
          await http.post(Uri.parse('${ApiService.serverUrl}/event-service'),
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization': 'Bearer $token',
              },
              body: body);

      if (EventServiceResponse.statusCode == 200) {
        print('EventService: Call was successful');

        return true;
      } else {
        print(EventServiceResponse.statusCode);
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }


  static Future<int> inviteEvent(int eventId, String recipient) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token not found');
      }

      final inviteEventResponse = await http.post(
        Uri.parse('${ApiService.serverUrl}/invite-event'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'eventId': eventId,
          'recipient': recipient,
        }),
      );

      if (inviteEventResponse.statusCode == 200) {
        print('inviteEvent function: Inviting to Event was successful');
        return 200;
      }

      if (inviteEventResponse.statusCode == 401) {
        print(
            'inviteEvent function: $recipient already interacted with the event');
        return 401;
      }

      if(inviteEventResponse.statusCode == 402){
        print(
            'inviteEvent function: $recipient does not exist');
        return 402;
      }

      print('inviteEvent function: Error inviting to Event');
      print('StatusCode: ${inviteEventResponse.statusCode}');
      return 400;
    } catch (e) {
      print('inviteEvent function error: $e');
      return 500;
    }
  }

  static Future<int> joinEvent(String recipientUsername,
      double amount, String message, int eventId) async {

    // Return Codes:
    // 200: success
    // 400: general failure
    // 401: event already joined
    // 402: payment failed

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token not found');
      }

      // Free Event
      if (amount == 0) {
        final joinEventResponse = await http.post(
          Uri.parse('${ApiService.serverUrl}/join-event'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'amount': amount.toString(),
            'message': message,
            'eventId': eventId.toString()
          }),
        );

        if (joinEventResponse.statusCode == 200) {
          print('joinEvent function: Joining Event was successful');
          return 200;
        }
      }


        // Event with costs
        if (amount > 0) {
          try {
            final sendMoneyResponse = await http.post(
              Uri.parse('${ApiService.serverUrl}/send-money'),
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(<String, dynamic>{
                'recipient': recipientUsername,
                'amount': amount,
                'message': message,
                'event_id': eventId.toString(),
              }),
            );

            if (sendMoneyResponse.statusCode == 200) {
              // Money sent successfully
              print('Sending money was successful');
              print('joinEvent function: Joining Event was successful');
              return 200;
            }
            else if (sendMoneyResponse.statusCode == 400) {
              print('Not enough money to join the event');
              return 402;
            }
          } catch (err) {
            print("joinEvent function: Error sending money: $err");
            rethrow;
          }
        }

        return 400;

      /*
      final joinEventResponse = await http.post(
        Uri.parse('${ApiService.serverUrl}/join-event'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount.toString(),
          'message': message,
          'eventId': eventId.toString()
        }),
      );

      if (joinEventResponse.statusCode == 200) {
        print("Joining Event Successful");

        if (amount > 0) {
          try {
            final sendMoneyResponse = await http.post(
              Uri.parse('${ApiService.serverUrl}/send-money'),
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(<String, dynamic>{
                'recipient': recipientUsername,
                'amount': amount,
                'message': message,
                'event_id': eventId.toString(),
              }),
            );

            if (sendMoneyResponse.statusCode == 200) {
              // Money sent successfully
              print('Sending money was successful');
              return 200;
            } else {

              // Money transfer failed, handle accordingly
              print('Error sending money: ${sendMoneyResponse.body}');
              return 402;
            }
          } catch (err) {
            print('joinEvent function: Error sending money $err');
            return 402;
          }
        } else {
          print('joinEvent function: Joining Event was successful');
          return 200;
        }
      }
      else if(joinEventResponse.statusCode == 401){
        return 401;
      }

      print(joinEventResponse.statusCode);
      print('joinEvent function: Error joining Event');
      return 400;

       */
    } catch (e) {
      print('joinEvent function: Error joining Event: $e');
      print(e);
      return 400;
    }
  }

  static Future<bool> kickParticipant(int eventId, String participantUsername) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token not found');
      }

      final kickParticipantResponse = await http.post(
          Uri.parse('${ApiService.serverUrl}/kick-participant?eventId=$eventId&participantUsername=$participantUsername'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          });

      if (kickParticipantResponse.statusCode == 200) {
        print('kickParticipant function: Participant successfully kicked from the event');
        return true;
      }

      print('kickParticipant function: Kicking participant failed');
      return false;

    } catch (e) {
      print('kickParticipant function: Kicking participant failed: $e');
      return false;
    }
  }

  static Future<int> leaveEvent(int eventId) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token not found');
      }

      final leaveEventResponse = await http.post(
          Uri.parse('${ApiService.serverUrl}/leave-event?eventId=$eventId'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          });

      if (leaveEventResponse.statusCode == 200) {
        print('leaveEvent function: Leaving Event was successful');
        return 1;
      }

      if (leaveEventResponse.statusCode == 401) {
        print('leaveEvent function: Event was already canceled');
        return 401;
      }

      print('leaveEvent function: Error leaving Event');
      return 0;
    } catch (e) {
      print('leaveEvent function: Error leaving Event');
      return 0;
    }
  }

  static Future<List<String>> fetchParticipants(int eventId, int type) async {
    try {

      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse(
            '${ApiService.serverUrl}/event-participants?eventId=$eventId&type=$type'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> participantsList = jsonDecode(response.body);

        // Explicitly cast each element to String
        final List<String> participants = participantsList
            .map((dynamic item) =>
            (item as Map<String, dynamic>)['username'].toString())
            .toList();

        return participants;
      } else {
        throw Exception(
            'Failed to load participants. Error: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching Participants");
      print(e);
      rethrow;
    }
  }

  static Future<int> cancelEvent(int eventId) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token not found');
      }

      Future<List<String>> fetchParticipantMails(int eventId, int type) async {
        try {
          const storage = FlutterSecureStorage();
          final token = await storage.read(key: 'token');

          if (token == null) {
            throw Exception('Token not found');
          }

          final response = await http.get(
            Uri.parse(
                '${ApiService.serverUrl}/event-participant-mails?eventId=$eventId&type=$type'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
          );

          if (response.statusCode == 200) {
            final List<dynamic> participantsList = jsonDecode(response.body);

            // Explicitly cast each element to String
            final List<String> participants = participantsList
                .map((dynamic item) =>
                (item as Map<String, dynamic>)['email'].toString())
                .toList();

            return participants;
          } else {
            throw Exception(
                'Failed to load participants. Error: ${response.statusCode}');
          }
        } catch (e) {
          print("Error fetching Participants");
          print(e);
          rethrow;
        }
      }

      // Fetch participant emails
      List<String> participants =
      await fetchParticipantMails(eventId, 1);

      final cancelEventResponse = await http.post(
          Uri.parse('${ApiService.serverUrl}/cancel-event'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'eventId': eventId,
            'participants' : participants
        }),
      );

      if (cancelEventResponse.statusCode == 200) {
        print('cancelEvent function: Canceling Event was successful');
        return 1;
      }

      if (cancelEventResponse.statusCode == 401) {
        print('cancelEvent function: Event was already canceled');
        return 401;
      }

      print('cancelEvent function: Error canceling Event');
      return 0;
    } catch (e) {
      print('cancelEvent function: Error canceling Event');
      return 0;
    }
  }

  static void navigateWithAnimation(
      BuildContext context, Widget destinationScreen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            destinationScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeInOutQuart;

          var slideTween = Tween(begin: Offset(0.0, 1.0), end: Offset.zero)
              .chain(CurveTween(curve: curve));

          var fadeTween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          var slideAnimation = animation.drive(slideTween);
          var fadeAnimation = animation.drive(fadeTween);

          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
