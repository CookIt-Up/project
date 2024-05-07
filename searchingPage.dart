import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cookitup/recipe_details.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class SearchingPage extends StatefulWidget {
  const SearchingPage({Key? key});

  @override
  State<SearchingPage> createState() => _SearchingPageState();
}

class _SearchingPageState extends State<SearchingPage> {
  bool showHomeSearch = false;
  bool showFilterPage = false;
  bool isHomeSearch = false;

  String recipe = "";
  List<DocumentSnapshot>? postDocumentsList;

  TextEditingController textFieldController = TextEditingController();
  String searchTitle = '';
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    textFieldController.text = searchTitle; // Set the initial value
    _focusNode = FocusNode();
    _focusNode.requestFocus(); // Request focus when the page loads
  }

  @override
  void dispose() {
    _focusNode.dispose(); // Dispose the FocusNode when the page is disposed
    super.dispose();
  }

  void initSearching(String value) {
  if (value.isEmpty) {
    setState(() {
      postDocumentsList = null;
    });
    return;
  }

  String searchQuery = value.toLowerCase();

  FirebaseFirestore.instance.collection("recipe").get().then((querySnapshot) {
    Set<String> uniqueTitles = {}; // Set to store unique titles
    List<DocumentSnapshot> filteredDocuments = [];

    querySnapshot.docs.forEach((doc) {
      var title = doc['title'].toLowerCase();
      if (title.contains(searchQuery) && !uniqueTitles.contains(title)) {
        uniqueTitles.add(title); // Add title to the set
        filteredDocuments.add(doc);
      }
    });

    setState(() {
      postDocumentsList = filteredDocuments;
      isHomeSearch = false; // Set to false to show SearchingPage
    });
  }).catchError((error) {
    print("Error searching: $error");
  });
}


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFFD1E7D2),
        appBar: AppBar(
          backgroundColor: Color(0xFFD1E7D2),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              if (isHomeSearch) {
                setState(() {
                  isHomeSearch = false;
                  textFieldController.clear(); // Clear text field when going back to SearchingPage
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 3.0),
                  child: TextField(
                    controller: textFieldController,
                    focusNode: _focusNode, // Assign the focus node to the TextField
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search...',
                    ),
                    onChanged: (value) {
                      setState(() {
                        showHomeSearch = false;
                        recipe = value;
                      });
                      initSearching(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        body: isHomeSearch
            ? HomeSearch(title: searchTitle)
            : postDocumentsList != null
                ? ListView.builder(
                    itemCount: postDocumentsList!.length,
                    itemBuilder: (context, index) {
                      var document = postDocumentsList![index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            searchTitle = document['title'];
                            isHomeSearch = true;
                            textFieldController.text = searchTitle;
                          });
                        },
                        child: ListTile(
                          title: Text(document['title']),
                        ),
                      );
                    },
                  )
                : Center(
                    // child:
                    //     CircularProgressIndicator(), // Show loading indicator while data is being fetched
                  ),
      ),
    );
  }
}

class HomeSearch extends StatefulWidget {
  final String title;

  HomeSearch({Key? key, required this.title}) : super(key: key);

  @override
  _HomeSearchState createState() => _HomeSearchState();
}

class _HomeSearchState extends State<HomeSearch> {
  late StreamController<Set<String>> matchedDocumentIdsStreamController;
  late Set<String> matchedDocumentIds;

  @override
  void initState() {
    super.initState();
    matchedDocumentIds = {};
    matchedDocumentIdsStreamController = StreamController<Set<String>>();
    initSearchResult();
  }

  Future<void> initSearchResult() async {
    matchedDocumentIds.clear();
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("recipe")
          .where("title", isEqualTo: widget.title)
          .get();

      for (var doc in querySnapshot.docs) {
        matchedDocumentIds.add(doc.id);
      }

      // Emit the updated set of document IDs to the stream
      matchedDocumentIdsStreamController.add(matchedDocumentIds);
    } catch (error) {
      print("Error searching: $error");
    }
  }

@override
Widget build(BuildContext context) {
  return SafeArea(
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
                                                      avatarUrlSnapshot.data!;
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
                                                  CrossAxisAlignment.start,
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


