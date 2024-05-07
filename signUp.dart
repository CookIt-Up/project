import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart'; // Import home.dart file
import 'signIn.dart';


class SignUpPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _signUpWithEmailAndPassword(String email, String password, String name,BuildContext context) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
     // await userCredential.user!.sendEmailVerification();

      // Add user data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(email).set({
        'password': password,
        'name' : name,
        'email':email,
      });// Call the function to add user data

      // Sign up successful, you can access user details using userCredential.user
      print('User signed up: ${userCredential.user!.uid}');

       SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        await prefs.setBool('loggedIn', true);
      // Navigate to home() method in home.dart
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Home(), // Navigate to main.dart
        ),
      );
    } catch (e) {
      // Handle sign up errors
      print(e);

      // Show error message to the user
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text(e.toString()),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> addUserToFirestore(String userId, String email) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'email': email,
        
        // You can add more user data fields here if needed
      });
      print('User data added to Firestore');
    } catch (e) {
      print('Error adding user to Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Get Started',
          style: TextStyle(
            color: Color(
              0xFF437D28,
            ), // Title text color changed to match provided color
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Name',
                style: TextStyle(
                  color: Color(0xFF437D28), // Text color changed to green
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200], // Container background color
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      border: InputBorder.none, // Remove the default border
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      // You can add validation logic here if needed
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
               Text(
                'Email',
                style: TextStyle(
                  color: Color(0xFF437D28), // Text color changed to green
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200], // Container background color
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      border: InputBorder.none, // Remove the default border
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      // You can add validation logic here if needed
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Password',
                style: TextStyle(
                  color: Color(0xFF437D28), // Text color changed to green
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200], // Container background color
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      border: InputBorder.none, // Remove the default border
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      // You can add validation logic here if needed
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
                            Text(
                'Confirm Password',
                style: TextStyle(
                  color: Color(0xFF437D28), // Text color changed to green
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200], // Container background color
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      hintText: 'Confirm your password',
                      border: InputBorder.none, // Remove the default border
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      // You can add validation logic here if needed
                    },
                  ),
                ),
              ),
              SizedBox(height: 20,),
              ElevatedButton(
                onPressed: () {
                  // Retrieve email and password from text fields
                  String email = emailController.text;
                  String password = passwordController.text;
                  String name = nameController.text;
                  // Pass the email and password inputs
                  _signUpWithEmailAndPassword(email, password,name, context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(
                    0xFF437D28,
                  ), // Button background color changed to match provided color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded corners
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Color(0xFF437D28),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.grey[200],
                          // fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Color(0xFF437D28),
                      ),
                    ),
                  ],
                ),
              ),

              
              SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignInPage(), // Navigate to main.dart
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'If you have an account? ',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFF437D28),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
