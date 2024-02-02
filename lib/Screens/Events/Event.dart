import 'dart:convert';
import 'dart:developer';
import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;



/*
Status Overview
Event Status:
0 -> Canceled
1 -> Active
2 -> Event Time pasted

User_Event Status:
0 -> Leaved
1 -> Joined
2 -> Pending (received invite)
*/

class Event {

  final int eventID;
  final String title;
  final String category;
  final String description;
  final int participants;
  final int maxParticipants;
  DateTime datetimeCreated;
  DateTime datetimeEvent;
  final double price;
  final int status;
  int recurrenceType;
  int recurrenceInterval;
  String? country;
  String? street;
  String? city;
  String? zipcode;
  final creatorUsername;
  final creatorId;
  bool isCreator;
  int user_event_status;

  Event({
    required this.eventID,
    required this.title,
    required this.description,
    required this.category,
    required this.participants,
    required this.maxParticipants,
    required this.datetimeCreated,
    required this.datetimeEvent,
    required this.price,
    required this.status,
    required this.recurrenceType,
    required this.recurrenceInterval,
    required this.country,
    required this.city,
    required this.street,
    required this.zipcode,
    required this.creatorUsername,
    required this.creatorId,
    required this.isCreator,
    required this.user_event_status
  });

  final Map<String, IconData> iconMap = {
    'Book and Literature': Icons.menu_book_rounded,
    'Cultural and Arts': Icons.panorama,
    'Community': Icons.people_rounded,
    'Enviromental': Icons.park_rounded,
    'Fashion': Icons.local_mall_rounded,
    'Film and Entertainment': Icons.movie_creation_rounded,
    'Food and Drink': Icons.restaurant,
    'Gaming': Icons.sports_esports_rounded,
    'Health and Wellness': Icons.health_and_safety_rounded,
    'Science': Icons.science_rounded,
    'Sport': Icons.sports_martial_arts_rounded,
    'Technology and Innovation': Icons.biotech_outlined,
    'Travel and Adventure': Icons.travel_explore_rounded,
    'Professional': Icons.business_center_rounded,
  };


  IconData getIconForCategory(String category) {
    // Check if the category exists in the map, otherwise use a default icon
    if (status != 1) {
      return Icons.do_disturb;
    } else if (datetimeEvent.millisecondsSinceEpoch <
        DateTime.now().millisecondsSinceEpoch) {
      return Icons.update_disabled_rounded;
    }
    else if(status == 1 && !isCreator && user_event_status == 2 && participants >= maxParticipants){
      return Icons.disabled_visible_rounded;
    }
    else{
      return iconMap.containsKey(category) ? iconMap[category]! : Icons.category;
    }
  }


  Future<void> checkIfCreator() async {

    String userId = await ApiService.fetchUserId();
    if(creatorId.toString() == userId){
      isCreator = true;
    }
  }

  bool notOutDatedEvent(DateTime eventTime) {
    if (eventTime.millisecondsSinceEpoch >
        DateTime.now().millisecondsSinceEpoch) {
      return true;
    }
    return false;
  }

