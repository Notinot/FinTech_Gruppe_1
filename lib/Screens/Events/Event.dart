import 'dart:convert';
import 'package:flutter_application_1/Screens/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';


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
  int? recurrenceType;
  int? recurrenceInterval;
  String? country;
  String? street;
  String? city;
  String? zipcode;
  final creatorUsername;
  final creatorId;
  bool isCreator;
  int? user_event_status;

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

    return iconMap.containsKey(category) ? iconMap[category]! : Icons.category;
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
      datetimeCreated: DateTime.parse(json['datetime_created']),
      datetimeEvent: DateTime.parse(json['datetime_event']),
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

      // Get all repeatable Events
      for (var event in events) {
        if (event.recurrenceType != 0 && !checkingEvents.contains(event)) {
          checkingEvents.add(event);
        }
      }

      for (var event in checkingEvents) {
        if (event.datetimeEvent.compareTo(DateTime.now()) < 0) {
          switch (event.recurrenceType) {
            case 1:
              event.datetimeEvent =
                  event.datetimeEvent.add(Duration(days: 7));
              event.recurrenceInterval = (event.recurrenceInterval! + 1)!;
            case 2:
            // Needs to be improved
              event.datetimeEvent =
                  event.datetimeEvent.add(Duration(days: 30));
              event.recurrenceInterval = (event.recurrenceInterval! + 1)!;
            case 3:
              event.datetimeEvent =
                  event.datetimeEvent.add(Duration(days: 365));
              event.recurrenceInterval = (event.recurrenceInterval! + 1)!;
          }
        }
      }

      try {
        List<Map<String, dynamic>> eventsJson =
        checkingEvents.map((i) => i.toJson()).toList();

        String body = jsonEncode(eventsJson);
        ApiService.EventService(body);

      } catch (e) {
        print(e);
      }

    } catch (e) {
      print(e.toString());
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': this.eventID,
      'datetime_event': this.datetimeEvent.toString().substring(
          0, this.datetimeEvent.toString().length - 5), // U
      // se UTC time
      'recurrence_interval': this.recurrenceInterval,
    };
  }
}