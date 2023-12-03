import 'dart:convert';
import 'dart:ffi';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String serverUrl = 'http://10.0.2.2:3000';
  //static const String serverUrl = 'http://localhost:3000';
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

  // async function to fetch the user_id from the flutter secure storage
  static Future<String> fetchUserId() async {
    const storage = FlutterSecureStorage();
    final userId = await storage.read(key: 'user_id');
    print(userId);
    return userId!;
  }
}
