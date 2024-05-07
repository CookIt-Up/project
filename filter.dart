import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cookitup/recipe_details.dart';
import 'package:cookitup/upload_recipe.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'profile.dart';
import 'grocery.dart';
import 'home.dart';
import 'chatbot.dart';

class FilterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Filter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Define named routes
      routes: {
        '/': (context) => filterScreen(),
        '/userProfile': (context) => UserProfileScreen(),
        '/groceryList': (context) => GroceryListApp(),
        '/main': (context) => Home(),
        '/chatbot': (context) => ChatbotApp(),
        '/filter': (context) => FilterPage(),
      },
    );
  }
}

class filterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilterRecipe(
                                      filter: 'diets', category: 'keto'),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      AssetImage('assets/keto.jpg'),
                                ),
                                SizedBox(height: 5),
                                Text('Keto'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilterRecipe(
                                      filter: 'diets', category: 'paleo'),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      AssetImage('assets/paleo.webp'),
                                ),
                                SizedBox(height: 5),
                                Text('Paleo'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilterRecipe(
                                      filter: 'diets', category: 'vegan'),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      AssetImage('assets/vegan.jpg'),
                                ),
                                SizedBox(height: 5),
                                Text('Vegan'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilterRecipe(
                                      filter: 'diets', category: 'liquid'),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      AssetImage('assets/liquid.jpg'),
                                ),
                                SizedBox(height: 5),
                                Text('Liquid'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Occasions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilterRecipe(
                                      filter: 'occasion',
                                      category: 'christmas'),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      AssetImage('assets/christmas.jpg'),
                                ),
                                SizedBox(height: 5),
                                Text('Christmas'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilterRecipe(
                                      filter: 'occasion', category: 'diwali'),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      AssetImage('assets/diwali.jpg'),
                                ),
                                SizedBox(height: 5),
                                Text('Diwali'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilterRecipe(
                                      filter: 'occasion',
                                      category: 'eid-al-fitr'),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: AssetImage('assets/eid.jpg'),
                                ),
                                SizedBox(height: 5),
                                Text('Ei-al-Fitr'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilterRecipe(
                                      filter: 'occasion', category: 'onam'),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      AssetImage('assets/onam.webp'),
                                ),
                                SizedBox(height: 5),
                                Text('Onam'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilterRecipe(
                                      filter: 'meals', category: 'main course'),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      AssetImage('assets/main.jpg'),
                                ),
                                SizedBox(height: 5),
                                Text('Main Course'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilterRecipe(
                                      filter: 'meals', category: 'side dish'),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      AssetImage('assets/side.jpg'),
                                ),
                                SizedBox(height: 5),
                                Text('Side Dish'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilterRecipe(
                                      filter: 'meals', category: 'dessert'),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      AssetImage('assets/dessert.jpg'),
                                ),
                                SizedBox(height: 5),
                                Text('Dessert'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilterRecipe(
                                      filter: 'meals', category: 'appetizer'),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      AssetImage('assets/appetizer.jpg'),
                                ),
                                SizedBox(height: 5),
                                Text('Appetizer'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/main');
                },
                icon: Icon(Icons.home),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FilterPage()),
                  );
                },
                icon: Icon(Icons.soup_kitchen_sharp),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => YourRecipe()),
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
                  // Navigator.pushNamed(context, '/chatbot');
                },
                icon: Icon(Icons.person_4_sharp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterRecipe extends StatefulWidget {
  final String filter;
  final String category;

  const FilterRecipe({Key? key, required this.filter, required this.category})
      : super(key: key);

  @override
  State<FilterRecipe> createState() => _FilterRecipeState();
}

class _FilterRecipeState extends State<FilterRecipe> {
  late QuerySnapshot querySnapshot;
  late Set<String> matchedDocumentIds;
  late StreamController<Set<String>> matchedDocumentIdsStreamController;

  @override
  void initState() {
    super.initState();
    matchedDocumentIds = {};
    matchedDocumentIdsStreamController = StreamController<Set<String>>();
    fetchData();
  }

  Future<void> fetchData() async {
    querySnapshot =
        await FirebaseFirestore.instance.collection(widget.filter).get();

    for (var doc in querySnapshot.docs) {
      // Check if the document's ID matches the desired category and the data is not null
      if (doc.id == widget.category) {
        // Retrieve the document data as a map
        var data = doc.data();
        if (data != null) {
          // Iterate over the fields and add their values to matchedDocumentIds
          if (data is Map<String, dynamic>) {
            // Iterate over the fields and add their values to matchedDocumentIds
            data.forEach((key, value) {
              if (value != null) {
                matchedDocumentIds.add(value.toString());
              }
            });
          }
        }
      }
    }

    // Emit the updated set of document IDs to the stream
    matchedDocumentIdsStreamController.add(matchedDocumentIds);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            // Capitalize the first letter of the category
            widget.category.substring(0, 1).toUpperCase() +
                widget.category.substring(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18, // Adjust the font size as needed
            ),
          ),
          backgroundColor: Color(0xFFD1E7D2),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        backgroundColor: Color(0xFFD1E7D2),
        body: SafeArea(
          child: StreamBuilder<Set<String>>(
            stream: matchedDocumentIdsStreamController.stream,
            builder: (context, AsyncSnapshot<Set<String>> snapshot) {
              if (snapshot.hasData) {
                return ListView.separated(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    String documentId = snapshot.data!.toList()[index];
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('recipe')
                          .doc(documentId)
                          .snapshots(),
                      builder: (context,
                          AsyncSnapshot<DocumentSnapshot> documentSnapshot) {
                        if (documentSnapshot.hasData &&
                            documentSnapshot.data!.exists) {
                          var data = documentSnapshot.data!.data()
                              as Map<String, dynamic>;
                          String thumbnailUrl = data['thumbnail'];

                          return SizedBox(
                            width: 200,
                            height: 250,
                            child: FutureBuilder(
                              future: getImageUrl(thumbnailUrl),
                              builder: (context, urlSnapshot) {
                                if (urlSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator(
                                    // Define the color of the CircularProgressIndicator
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        const Color.fromARGB(
                                            255, 255, 255, 255)),

                                    // Define the thickness of the CircularProgressIndicator
                                    strokeWidth: 2.0,
                                  );
                                } else if (urlSnapshot.hasError) {
                                  return Text('Error: ${urlSnapshot.error}');
                                } else {
                                  var url = urlSnapshot.data as String;
                                  return GestureDetector(
                                    onTap: () {
                                      DocumentSnapshot recipeSnapshot =
                                          documentSnapshot.data!;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                RecipeDetailsPage(
                                                    recipeSnapshot:
                                                        recipeSnapshot)),
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: NetworkImage(url),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        StreamBuilder<DocumentSnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(data['userid'])
                                              .snapshots(),
                                          builder: (context,
                                              AsyncSnapshot<DocumentSnapshot>
                                                  userSnapshot) {
                                            if (userSnapshot.hasData &&
                                                userSnapshot.data!.exists) {
                                              var userData =
                                                  userSnapshot.data!.data()
                                                      as Map<String, dynamic>;
                                              String dp =
                                                  userData['profilepic'];
                                              return Row(
                                                children: [
                                                  FutureBuilder<String>(
                                                    future: getImageUrl(dp),
                                                    builder: (context,
                                                        avatarUrlSnapshot) {
                                                      if (avatarUrlSnapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return CircularProgressIndicator(
                                                          // Define the color of the CircularProgressIndicator
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                      Color>(
                                                                  const Color
                                                                      .fromARGB(
                                                                      255,
                                                                      255,
                                                                      255,
                                                                      255)),

                                                          // Define the thickness of the CircularProgressIndicator
                                                          strokeWidth: 2.0,
                                                        );
                                                      } else if (avatarUrlSnapshot
                                                          .hasError) {
                                                        return Text(
                                                            'Error: ${avatarUrlSnapshot.error}');
                                                      } else {
                                                        String avatarUrl =
                                                            avatarUrlSnapshot
                                                                .data!;
                                                        // Use the avatarUrl to display the avatar image
                                                        return CircleAvatar(
                                                          backgroundImage:
                                                              NetworkImage(
                                                                  avatarUrl),
                                                          radius: 20,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                  SizedBox(width: 10),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        data['title'],
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                      SizedBox(height: 5),
                                                      Text(
                                                        userData['name'],
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w200,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            } else {
                                              print(
                                                  "User Snapshot Error: ${userSnapshot.error}");
                                              return SizedBox(); // Placeholder when data is loading or not available
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        } else {
                          return SizedBox(); // Placeholder when data is loading or not available
                        }
                      },
                    );
                  },
                  separatorBuilder: (ctx, index) {
                    return SizedBox(
                      height: 20,
                    );
                  },
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(
                    // Define the color of the CircularProgressIndicator
                    valueColor: AlwaysStoppedAnimation<Color>(
                        const Color.fromARGB(255, 255, 255, 255)),

                    // Define the thickness of the CircularProgressIndicator
                    strokeWidth: 2.0,
                  ),
                  // Show a loading indicator while waiting for data
                );
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    matchedDocumentIdsStreamController.close();
    super.dispose();
  }

  Future<String> getImageUrl(String imageName) async {
    final ref = FirebaseStorage.instance.ref().child(imageName);
    final url = await ref.getDownloadURL();
    return url;
  }
}
