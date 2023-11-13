import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FriendsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const FriendsScreen({super.key, required this.user});

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<Map<String, dynamic>> friendData = []; // List to store friend data

  @override
  void initState() {
    super.initState();
    final user_id = widget.user['user_id'];
    fetchData(user_id);
  }

  Future<void> fetchData(int userId) async {
    try {
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
