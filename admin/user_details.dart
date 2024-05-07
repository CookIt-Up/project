import 'package:cookitup/admin/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserListWidget extends StatelessWidget {
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference _recipeCollection =
      FirebaseFirestore.instance.collection('recipe');
  final FirebaseStorage _storage = FirebaseStorage.instance;
    final CollectionReference _dietCollection =
      FirebaseFirestore.instance.collection('diets');

  // Stateful list to hold deleted recipe document IDs
  final List<String> deletedRecipeIds = [];

  // Function to build ListTile with avatar (profile picture or default icon) and delete button
  Widget _buildListTileWithAvatarAndDeleteButton(
    String? avatarUrl, String name, String email, BuildContext context) {
  // Determine the image provider based on the avatarUrl
  ImageProvider<Object>? imageProvider;
  if (avatarUrl != null && avatarUrl.isNotEmpty) {
    imageProvider = NetworkImage(avatarUrl);
  } else {
    // Use default icon if avatarUrl is null or empty
    imageProvider = AssetImage('assets/userprofile.jpg');
  }

  return ListTile(
    leading: CircleAvatar(
      radius: 25,
      backgroundImage: imageProvider,
    ),
    title: Text(
      name,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    subtitle: Text(
      email,
      style: TextStyle(fontSize: 14),
    ),
    trailing: IconButton(
      icon: Icon(Icons.delete),
      onPressed: () {
        _confirmDeleteUser(context, name, email);
      },
    ),
    onTap: () {
      _navigateToUserDetails(context, email);
    },
  );
}

void _confirmDeleteUser(BuildContext context, String name, String email) async {
  bool confirmed = await showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('Delete User?'),
        content: Text('Are you sure you want to delete $name?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false); // Cancel delete
            },
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true); // Confirm delete
            },
            child: Text('DELETE'),
          ),
        ],
      );
    },
  );

  if (confirmed == true) {
    _deleteUser(email);
  }
}


  // Function to navigate to user details page
  void _navigateToUserDetails(BuildContext context, String email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(email: email),
      ),
    );
  }
   //delete from diets
void _deleteDiets(List<String> recipeIdsToDelete) {
    recipeIdsToDelete.forEach((recipeId) {
      // Reference the 'diets' subcollection of the specific recipe
   _dietCollection.get().then((querySnapshot) {
      querySnapshot.docs.forEach((collectionDoc) {
        print(collectionDoc);
      });
   }).catchError((error) {
        print('Error getting diet subcollection: $error');
      });
    });
  }

  //recipes delete
  void _deleteRecipes(String userEmail) {
    // Query 'recipe' collection to find recipes associated with the user
    _recipeCollection
        .where('userid', isEqualTo: userEmail)
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((recipeDoc) {
        // Save the deleted recipe document ID
        String recipeId = recipeDoc.id;
        deletedRecipeIds.add(recipeId);

        // Delete the recipe document
        recipeDoc.reference.delete().then((value) {
          print('Recipe deleted successfully: $recipeId');
          _deleteDiets(deletedRecipeIds);
        }).catchError((error) {
          print('Failed to delete recipe $recipeId: $error');
        });
      });
    }).catchError((error) {
      print('Error getting recipes: $error');
    });
  }
  // Function to delete user
  void _deleteUser(String email) {
    // Implement user deletion logic here
    _userCollection.doc(email).delete().then((value) {
      print('User deleted successfully');
    _deleteRecipes(email);
    }).catchError((error) {
      print('Failed to delete user: $error');
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Details'),
      ),
      body: StreamBuilder(
        stream: _userCollection.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final userList = snapshot.data!.docs;

          return ListView.builder(
            itemCount: userList.length,
            itemBuilder: (context, index) {
              final userData = userList[index].data() as Map<String, dynamic>;
              final String name = userData['name'] ?? '';
              final String email = userData['email'] ?? '';
              final String profilePicPath = userData['profilepic'] ?? '';

              return FutureBuilder(
                future: _storage.ref(profilePicPath).getDownloadURL(),
                builder: (context, AsyncSnapshot<String> urlSnapshot) {
                  if (urlSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildListTileWithAvatarAndDeleteButton(
                        null, name, email, context); // Show loading indicator
                  }

                  if (urlSnapshot.hasError) {
                    return _buildListTileWithAvatarAndDeleteButton(
                        null, name, email, context); // Show default avatar on error
                  }

                  final String? avatarUrl = urlSnapshot.data;

                  return _buildListTileWithAvatarAndDeleteButton(
                      avatarUrl, name, email, context);
                },
              );
            },
          );
        },
      ),
    );
  }
}
