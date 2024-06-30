import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Navigationdrawer extends StatelessWidget {
  const Navigationdrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            buildHeader(context, user),
            buildMenuItems(context),
          ],
        ),
      ),
    );
  }

  Widget buildHeader(BuildContext context, User? user) => Container(
    padding: EdgeInsets.all(16),
    color: Theme.of(context).primaryColor,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Navigation Drawer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        SizedBox(height: 16),
        if (user != null) ...[
          Text(
            'Logged in as:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          Text(
            user.email ?? 'No Email',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login'); // Redirect to login page after logout
            },
            icon: Icon(Icons.logout, color: Colors.white),
            label: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ],
    ),
  );

  Widget buildMenuItems(BuildContext context) => Column(
    children: [
      ListTile(
        leading: const Icon(Icons.restaurant),
        title: const Text('Nearby Restaurants'),
        onTap: () {
          // Handle tap event
          Navigator.pop(context); // Close the drawer
        },
      ),
      ListTile(
        leading: const Icon(Icons.park),
        title: const Text('Nearby Parks'),
        onTap: () {
          // Handle tap event
          Navigator.pop(context); // Close the drawer
        },
      ),
      ListTile(
        leading: const Icon(Icons.local_mall),
        title: const Text('Nearby Malls'),
        onTap: () {
          // Handle tap event
          Navigator.pop(context); // Close the drawer
        },
      ),
      // Add more ListTile for other options if needed
    ],
  );
}
