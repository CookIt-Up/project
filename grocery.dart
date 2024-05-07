import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cookitup/form.dart';
import 'package:cookitup/ingredients.dart';
import 'package:cookitup/upload_recipe.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'chatbot.dart';
import 'profile.dart';
import 'filter.dart';

class GroceryListApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GroceryListScreen(),
      routes: {
        //'/': (context) => filterScreen(),
        '/userProfile': (context) => UserProfileScreen(),
        '/groceryList': (context) => GroceryListApp(),
        '/main': (context) => Home(),
        '/chatbot': (context) => ChatbotApp(),
        '/filter': (context) => SelectionPage(),
      },
    );
  }
}

class GroceryListScreen extends StatefulWidget {
  @override
  _GroceryListScreenState createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  late Stream<List<String>> _selectedIngredientsStream;

  @override
  void initState() {
    super.initState();
    _selectedIngredientsStream = _fetchSelectedIngredients();
  }

  Stream<List<String>> _fetchSelectedIngredients() async* {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('email');
    if (userId != null) {
      yield* FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((snapshot) {
        final List<dynamic> data =
            snapshot.data()?['selectedIngredients'] ?? [];
        return data.map((ingredient) => ingredient.toString()).toList();
      });
    } else {
      // Handle the case when user ID is not available
    }
  }

  void _clearAllIngredients(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Clear All Ingredients"),
          content:
              Text("Are you sure you want to clear all selected ingredients?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text("Clear"),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                _clearIngredients();
              },
            ),
          ],
        );
      },
    );
  }

  void _clearIngredients() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('email');
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'selectedIngredients': []});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grocery List'),
        actions: [
          IconButton(
            onPressed: () {
              _clearAllIngredients(context);
            },
            icon: Icon(Icons.clear_all),
          ),
        ],
      ),
      body: Container(
        color: Colors.green[100],
        child: StreamBuilder<List<String>>(
          stream: _selectedIngredientsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final List<String> selectedIngredients = snapshot.data ?? [];
              if (selectedIngredients.isEmpty) {
                return Center(child: Text('No selected ingredients found'));
              } else {
                return ListView.builder(
                  itemCount: selectedIngredients.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(selectedIngredients[index]),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle_outline_outlined),
                        onPressed: () {
                          _removeIngredient(selectedIngredients[index]);
                        },
                      ),
                    );
                  },
                );
              }
            }
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 65,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                // Navigator.pushNamed(context, '/home');
              },
              icon: Icon(Icons.home),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/filter');
              },
              icon: FaIcon(
                FontAwesomeIcons.seedling,
                size: 20,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => YourRecipeApp()),
                );
              },
              icon: Icon(Icons.add),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GroceryListApp()),
                );
              },
              icon: Icon(Icons.list_alt_outlined),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/chatbot');
              },
              icon: Icon(Icons.person_4_sharp),
            ),
          ],
        ),
      ),
    );
  }
}

void _removeIngredient(String ingredient) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('email');
  if (userId != null) {
    List<String> updatedIngredients = [];
    List<String> currentIngredients = [];
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    currentIngredients =
        List<String>.from(snapshot.data()?['selectedIngredients'] ?? []);

    for (int i = 0; i < currentIngredients.length; i++) {
      if (currentIngredients[i] != ingredient) {
        updatedIngredients.add(currentIngredients[i]);
      }
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'selectedIngredients': updatedIngredients});
  }
}