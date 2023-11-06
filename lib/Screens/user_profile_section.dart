import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class UserProfileSection extends StatelessWidget {
  final String username;

  const UserProfileSection(this.username, {super.key});

  @override
  Widget build(BuildContext context) {
    Image image;

    // Use a fallback image if the image data is not available in the JSON data
    image = Image.asset(
      "lib/assets/profile_image.png",
      width: 40,
      height: 40,
    );

    return Column(
      children: <Widget>[
        CircleAvatar(
          backgroundImage: image.image,
          radius: 50,
          backgroundColor: Colors.grey, // Fallback background color
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome, $username',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
