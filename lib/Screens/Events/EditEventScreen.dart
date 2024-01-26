import 'dart:convert';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Dashboard/appDrawer.dart';
import 'package:flutter_application_1/Screens/Dashboard/dashBoardScreen.dart';
import 'package:flutter_application_1/Screens/Events/Event.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import '../api_service.dart';

/*
 Recurrence Type
 None = 0
 Weekly = 1
 Monthly = 2
 Yearly = 3
*/

class EditEventScreen extends StatefulWidget {
  Event event;
  EditEventScreen({super.key, required this.event});

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  var selectedCategory;
  var selectedCountry;
  var selectedMaxParticipants;
  var selectedTimestamp;
  var unixTimestamp;
  var displayTimestamp;

  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController maxParticipantsController;
  late TextEditingController cityController;
  late TextEditingController streetController;
  late TextEditingController zipcodeController;
  late TextEditingController priceController;

  Color countryButton = Colors.white;
  Color datetimeButton = Colors.white;
  Color priceBorder = Colors.white;
  Color wrongDate = Colors.black;

  String? title;
  String? description;
  String? maxParticipants;
  String? city;
  String? street;
  String? zipcode;
  String? price;

  String? titleError;
  String? descriptionError;
  String? maxParticipantsError;
  String? cityError;
  String? streetError;
  String? zipcodeError;
  String? priceError;

  bool? weekly;
  bool? monthly;
  bool? yearly;

