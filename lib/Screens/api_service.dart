import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String serverUrl = 'http://10.0.2.2:3000';
  // static const String serverUrl = 'http://localhost:3000';
  // const serverUrl = '192.168.56.1:3000';

  static Future<Map<String, dynamic>> fetchUserProfile() async {
    // Retrieve the token from secure storage
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      throw Exception('Token not found');
    }

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
  Future<String> fetchUsername(int senderId) async {
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
        final double balance = data['balance'];
        return balance;
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      print('fetchUserBalance: Error fetching data: $e');
      return 0;
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
  static Future<bool> checkIfFriends(int userId) async {
    print("APIService: checkIfFriends: userId = $userId");
    try {
      // Retrieve the token from secure storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.post(
        Uri.parse('${ApiService.serverUrl}/checkIfFriends'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(<String, dynamic>{
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final bool isFriend = data['isFriend'];
        return isFriend;
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      print('checkIfFriends function: Error fetching data: $e');
      return false;
    }
  }
}
