import 'dart:convert';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class CreateEventScreen extends StatefulWidget {
  CreateEventScreen({super.key});

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  var selectedCat = 'Book and Literature';
  var selectedCountry = '';
  var selectedMaxParticipants = 1;
  var selectedTimestamp;
  var unixTimestamp;
  var displayTimestamp;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController maxParticipantsController =
      TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController zipcodeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  Color countryButton = Colors.grey;
  Color datetimeButton = Colors.grey;
  Color priceBorder = Colors.grey;
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

  bool countryButtonUsed = false;

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

  Future<void> handleCreateEvent() async {
    // Error cleaning
    clearErrors();
    // datetimeButton = Colors.grey;
    // countryButton = Colors.grey;

    final String title = titleController.text;
    final String description = descriptionController.text;
    final String city = cityController.text;
    final String street = streetController.text;
    final String zipcode = zipcodeController.text;
    final String price = priceController.text;

    try {
      if (unixTimestamp == null || unixTimestamp == '') {
        setState(() {
          datetimeButton = Colors.red;
        });
      }

      if (unixTimestamp < DateTime.now().millisecondsSinceEpoch) {
        setState(() {
          datetimeButton = Colors.red;
          wrongDate = Colors.red;
        });
      }
    } catch (e) {
      print("error $e");
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

    if (city.trim().isEmpty) {
      setState(() {
        cityError = 'City cannot be empty';
      });
    }

    if (street.trim().isEmpty) {
      setState(() {
        streetError = 'Street cannot be empty';
      });
    }

    if (zipcode.trim().isEmpty) {
      setState(() {
        zipcodeError = 'Zipcode cannot be empty';
      });
    }

    if (selectedCountry == '') {
      setState(() {
        countryButton = Colors.red;
      });
      showErrorSnackBar(context as BuildContext, 'Select a Country');
    }

    if (parsedPrice <= 0) {
      setState(() {
        priceError = "Enter a valid price";
      });

      showErrorSnackBar(context as BuildContext, 'Enter a valid amount');
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

    final createEventResponse =
        await http.post(Uri.parse('http://localhost:3000/create-event'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(<String, dynamic>{
              'category': selectedCat,
              'title': title,
              'description': description,
              'max_participants': selectedMaxParticipants,
              'datetime_event': selectedTimestamp.toString(),
              'country': selectedCountry,
              'city': city,
              'street': street,
              'zipcode': zipcode,
              'price': parsedPrice
            }));

    print(createEventResponse);

    if (createEventResponse.statusCode == 200) {
      print('Event successfuly created');
      return;
    } else {
      print('Error creating the event: ${createEventResponse.body}');
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
                initialSelection: categories.first,
                hintText: 'Categories',
                onSelected: (String? newValue) {
                  setState(() {
                    selectedCat = newValue!;
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
              const SizedBox(height: 32.0),
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
              const SizedBox(height: 42.0),
              const Text(
                'Location',
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

                      /*
                      showSuccessSnackBar(
                      context, 'Country: $selectedCountry');
                      */

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
              const SizedBox(height: 32.0),
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
              const SizedBox(height: 40.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button background color
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                onPressed: handleCreateEvent,
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