  bool notFullEvent() {
    if (participants < maxParticipants) {
      return true;
    }
    return false;
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventID: json['event_id'],
      category: json['category'],
      title: json['title'],
      description: json['description'],
      participants: json['participants'],
      maxParticipants: json['max_participants'],
      datetimeCreated: DateTime.parse(json['datetime_created']).add(Duration(hours: 1)),
      datetimeEvent: DateTime.parse(json['datetime_event']).add(Duration(hours: 1)),
      price: (json['price'] as num).toDouble(),
      status: json['status'],
      recurrenceType: json['recurrence_type'],
      recurrenceInterval: json['recurrence_interval'],
      country: json['country'],
      city: json['city'],
      street: json['street'],
      zipcode: json['zipcode'],
      creatorUsername: json['creator_username'],
      creatorId: json['creator_id'],
      user_event_status: json['user_event_status'],
      isCreator: false,
    );
  }

  static Future<void> eventService(List<Event> events) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token not found');
      }

      List<Event> checkingEvents = [];
      List<Event> restartingEventsWithoutMoney = [];
      List<Event> restartingEventsWithMoney = [];

      // Get all repeatable Events
      for (var event in events) {
        if (event.recurrenceType > 0 && event.status > 0 && !checkingEvents.contains(event) ) {
          checkingEvents.add(event);
        }
      }


      for (var event in checkingEvents) {

        if (event.datetimeEvent.compareTo(DateTime.now().add(Duration(hours: 1))) < 0) {
          switch (event.recurrenceType) {
            case 1:
              event.datetimeEvent =
                  event.datetimeEvent.add(Duration(days: 7));
              event.recurrenceInterval = (event.recurrenceInterval + 1)!;
              if(event.price == 0 && !restartingEventsWithoutMoney.contains(event)){
                restartingEventsWithoutMoney.add(event);
              } else if(event.price > 0 && !restartingEventsWithMoney.contains(event)){
                restartingEventsWithMoney.add(event);
              }
            case 2:
            // Needs to be improved
              event.datetimeEvent =
                  event.datetimeEvent.add(Duration(days: 30));
              event.recurrenceInterval = (event.recurrenceInterval + 1)!;
              if(event.price == 0 && !restartingEventsWithoutMoney.contains(event)){
                restartingEventsWithoutMoney.add(event);
              } else if(event.price > 0 && !restartingEventsWithMoney.contains(event)){
                restartingEventsWithMoney.add(event);
              }
            case 3:
              event.datetimeEvent =
                  event.datetimeEvent.add(Duration(days: 365));
              event.recurrenceInterval = (event.recurrenceInterval + 1)!;
              if(event.price == 0 && !restartingEventsWithoutMoney.contains(event)){
                restartingEventsWithoutMoney.add(event);
              } else if(event.price > 0 && !restartingEventsWithMoney.contains(event)){
                restartingEventsWithMoney.add(event);
              }
          }
        }
      }


      // Send Request without money
      if(restartingEventsWithoutMoney.length > 0){

        List<Map<String, dynamic>> eventsJson =
        restartingEventsWithoutMoney.map((i) => i.toJson()).toList();

        String body = jsonEncode(eventsJson);
        ApiService.EventService(body);
      }

      // Send Request with money
      if(restartingEventsWithMoney.length > 0){

        List<Map<String, dynamic>> eventsJson =
        restartingEventsWithMoney.map((i) => i.toJson()).toList();

        String body = jsonEncode(eventsJson);
        ApiService.EventService(body);


        for(var event in restartingEventsWithMoney){
          try{

            List<String> participantsList = await ApiService.fetchParticipants(event.eventID, 1);

            for(var participant in participantsList){

              final sendMoneyResponse = await http.post(
                Uri.parse('${ApiService.serverUrl}/send-money'),
                headers: {
                  'Content-Type': 'application/json; charset=UTF-8',
                  'Authorization': 'Bearer $token',
                },
                body: json.encode(<String, dynamic>{
                  'recipient': participant,
                  'amount': event.price,
                  'message': event.title,
                  'event_id': event.eventID.toString(),
                }),
              );

              if (sendMoneyResponse.statusCode == 200) {
                // Money sent successfully
                print('Sending money was successful');
              } else if (sendMoneyResponse.statusCode == 400) {
                // Participant has not enough money to pay again
                print('Participant has not enough money to pay again');
                // Kick here
                ApiService.kickParticipant(event.eventID, participant);
              }
            }
          }catch(err){
            print(err);
            rethrow;
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': this.eventID,
      'datetime_event': this.datetimeEvent.toString().substring(
          0, this.datetimeEvent.toString().length - 5), // U
      // set UTC time
      'recurrence_interval': this.recurrenceInterval,
    };
  }
}