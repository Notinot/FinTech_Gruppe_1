import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class CreateEventScreen extends StatefulWidget {

  CreateEventScreen({super.key});

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {

  var selectedCat = 'Book and Literature';
  var selectedCountry = '';

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController maxParticipantsController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController zipcodeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  Color countryButton = Colors.grey;
  Color titleBorder = Colors.grey;
  Color descriptionBorder = Colors.grey;
  Color priceBorder = Colors.grey;
  Color maxParticipantBorder = Colors.grey;
  Color cityBorder = Colors.grey;
  Color streetBorder = Colors.grey;
  Color zipcodeBorder = Colors.grey;

  String? title;
  String? description;
  String? maxParticipants;
  String? city;
  String? street;
  String? zipcode;
  String? price;

  bool countryButtonUsed = false;

  Future<void> handleCreateEvent() async {

    final String title = titleController.text;
    final String description = descriptionController.text;
    final String maxParticipants = maxParticipantsController.text;
    final String city = cityController.text;
    final String street = streetController.text;
    final String zipcode = zipcodeController.text;
    final String price = priceController.text;


    // Remove euro sign, periods and spaces
    final cleanedAmountText = price
        .replaceAll('€', '')
        .replaceAll(' ', '')
        .replaceAll('.', '');

    // Replace commas with periods
    final normalizedAmountText =
    cleanedAmountText.replaceAll(',', '.');

    // Parse the amount
    final parsedPrice =
        double.tryParse(normalizedAmountText) ?? 0.0;

    if(title.trim().isEmpty){

    }

    if(maxParticipants.trim().isEmpty){

    }

    if(city.trim().isEmpty){

    }

    if(street.trim().isEmpty){

    }

    if(zipcode.trim().isEmpty){

    }

    if(selectedCountry == ''){

      setState(() {
        countryButton = Colors.red;
      });
      showErrorSnackBar(context, 'Select a Country');
    }

    if (parsedPrice <= 0) {
      /*
      setState(() {
        amountBorderColor = Colors.red;
      });

       */
      showErrorSnackBar(context, 'Enter a valid amount');
      return;
    }

    return;
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
      body:  SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 16.0),
              const Text(
                'Event details',
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
                dropdownMenuEntries: categories.map<DropdownMenuEntry<String>>((String value) {
                  return DropdownMenuEntry<String>(value: value, label: value);
                }).toList(),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Event title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: maxParticipantsController,
                decoration: const InputDecoration(
                  labelText: 'Maximal participants',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32.0),
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
                      showSuccessSnackBar(
                      context, 'Country: $selectedCountry');

                      setState(() {
                        countryButton = Colors.blue;
                      });
                    },
                  );
                },
                child: const Text('Select Country'),
              ),
              const SizedBox(height: 12.0),
              Text(
                'Currently chosen: $selectedCountry',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: streetController,
                decoration: const InputDecoration(
                  labelText: 'Street',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: zipcodeController,
                decoration: const InputDecoration(
                  labelText: 'Zipcode',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32.0),
              Text(
                'Price',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  hintText: '0,00 €', // Initial value
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true), // Allow decimals
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    // Remove any non-numeric characters
                    final cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');

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
              const SizedBox(height: 32.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button background color
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
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