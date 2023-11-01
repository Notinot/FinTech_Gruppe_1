import 'package:flutter/material.dart';

class UserProfileSection extends StatelessWidget {
  final String username; // Replace with actual user data

  UserProfileSection(this.username);

  @override
  Widget build(BuildContext context) {
    AssetImage userImage = AssetImage('lib/assets/profile_img.png');
    Image image;
    try {
      image = Image(image: userImage);
    } catch (e) {
      image = Image.asset(
        'assets/default_profile_icon.png', // Use a generic icon as a fallback
        width: 40, // Adjust the size as needed
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
        SizedBox(height: 16),
        Text(
          'Welcome, $username',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