  bool countryButtonUsed = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.event.title);
    descriptionController =
        TextEditingController(text: widget.event.description);
    maxParticipantsController =
        TextEditingController(text: widget.event.maxParticipants.toString());
    cityController = TextEditingController(text: widget.event.city);
    streetController = TextEditingController(text: widget.event.street);
    zipcodeController = TextEditingController(text: widget.event.zipcode);
    priceController =
        TextEditingController(text: widget.event.price.toString());

    selectedTimestamp = widget.event.datetimeEvent;
    selectedCategory = widget.event.category;
    selectedCountry = widget.event.country;
    selectedMaxParticipants = widget.event.maxParticipants;
    int? recurrenceType = widget.event.recurrenceType;

    if (recurrenceType == 1) {
      weekly = true;
    } else if (recurrenceType == 2) {
      monthly = true;
    } else if (recurrenceType == 3) {
      yearly = true;
    } else {
      recurrenceType = 0;
    }
  }

  void clearErrors() {
    // Clear any previous error messages
    setState(() {
      titleError = null;
      descriptionError = null;
      maxParticipantsError = null;
      cityError = null;
      streetError = null;
      zipcodeError = null;
      priceError = null;
    });
  }

  Future<DateTime?> showDateTimePicker({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    initialDate ??= DateTime.now();
    firstDate ??= DateTime.now();
    lastDate ??= firstDate.add(const Duration(days: 365 * 200));

    final DateTime? selectedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate);

    if (selectedDate == null) return null;

    if (!context.mounted) return selectedDate;

    final TimeOfDay? selectedTime = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(selectedDate));

    setState(() {
      datetimeButton = Colors.blue;
    });

    selectedTime == null;
    selectedTimestamp = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, selectedTime!.hour, selectedTime.minute);

    unixTimestamp = selectedTimestamp.toString();
    unixTimestamp = DateTime.parse(unixTimestamp).millisecondsSinceEpoch;

    displayTimestamp = selectedTimestamp.toString().substring(0, 16);

    return selectedTime == null
        ? selectedDate
        : DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
            selectedTime.hour, selectedTime.minute);
  }

  Future<void> handleEditEvent() async {
    // Error cleaning
    clearErrors();

    final String title = titleController.text;
    final String description = descriptionController.text;
    String? city = cityController.text;
    String? street = streetController.text;
    String? zipcode = zipcodeController.text;
    final String price = priceController.text;
    int recurrenceType;

    try {
      if (unixTimestamp == null || unixTimestamp == '') {
        setState(() {
          datetimeButton = Colors.red;
        });

        showErrorSnackBar(this.context, 'Please pick date and time');

        return;
      }

      if (unixTimestamp < DateTime.now().millisecondsSinceEpoch) {
        setState(() {
          datetimeButton = Colors.red;
          wrongDate = Colors.red;
        });

        showErrorSnackBar(
            this.context, 'The time the event starts cannot be in the past');

        return;
      } else {
        setState(() {
          datetimeButton = Colors.blue;
          wrongDate = Colors.grey;
        });
      }
    } catch (e) {
      print("error {$e}");
    }

    // Remove euro sign, periods and spaces
    final cleanedAmountText =
        price.replaceAll('€', '').replaceAll(' ', '').replaceAll('.', '');

    // Replace commas with periods
    final normalizedAmountText = cleanedAmountText.replaceAll(',', '.');

    // Parse the amount
    final parsedPrice = double.tryParse(normalizedAmountText) ?? 0.0;

    if (title.trim().isEmpty) {
      setState(() {
        titleError = 'Event title cannot be empty';
      });
    }

    if (description.trim().isEmpty) {
      setState(() {
        descriptionError = 'Please enter a brief description';
      });
    }

    if (weekly == true) {
      recurrenceType = 1;
    } else if (monthly == true) {
      recurrenceType = 2;
    } else if (yearly == true) {
      recurrenceType = 3;
    } else {
      recurrenceType = 0;
    }

    // Start for request
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      if (kDebugMode) {
        print('JWT token not found.');
      }
      return;
    }
    if (kDebugMode) {
      print('token: $token');
    }

    print(selectedTimestamp);

    final editEventResponse =
        await http.post(Uri.parse('${ApiService.serverUrl}/edit-event'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(<String, dynamic>{
              'eventID': widget.event.eventID,
              'category': selectedCategory,
              'title': title,
              'description': description,
              'max_participants': selectedMaxParticipants,
              'datetime_event': selectedTimestamp.toString(),
              'country': selectedCountry,
              'city': city,
              'street': street,
              'zipcode': zipcode,
              'price': parsedPrice,
              'recurrence_type': recurrenceType
            }));

    print(editEventResponse);

    if (editEventResponse.statusCode == 200) {
      Navigator.push(
        this.context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else if (editEventResponse.statusCode == 401) {
      setState(() {
        selectedCountry = '';
        countryButton = Colors.red;
        cityError = 'The address does not exist';
        streetError = ' ';
        zipcodeError = ' ';
      });

      print('The address does not exist');
      return;
    } else {
      print('Error creating the event: ${editEventResponse.body}');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> categories = <String>[
      'Book and Literature',
      'Cultural and Arts',
      'Community',
      'Enviromental',
      'Fashion',
      'Film and Entertainment',
      'Food and Drink',
      'Gaming',
      'Health and Wellness',
      'Science',
      'Sport',
      'Technology and Innovation',
      'Travel and Adventure',
      'Professional'
    ];

    return Scaffold(
      drawer: FutureBuilder<Map<String, dynamic>>(
        future: ApiService
            .fetchUserProfile(), // Replace with your actual method to fetch user data
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
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 16.0),
              const Text(
                'Event information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              DropdownMenu<String>(
                initialSelection: selectedCategory, //categories.first,
                hintText: 'Categories',
                requestFocusOnTap: false,
                onSelected: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue!;
                  });
                },
                dropdownMenuEntries:
                    categories.map<DropdownMenuEntry<String>>((String value) {
                  return DropdownMenuEntry<String>(value: value, label: value);
                }).toList(),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Event title',
                  border: OutlineInputBorder(),
                  errorText: titleError,
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    errorText: descriptionError),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: datetimeButton, // Button background color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 35, vertical: 16),
                  ),
                  onPressed: () {
                    showDateTimePicker(context: context);
                  },
                  child: const Text('Pick Date and Time')),
              const SizedBox(height: 16.0),
              Column(
                children: [
                  if (selectedTimestamp != null)
                    Text('$displayTimestamp',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: wrongDate)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 8, thickness: 2),
              const SizedBox(height: 16),
              const Text('Maximal number of participants',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              NumberPicker(
                  minValue: 1,
                  maxValue: 100,
                  value: selectedMaxParticipants,
                  onChanged: (value) =>
                      (setState(() => selectedMaxParticipants = value))),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () => setState(() {
                      final newValue = selectedMaxParticipants - 1;
                      selectedMaxParticipants = newValue.clamp(1, 100);
                    }),
                  ),
                  Text('Participants: $selectedMaxParticipants',
                      style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () => setState(() {
                      final newValue = selectedMaxParticipants + 1;
                      selectedMaxParticipants = newValue.clamp(1, 100);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 21),
              const Divider(height: 8, thickness: 2),
              const SizedBox(height: 21),
              const Text(
                'Location (optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: countryButton, // Button background color
                  padding:
                      const EdgeInsets.symmetric(horizontal: 35, vertical: 16),
                ),
                onPressed: () {
                  showCountryPicker(
                    context: context,
                    showPhoneCode: false,
                    onSelect: (Country country) {
                      selectedCountry = country.name;

                      setState(() {
                        countryButton = Colors.blue;
                      });
                    },
                  );
                },
                child: const Text('Pick Country'),
              ),
              const SizedBox(height: 16.0),
              if (selectedCountry != '')
                Text(
                  '$selectedCountry',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                ),
              const SizedBox(height: 24.0),
              TextFormField(
                controller: cityController,
                decoration: InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                    errorText: cityError),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: streetController,
                decoration: InputDecoration(
                    labelText: 'Street',
                    border: OutlineInputBorder(),
                    errorText: streetError),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: zipcodeController,
                decoration: InputDecoration(
                    labelText: 'Zipcode',
                    border: OutlineInputBorder(),
                    errorText: zipcodeError),
              ),
              const SizedBox(height: 16),
              const Divider(height: 8, thickness: 2),
              const SizedBox(height: 16),
              Text(
                'Price',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: priceController,
                decoration: InputDecoration(
                    hintText: '0,00 €', // Initial value
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monetization_on),
                    errorText: priceError),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true), // Allow decimals
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    // Remove any non-numeric characters
                    final cleanedValue =
                        value.replaceAll(RegExp(r'[^0-9]'), '');

                    // Convert the cleaned value to an integer
                    final intValue = int.tryParse(cleanedValue) ?? 0;

                    // Format the integer as a currency value with the correct pattern
                    final formattedPrice = NumberFormat.currency(
                      decimalDigits: 2,
                      symbol: '€', // Euro sign
                      locale: 'de_DE', // German locale for correct separators
                    ).format(intValue / 100);

                    priceController.text = formattedPrice;
                  }
                },
              ),
              const SizedBox(height: 16),
              const Divider(height: 8, thickness: 2),
              const SizedBox(height: 16),
              Text(
                'Repeatable Event',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              CheckboxListTile(
                value: weekly ?? false,
                onChanged: (bool? value) {
                  setState(() {
                    weekly = value ?? false;
                    monthly = false;
                    yearly = false;
                  });
                },
                title: const Text('Weekly'),
              ),
              const Divider(height: 0, thickness: 1),
              CheckboxListTile(
                value: monthly ?? false,
                onChanged: (bool? value) {
                  setState(() {
                    monthly = value ?? false;
                    weekly = false;
                    yearly = false;
                  });
                },
                title: const Text('Monthly'),
              ),
              const Divider(height: 0, thickness: 1),
              CheckboxListTile(
                value: yearly ?? false,
                onChanged: (bool? value) {
                  setState(() {
                    yearly = value ?? false;
                    weekly = false;
                    monthly = false;
                  });
                },
                title: const Text('Yearly'),
              ),
              const SizedBox(height: 40.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button background color
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                onPressed: handleEditEvent,
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.white, // Button text color
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ),
  );
}

void showSnackBar({bool isError = false, required String message}) {
  ScaffoldMessenger.of(context as BuildContext).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ),
  );
}
