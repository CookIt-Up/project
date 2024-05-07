// recipe_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class RecipeDetails{
  Stream<QuerySnapshot> streamUnapprovedRecipes() {
    return FirebaseFirestore.instance
        .collection('recipe')
        .snapshots();
  }
}

class RecipeDetailsPage extends StatelessWidget {
  final RecipeDetails _recipeService = RecipeDetails();
  void _confirmDeleteRecipe(BuildContext context, String recipeId) async {
  bool confirmed = await showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('Delete Recipe?'),
        content: Text('Are you sure you want to delete $recipeId?'),
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
    _deleteRecipe(recipeId);
  }
}

void _deleteRecipe(String recipeId) async {
  final CollectionReference recipesCollection =
      FirebaseFirestore.instance.collection('recipe');

  try {
    await deleteDocumentAndSubcollections(recipeId);
    print('Recipe deleted successfully');
  } catch (error) {
    print('Failed to delete recipe: $error');
  }
}

Future<void> deleteDocumentAndSubcollections(String documentId) async {
  final CollectionReference recipesCollection =
      FirebaseFirestore.instance.collection('recipe');

  // Start by deleting the main document
  await recipesCollection.doc(documentId).delete();

  // Get a reference to the document's subcollections
  QuerySnapshot subcollectionsSnapshot =
      await recipesCollection.doc(documentId).collection('subcollections').get();

  // Delete all documents in each subcollection
  for (QueryDocumentSnapshot subcollectionDoc in subcollectionsSnapshot.docs) {
    await deleteDocumentAndSubcollections(subcollectionDoc.reference.id);
  }
}
  @override
    Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Details'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _recipeService.streamUnapprovedRecipes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final List<DocumentSnapshot> recipes = snapshot.data!.docs;

          if (recipes.isEmpty) {
            return Center(
              child: Text('No unapproved recipes found.'),
            );
          }

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index].data() as Map<String, dynamic>;
              final String recipeId = recipes[index].id;

              return ListTile(
                title: Text(recipe['title'] ?? ''),
                subtitle: Text('ID: $recipeId'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdateRecipePage(recipes[index]),
                    ),
                  );
                },
                trailing: IconButton(
      icon: Icon(Icons.delete),
      onPressed: () {
        _confirmDeleteRecipe(context,recipeId);
      },
    ),
              );
            },
          );
        },
      ),
    );
  }
   
  }

 


class UpdateRecipePage extends StatelessWidget {
  final DocumentSnapshot recipeSnapshot;

  UpdateRecipePage(this.recipeSnapshot);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> recipe = recipeSnapshot.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text('Update Recipe'),
      ),
      backgroundColor:
          Colors.lightGreen[100], // Set light green background color
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Title'),
              controller: TextEditingController(text: recipe['title']),
              onChanged: (value) {
                recipe['title'] = value;
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Meal'),
              controller: TextEditingController(text: recipe['meal']),
              onChanged: (value) {
                recipe['meal'] = value;
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Diet'),
              controller: TextEditingController(text: recipe['diet']),
              onChanged: (value) {
                recipe['diet'] = value;
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Occasion'),
              controller: TextEditingController(text: recipe['occasion']),
              onChanged: (value) {
                recipe['occasion'] = value;
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Serving'),
              controller:
                  TextEditingController(text: recipe['serving'].toString()),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                recipe['serving'] = int.tryParse(value) ?? 1;
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Thumbnail'),
              controller: TextEditingController(text: recipe['thumbnail']),
              onChanged: (value) {
                recipe['thumbnail'] = value;
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'User ID'),
              controller: TextEditingController(text: recipe['userid']),
              onChanged: (value) {
                recipe['userid'] = value;
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Video'),
              controller: TextEditingController(text: recipe['video']),
              onChanged: (value) {
                recipe['video'] = value;
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Update recipe in Firestore
          FirebaseFirestore.instance
              .collection('recipe')
              .doc(recipeSnapshot.id)
              .update(recipe)
              .then((_) {
            Navigator.pop(context);
          }).catchError((error) {
            print('Error updating recipe: $error');
          });
        },
        child: Icon(Icons.save),
      ),
    );
  }
}


