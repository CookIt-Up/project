import 'package:cookitup/admin/recipe_service.dart';
import 'package:cookitup/admin/recipes_details.dart';
import 'package:cookitup/admin/report.dart';
import 'package:cookitup/admin/user_details.dart';
import 'package:cookitup/main.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 0;
  int _totalUsers = 0;
  int _totalRecipes = 0;
  int _unapprovedRecipes = 0;
  late PageController _pageController;
  late DateTime _startDate;
  @override
  void initState() {
    super.initState();
    _fetchCounts();
    _startDate = DateTime.now();
    _pageController = PageController(initialPage: 15); // Start at today's date
  }
  
  Future<void> _fetchCounts() async {
    // Retrieve total number of users
    FirebaseFirestore.instance.collection('users').get().then((QuerySnapshot querySnapshot) {
      setState(() {
        _totalUsers = querySnapshot.size;
      });
    }).catchError((error) {
      print('Error getting users count: $error');
    });

    // Retrieve total number of recipes
    FirebaseFirestore.instance.collection('recipe').get().then((QuerySnapshot querySnapshot) {
      setState(() {
        _totalRecipes = querySnapshot.size;
      });
    }).catchError((error) {
      print('Error getting recipes count: $error');
    });

    Stream<QuerySnapshot> unapprovedRecipesStream = FirebaseFirestore.instance
      .collection('recipe')
      .where('approved', isEqualTo: false)
      .snapshots();

  // Await the first result from the stream
  QuerySnapshot snapshot = await unapprovedRecipesStream.first;

  // Get the count of documents in the snapshot
  setState(() {
       _unapprovedRecipes = snapshot.size;
      });
  }

  @override
    void showSignOutConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('No'),
          ),
          TextButton(
            onPressed: () async {
              // Execute sign-out logic
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('adminloggedIn', false);
              
              // Navigate to MyApp (or any desired screen after sign-out)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MyApp()),
              );
            },
            child: Text('Yes'),
          ),
        ],
      );
    },
  );
}


 

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.green[100],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Text(
                    'Welcome, Admin!',
                    style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 60),
                IconButton(
                  onPressed: () {
                    // Implement sign out functionality
                    showSignOutConfirmationDialog(context);
                  },
                  icon: Icon(Icons.logout),
                ),
              ],
            ),
             
Container(
        margin: EdgeInsets.all(12),
        height: 202, // Add margin around the container
        decoration: BoxDecoration(
          color: Colors.white, // Background color of the container
          borderRadius: BorderRadius.circular(12), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5), // Shadow color
              spreadRadius: 2, // Spread radius
              blurRadius: 5, // Blur radius
              offset: Offset(0, 3), // Offset to control the direction of the shadow
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      DateFormat('MMMM yyyy').format(_startDate),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.calendar_month,
                      color: Color.fromARGB(255, 55, 55, 55),
                    ),
                    onPressed: () {
                      // Handle calendar button press
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              Container(
                height: 100,
                child: ListView.builder(
                  itemCount: 30,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final date = _startDate.add(Duration(days: index));
                    return _buildDateItem(date);
                  },
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                        _buildIconBox(
                          context,
                          labelText: 'Customer',
                          icon: Icons.person,
                          text: '$_totalUsers',
                          onTap: () {
                           // Navigate to user details page
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UserListWidget()),
                            );
                          },
                        ),
                         SizedBox(width: 10,),
                        _buildIconBox(
                          context,
                          labelText: 'Recipe',
                          icon: Icons.restaurant,
                          text: '$_totalRecipes',
                          onTap: () {
                            //Navigate to recipe details page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RecipeDetailsPage()),
                            );
                          },
                        ),
              ]
            ),
            SizedBox(height: 20,),
             Row(
              children: [
                        _buildIconBox(
                          context,
                          labelText:'New Recipes',
                          icon: Icons.check,
                          text: '$_unapprovedRecipes',
                          onTap: () {
                            //Navigate to recipe details page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RecipeServicePage()),
                            );
                          },
                        ),
                         SizedBox(width: 10,),
                        _buildIconBox(
                          context,
                          labelText: 'Report',
                          icon: Icons.auto_graph,
                          text: '',
                          onTap: () {
                            // Navigate to recipe details page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AnalyticsPage ()),
                            );
                          },
                        ),
              ]
            ),
          ],
        ),
      )
          ]
    ),
  
       
      ),
    );
  }
Widget _buildIconBox(
  BuildContext context, {
  required IconData icon,
  required String text,
  required void Function() onTap,
  double iconSize = 40.0,
  double boxWidth = 156.0,
  double boxHeight = 130.0, required String labelText,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: boxWidth,
      height: boxHeight,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5), // Shadow color
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // Changes position of shadow
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: iconSize,
              ),
              SizedBox(width: 8.0),
              Text(
                text,
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              
            ],
          ),
      
      SizedBox(height: 10.0),
          Text(
            labelText,
            // style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
            ],
      ),
    ),
  );
}
 Widget _buildDateItem(DateTime date) {
  final today = DateTime.now();
  final isSelectedDate = today.isAtSameMomentAs(date);
  final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

  return Container(
    width: 75,
    margin: EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: isToday ? Colors.green[100] : Colors.grey[300],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          DateFormat('E').format(date), // Display weekday abbreviation (e.g., "Mon", "Tue")
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelectedDate ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 4),
        Text(
          DateFormat('d').format(date), // Display day of the month
          style: TextStyle(
            fontSize: 18,
            color: isSelectedDate ? Colors.white : Colors.black,
            fontWeight: isSelectedDate ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

}
