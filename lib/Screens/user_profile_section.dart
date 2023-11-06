import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class UserProfileSection extends StatelessWidget {
  final String username;
  final Map<String, dynamic> picture;

  const UserProfileSection(this.username, this.picture, {super.key});

  @override
  Widget build(BuildContext context) {
    Image image;
    if (picture != null && picture.containsKey("imageData")) {
      final Uint8List imageBytes = base64Decode(picture["imageData"]);
      final ImageProvider<Object> userImage = MemoryImage(imageBytes);
      image = userImage as Image;
    } else {
      // Use a fallback image if the image data is not available in the JSON data
      image = Image.asset(
        "lib/assets/profile_image.png",
        width: 40,
        height: 40,
      );
    }
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
