import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_search_bar/flutter_search_bar.dart' as search_bar;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EventOverview extends StatefulWidget {

  EventOverview({super.key});

  @override
  _EventOverviewState createState() => _EventOverviewState();
}

class _EventOverviewState extends State<EventOverview>{

  late Future<List<Event>> eventsFuture;
  List<Event> allEvents = [];

  Future<List<Event>> fetchEvents() async{

    try{
      // Retrieve the user's authentication token from secure storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      // Handle the case where the token is not available
      if (token == null) {
        throw Exception('Token not found');
      }

      // Make an HTTP GET request to fetch transactions
      final response = await http.get(
        Uri.parse('${ApiService.serverUrl}/events'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if(response.statusCode == 200){

        final List<dynamic> data = json.decode(response.body);
        final List<dynamic> eventsData = data[0];
        List<Event> events = eventsData.map((eventData) {
          return Event.fromJson(eventData as Map<String, dynamic>);
        }).toList();

        events.sort((a, b) => b.datetime_event.compareTo(a.datetime_event));

        return events;
      }
      else{
        // Handle errors if the request is not successful
        throw Exception(
            'Error fetching events. Status Code: ${response.statusCode}');
      }
    }
    catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SearchBar(),
      ),
      body: Center(
        child: Column(
          children: [

          ],
        )
      )
    );
  }


}

class Event {

  int id;
  String category;
  String title;
  String description;
  int max_participants;
  DateTime datetime_created;
  DateTime datetime_event;
  double price;
  bool status;
  int creator_id;

  Event({
    required this.id,
    required this.category,
    required this.title ,
    required this.description,
    required this.max_participants,
    required this.datetime_created,
    required this.datetime_event,
    required this.price,
    required this.status,
    required this.creator_id,
  });

  factory Event.fromJson(Map<String, dynamic> json){

    return Event(
        id: json['id'],
        category: json['category'],
        title: json['title'],
        description: json['description'],
        max_participants: json['max_participants'],
        datetime_created: json['datetime_created'],
        datetime_event: json['datetime_event'],
        price: json['price'],
        status: json['status'],
        creator_id: json['creator_id']
    );
  }

}