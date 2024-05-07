import 'package:camera/camera.dart';
import 'package:cookitup/admin/dashboard.dart';
import 'package:cookitup/form.dart';
import 'package:cookitup/profile.dart';
import 'package:cookitup/signUp.dart';
import 'package:cookitup/camera1.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'home.dart'; // Import home.dart file
import 'signIn.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDogvM669-5nP3D8LbZLcEzuptydL8ac24",
      authDomain: "cookitup-23ba5.firebaseapp.com",
      databaseURL: "https://cookitup-23ba5-default-rtdb.firebaseio.com",
      projectId: "cookitup-23ba5",
      storageBucket: "cookitup-23ba5.appspot.com",
      messagingSenderId: "176953686036",
      appId: "1:176953686036:web:f441fe9f06a8ff0ab88f01",
      measurementId: "G-VJYLLY53GX"
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(),
            routes: {
        '/signin': (context) => SignInPage(), 
        '/home':(content)=>Home(),
        '/admin':(context)=>AdminDashboardPage(),
            }
    );
  }
}



class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Add any loading animation or logic here
    // For simplicity, we'll navigate to Home after 2 seconds
    Future.delayed(Duration(seconds: 2), () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      //await prefs.setBool('loggedIn', false);
      bool loggedIn = prefs.getBool('loggedIn') ?? false;
      bool adminloggedIn = prefs.getBool('adminloggedIn') ?? false;
      print(adminloggedIn);
      print(loggedIn);
      if (adminloggedIn) {
        Navigator.pushNamed(context, '/admin');
      } else if(loggedIn){
         Navigator.pushNamed(context, '/home');
      }
      else {
        Navigator.pushNamed(context, '/signin');
      }
    });

    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/CookItUpbg.png',
          height: 500,
          width: 900,
        ),
      ),
    );
  }
}

