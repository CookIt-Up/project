import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cookitup/main.dart';
import 'package:cookitup/signIn.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late String _userName = '';
  late String _followers = '';
  late int _video = 0;
  late String _userImageUrl = '';

  get userData => null; // Initialize userName with a default value

  @override
  void initState() {
    super.initState();
    // Fetch user details using email from SharedPreferences when the page loads
    _fetchUserDetails();
  }

  void _fetchUserDetails() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userEmail = prefs.getString('email');
      if (userEmail != null) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(userEmail) // Use userEmail as the document ID
            .get();

        if (userSnapshot.exists) {
          // Access the data of the document
          Map<String, dynamic> userData =
              userSnapshot.data() as Map<String, dynamic>;

          // Access the fields from userData
          setState(() {
            _userName = userData['name'] ??
                ''; // Assign the fetched user name to _userName
            _followers = userData['followers'] ?? '';
            _video = userData['video'] ?? 0;
            _userImageUrl = userData['profilepic'] ?? '';
          });
        } else {
          print("No document found for email: $userEmail");
        }
      } else {
        print("User email is null");
      }
    } catch (error) {
      print("Error fetching user details: $error");
    }
  }

  final CollectionReference recipe =
      FirebaseFirestore.instance.collection('recipe');

  Future<String> getImageUrl(String imageName) async {
    final ref = FirebaseStorage.instance.ref().child(imageName);
    final url = await ref.getDownloadURL();
    return url;
  }

  Future<String> _fetchProfilePictureUrl() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userEmail = prefs.getString('email');
      if (userEmail != null) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(userEmail)
            .get();

        if (userSnapshot.exists) {
          Map<String, dynamic> userData =
              userSnapshot.data() as Map<String, dynamic>;
          return userData['profilepic'] ?? '';
        } else {
          print("No document found for email: $userEmail");
        }
      } else {
        print("User email is null");
      }
    } catch (error) {
      print("Error fetching user details: $error");
    }
    return ''; // Return an empty string if fetching fails
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showBottomSheet(context);
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.green[100], // Light green background color
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<String>(
              future: _fetchProfilePictureUrl(),
              builder: (context, avatarUrlSnapshot) {
                if (avatarUrlSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color.fromARGB(255, 255, 255, 255),
                    ),
                    strokeWidth: 5.0,
                  );
                } else if (avatarUrlSnapshot.hasError) {
                  return Text('Error: ${avatarUrlSnapshot.error}');
                } else {
                  String avatarUrl = avatarUrlSnapshot.data as String;
                  // Use the avatarUrl to fetch the image from Firebase Storage
                  return FutureBuilder<String>(
                    future: getImageUrl(avatarUrl),
                    builder: (context, imageUrlSnapshot) {
                      if (imageUrlSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color.fromARGB(255, 255, 255, 255),
                          ),
                          strokeWidth: 5.0,
                        );
                      } else if (imageUrlSnapshot.hasError) {
                        return Text('Error: ${imageUrlSnapshot.error}');
                      } else {
                        String imageUrl = imageUrlSnapshot.data as String;
                        // Use the imageUrl to display the image
                        return CircleAvatar(
                          backgroundImage: NetworkImage(imageUrl),
                          radius: 50,
                        );
                      }
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _userName, // Display fetched user name
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                if (_followers.isNotEmpty && _followers.contains('K'))
                  int.parse(_followers.replaceAll('K', '')) > 500
                      ? const Icon(
                          Icons.verified,
                          color: Colors.blue,
                        )
                      : Container(),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$_followers Followers . $_video Videos',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                            userName: _userName,
                            followers: _followers,
                            videos: _video,
                          )),
                );
              },
              child: const Text('Edit Profile'),
            ),
            Expanded(
              child: FutureBuilder<String?>(
                future: SharedPreferences.getInstance()
                    .then((prefs) => prefs.getString('email')),
                builder: (context, emailSnapshot) {
                  if (emailSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    // If still waiting for SharedPreferences, return a loading indicator
                    return Center(child: CircularProgressIndicator());
                  } else if (emailSnapshot.hasError) {
                    // Handle error if SharedPreferences retrieval fails
                    return Text('Error fetching email: ${emailSnapshot.error}');
                  } else {
                    // Once email is retrieved, use it to filter documents in the StreamBuilder
                    String? userEmail = emailSnapshot.data;

                    return StreamBuilder(
                      stream:
                          recipe.orderBy('likes', descending: true).snapshots(),
                      builder: (context, AsyncSnapshot snapshot) {
                        if (snapshot.hasData) {
                          // Filter documents where userid matches user's email
                          var filteredDocs = snapshot.data.docs.where((doc) {
                            var userId = doc['userid'];
                            return userId == userEmail;
                          }).toList();

                          return GridView.builder(
                            itemCount: filteredDocs.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                            ),
                            itemBuilder: (context, index) {
                              var document = filteredDocs[index];
                              var thumbnailPath = document['thumbnail'];
                              print('Image Path $thumbnailPath');
                              return FutureBuilder(
                                future: getImageUrl(thumbnailPath),
                                builder: (context, urlSnapshot) {
                                  if (urlSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  } else if (urlSnapshot.hasError) {
                                    return Text('Error: ${urlSnapshot.error}');
                                  } else {
                                    var url = urlSnapshot.data as String;

                                    return Container(
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(url),
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        } else {
                          return Container();
                        }
                      },
                    );
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final String userName;
  final String followers;
  final int videos;
  final String? userEmail;

  EditProfileScreen({
    required this.userName,
    required this.followers,
    required this.videos,
    this.userEmail,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState(userEmail);
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  _EditProfileScreenState(String? userEmail) {
    // Initialize controllers and userEmail here
    _usernameController = TextEditingController();
    _emailController = TextEditingController(text: userEmail);
    _passwordController = TextEditingController();
  }

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    // Fetch user information and set the text controllers
    _fetchUserData();
    _fetchProfilePictureUrl();
  }

  Future<void> _fetchUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userEmail = prefs.getString('email');
      if (userEmail != null) {
        // Fetch additional user data from Firestore
        DocumentSnapshot userDataSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .get();
        if (userDataSnapshot.exists) {
          Map<String, dynamic> userData =
              userDataSnapshot.data() as Map<String, dynamic>;
          setState(() {
            _usernameController.text = userData['name'] ?? '';
            _emailController.text = userEmail;
            _passwordController.text = userData['password'] ?? '';
          });
        }
      }
    } catch (error) {
      print('Error fetching user data: $error');
    }
  }

  Future<String> _fetchProfilePictureUrl() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userEmail = prefs.getString('email');
      if (userEmail != null) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(userEmail)
            .get();

        if (userSnapshot.exists) {
          Map<String, dynamic> userData =
              userSnapshot.data() as Map<String, dynamic>;
          return userData['profilepic'] ?? '';
        } else {
          print("No document found for email: $userEmail");
        }
      } else {
        print("User email is null");
      }
    } catch (error) {
      print("Error fetching user details: $error");
    }
    return ''; // Return an empty string if fetching fails
  }

  Future<String> getImageUrl(String imageName) async {
    final ref = FirebaseStorage.instance.ref().child(imageName);
    final url = await ref.getDownloadURL();
    return url;
  }

  @override
  Widget build(BuildContext context) {
    var text = _usernameController.text;
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        color: Colors.green[100],
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<String>(
              future: _fetchProfilePictureUrl(),
              builder: (context, avatarUrlSnapshot) {
                if (avatarUrlSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color.fromARGB(255, 255, 255, 255),
                    ),
                    strokeWidth: 5.0,
                  );
                } else if (avatarUrlSnapshot.hasError) {
                  return Text('Error: ${avatarUrlSnapshot.error}');
                } else {
                  String avatarUrl = avatarUrlSnapshot.data as String;
                  // Use the avatarUrl to fetch the image from Firebase Storage
                  return FutureBuilder<String>(
                    future: getImageUrl(avatarUrl),
                    builder: (context, imageUrlSnapshot) {
                      if (imageUrlSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color.fromARGB(255, 255, 255, 255),
                          ),
                          strokeWidth: 5.0,
                        );
                      } else if (imageUrlSnapshot.hasError) {
                        return Text('Error: ${imageUrlSnapshot.error}');
                      } else {
                        String imageUrl = imageUrlSnapshot.data as String;
                        // Use the imageUrl to display the image
                        return CircleAvatar(
                          backgroundImage: NetworkImage(imageUrl),
                          radius: 50,
                        );
                      }
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                if (widget.followers.isNotEmpty &&
                    widget.followers.contains('K'))
                  int.parse(widget.followers.replaceAll('K', '')) > 500
                      ? const Icon(
                          Icons.verified,
                          color: Colors.blue,
                        )
                      : Container(),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.followers} Followers . ${widget.videos} Videos',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement logic to update profile picture
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
              ),
              child: const Text('Change Picture'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            // TextField(
            //   controller: _emailController,
            //   decoration: InputDecoration(
            //     labelText: 'Email ID',
            //     border: OutlineInputBorder(),
            //   ),
            // ),
            // const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              color: Colors.black,
              child: ElevatedButton(
                onPressed: () {
                  _updateProfile(context);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                ),
                child: const Text('Update'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateProfile(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userEmail = prefs.getString('email');

      // Update user document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .update({
        'name': _usernameController.text,
        'password': _passwordController.text,
        'email': _emailController.text, // Update email in Firestore as well
      });

      // Update the UI with the new data
      setState(() {
        // Update any state variables that need to be updated
        var _userName = _usernameController.text;
        var _userEmail = _emailController.text;
        var _password = _passwordController.text;
      });

      // Show a SnackBar to indicate successful update
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('User profile updated successfully'),
      ));
    } catch (error) {
      // Handle errors during the update process
      print('Error updating user profile: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update user profile'),
      ));
    }
  }
}

