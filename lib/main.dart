import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_travel_helper/bloc/auto_complete/auto_complete_bloc.dart';
import 'package:flutter_travel_helper/bloc/marker/marker_cubit.dart';
import 'package:flutter_travel_helper/repository/place_search_service.dart';
import 'package:flutter_travel_helper/view/map_view.dart';
import 'package:flutter_travel_helper/login/main_page.dart'; // Assuming your login page is in main_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAX_W5NfJ6OM8fJR29PI297LgVwQgTvwdo", // paste your api key here
      appId: "1:515016846317:android:1467e42fa4a26bd2e955e4", //paste your app id here
      messagingSenderId: "515016846317", //paste your messagingSenderId here
      projectId: "loginsingup-d4f93", //paste your project id here
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final placeSearchService = PlaceSearchService();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => MarkerCubit(placeSearchService: placeSearchService),
        ),
        BlocProvider(
          create: (_) => AutoCompleteBloc(placeSearchService: placeSearchService),
        ),
      ],
      child: MaterialApp(
        title: 'Your App Title',
        theme: ThemeData(
            // Your theme data
            ),
        home: LoginPage(), // Start with the login page
      ),
    );
  }
}
