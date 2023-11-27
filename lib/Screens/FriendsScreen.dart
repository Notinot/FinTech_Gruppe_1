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
  //get user profile via jwt
  //late Future<Map<String, dynamic>> user = ApiService.fetchUserProfile();
  List<Map<String, dynamic>> friendData = []; // List to store friend data

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    //get user information via JWT
    try {
      Map<String, dynamic> user = await ApiService.fetchUserProfile();
      final userId = user['user_id'];
      final response =
          await http.get(Uri.parse('http://localhost:3000/friends/$userId'));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        // Extract friend data from the response
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
}