void _showBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SingleChildScrollView( // Wrap the Column with SingleChildScrollView
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green[100], // Light green background color
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), // Top-left corner radius
              topRight: Radius.circular(20), // Top-right corner radius
            ),
          ),
          // Adjust height according to content or use constraints
          // height: MediaQuery.of(context).size.height * 0.3, 
          child: Column(
            mainAxisSize: MainAxisSize.min, // Adjust according to content
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.save, color: Colors.black), // Black icon
                title: const Text(
                  'Saved',
                  style: TextStyle(color: Colors.black), // Black text color
                ),
                onTap: () {
                  // Handle "Saved" action
                  Navigator.pop(context);

                  // Navigate to a new screen to display the saved images
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SavedImagesScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.black), // Black icon
                title: const Text(
                  'About Us',
                  style: TextStyle(color: Colors.black), // Black text color
                ),
                onTap: () {
                  // Handle "About Us" action
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.black), // Black icon
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.black), // Black text color
                ),
                onTap: () async {
                  // Handle "Logout" action
                  print('loging out');
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('loggedIn', false);
                   //Navigator.popUntil(context, ModalRoute.withName('/signin'));
                   //Navigator.of(context).pop();
                   Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyApp()),
                );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<String> getImageUrl(String imageName) async {
  final ref = FirebaseStorage.instance.ref().child(imageName);
  final url = await ref.getDownloadURL();
  return url;
}

class SavedImagesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD1E7D2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD1E7D2),
        title: Text(
          'Saved Recipes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<String?>(
        future: SharedPreferences.getInstance()
            .then((prefs) => prefs.getString('email')),
        builder: (context, emailSnapshot) {
          if (emailSnapshot.connectionState == ConnectionState.waiting) {
            // If still waiting for SharedPreferences, return a loading indicator
            return Center(child: CircularProgressIndicator());
          } else if (emailSnapshot.hasError) {
            // Handle error if SharedPreferences retrieval fails
            return Text('Error fetching email: ${emailSnapshot.error}');
          } else {
            // Once email is retrieved, use it to fetch saved recipes
            String? userEmail = emailSnapshot.data;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userEmail)
                  .collection('savedRecipes')
                  .snapshots(),
              builder: (context, savedRecipesSnapshot) {
                if (savedRecipesSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (savedRecipesSnapshot.hasError) {
                  return Text(
                      'Error fetching saved recipes: ${savedRecipesSnapshot.error}');
                } else {
                  // Fetch the inner documents containing recipe IDs
                  List<DocumentSnapshot> savedRecipesData =
                      savedRecipesSnapshot.data!.docs;

                  if (savedRecipesData.isEmpty) {
                    return Center(child: Text('No saved recipes found.'));
                  }

                  // Extract recipe IDs
                  List<String> savedRecipeIds =
                      savedRecipesData.map((doc) => doc.id).toList();

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('recipe')
                        .where(FieldPath.documentId, whereIn: savedRecipeIds)
                        .snapshots(),
                    builder: (context, recipeSnapshot) {
                      if (recipeSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (recipeSnapshot.hasError) {
                        return Text(
                            'Error fetching recipes: ${recipeSnapshot.error}');
                      } else {
                        List<DocumentSnapshot> filteredDocs =
                            recipeSnapshot.data!.docs;

                        return GridView.builder(
                          itemCount: filteredDocs.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          itemBuilder: (context, index) {
                            var document = filteredDocs[index];
                            var thumbnailPath = document['thumbnail'];
                            print('Image Path $thumbnailPath');
                            return FutureBuilder(
                              future: getImageUrl(thumbnailPath),
                              builder: (context, urlSnapshot) {
                                if (urlSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                } else if (urlSnapshot.hasError) {
                                  return Text('Error: ${urlSnapshot.error}');
                                } else {
                                  var url = urlSnapshot.data as String;

                                  return Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(url),
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        );
                      }
                    },
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}


