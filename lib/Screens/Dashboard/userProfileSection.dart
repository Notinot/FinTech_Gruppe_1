import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/EditUser/EditUserScreen.dart';
import 'package:flutter_application_1/Screens/api_service.dart';

class UserProfileSection extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserProfileSection(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    Image image;

    void handleCircleAvatarTap() {
      // Handle the button click event here
      ApiService.navigateWithAnimation(context, EditUser());
      // Add your navigation or other logic as needed
    }

    // Use a fallback image if the image data is not available in the JSON data
    image = Image.asset(
      "lib/assets/profile_image.png",
      width: 40,
      height: 40,
    );

    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: handleCircleAvatarTap,
          child: CircleAvatar(
            backgroundImage: user['picture'] != null &&
                    user['picture'] is Map<String, dynamic> &&
                    user['picture']['data'] != null
                ? MemoryImage(
                    Uint8List.fromList(user['picture']['data'].cast<int>()))
                : image.image,
            radius: 50,
            //   backgroundColor: Colors.grey, // Fallback background color
            //   backgroundColor: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome, ' + user['username'],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
