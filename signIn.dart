import 'package:cookitup/signUp.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart'; // Import home.dart file
import 'main.dart'; // Import main.dart file (for SignUpPage)
import 'package:shared_preferences/shared_preferences.dart';

class SignInPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _signInWithEmailAndPassword(BuildContext context) async {
    String email = emailController.text;
    String password = passwordController.text;

    // Get the user document from Firestore
    try {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(email).get();
      DocumentSnapshot adminSnapshot = 
          await FirebaseFirestore.instance.collection('admin').doc(email).get();
      // Handle userSnapshot data
      // Check if the user exists and the password matches
      if (adminSnapshot.exists &&
          (adminSnapshot.data()! as Map<String, dynamic>)['password'] == password) {
        // Save email and login status to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        await prefs.setBool('adminloggedIn', true);
        var op=prefs.get('adminloggedIn');
        print(op);
        // Navigate to Home page if the user exists and the password matches
        Navigator.pushNamed(context, '/admin');
        // Navigator.push(
        //               context,
        //               MaterialPageRoute(builder: (context) => Home()),
        //             );
       
      }
      else if (userSnapshot.exists &&
          (userSnapshot.data()! as Map<String, dynamic>)['password'] == password) {
        // Save email and login status to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        await prefs.setBool('loggedIn', true);
        

        // Navigate to Home page if the user exists and the password matches
        Navigator.pushNamed(context, '/home');
        // Navigator.push(
        //               context,
        //               MaterialPageRoute(builder: (context) => Home()),
        //             );
       
      } else {
        // Show error message if the user doesn't exist or the password doesn't match
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Error"),
              content: Text("Invalid email or password"),
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
    } catch (e) {
      print('Error fetching user data: $e');
      // Handle error (e.g., display an error message to the user)
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
          'Welcome Back!',
          style: TextStyle(
            color: Color(0xFF437D28), // Title text color changed to match provided color
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView( // Wrap with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
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
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Implement sign-in logic
                  _signInWithEmailAndPassword(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(
                      0xFF437D28), // Button background color changed to match provided color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded corners
                  ),
                ),
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white, // Button text color changed to white
                  ),
                ),
              ),
              SizedBox(height: 20),
              // GestureDetector(
              //   onTap: () {
              //     // Implement login with Google logic
              //   },
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: Divider(
              //           color: Color(0xFF437D28),
              //         ),
              //       ),
              //       Padding(
              //         padding: EdgeInsets.symmetric(horizontal: 10),
              //         child: Text(
              //           'Sign in with',
              //           style: TextStyle(
              //             color: Color(0xFF437D28),
                         
              //           ),
              //         ),
              //       ),
              //       Expanded(
              //         child: Divider(
              //           color: Color(0xFF437D28),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // SizedBox(height: 5),
              // Image.asset(
              //   'assets/google_logo.png', // Path to your Google logo image
              //   width: 40, // Adjust the width as needed
              //   height: 40, // Adjust the height as needed
              // ),
              //SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage()), // Navigate to SignUpPage
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Sign up',
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
void main() {
  runApp(MaterialApp(
    initialRoute: '/signin', // Set the initial route to '/signin'
    routes: {
      '/signin': (context) => SignInPage(), // Define the route for SignInPage
      '/home': (context) => Home(),   // Define the route for HomeScreen
    },
  ));
}
