import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_travel_helper/view/map_view.dart';
import 'package:flutter_travel_helper/login/singup.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int _success = 1;
  // late String _userEmail;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _emailController.text = "abc@gmail.com";
      _passwordController.text = "111111";
    }
  }

  void _signIn() async {
    setState(() {
      _success = 1; // Reset _success to 1 before making a new sign-in attempt
    });

    try {
      final User? user = (await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      ))
          .user;

      if (user != null) {
        setState(() {
          _success = 2;
          // _userEmail = user.email!;
        });

        // Navigate to MapView after successful login
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MapView()),
        );
      } else {
        setState(() {
          _success = 3;
        });
      }
    } catch (e) {
      print("Sign in failed: $e");
      setState(() {
        _success = 3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                ),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
              ),
              ElevatedButton(
                onPressed: _signIn,
                child: Text('Sign In'),
              ),
              if (_success == 3) Text('Sign in failed'),
              SizedBox(height: 20), // Add spacing between buttons
              ElevatedButton(
                onPressed: () {
                  // Navigate to signup page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SingupPage()), // Replace SignupPage with your signup page widget
                  );
                },
                child: Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
