import 'dart:io';
//import 'package:cookitup/upload_recipe.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cookitup/home.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:fraction/fraction.dart';

class YourRecipe extends StatefulWidget {
  YourRecipe({Key? key}) : super(key: key);

  @override
  State<YourRecipe> createState() => _YourRecipeState();
}

class _YourRecipeState extends State<YourRecipe> {
  bool showUploadScreen = false; // Moved inside the state class
  XFile? videoFile; // Moved inside the state class

  Future<void> getVideoFile(ImageSource sourceImage) async {
    videoFile = await ImagePicker().pickVideo(source: sourceImage);

    if (mounted && videoFile != null) {
      print('Video confirmation screen');
      setState(() {
        showUploadScreen = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Pop back when tapping outside the container
      },
      child: Container(
        color: Colors.transparent, // Make the container transparent to allow taps through
        child: Center(
          child: showUploadScreen
              ? UploadRecipe(
                  videoFile: File(videoFile!.path),
                  videoPath: videoFile!.path,
                )
              : AlertDialog(
                  title: Text('Choose Video Source'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        onTap: () {
                          getVideoFile(ImageSource.gallery);
                        },
                        leading: Icon(Icons.image),
                        title: Text('Get Video from Gallery'),
                      ),
                      ListTile(
                        onTap: () {
                          getVideoFile(ImageSource.camera);
                        },
                        leading: Icon(Icons.camera_alt),
                        title: Text('Make Video with Camera'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class UploadRecipe extends StatefulWidget {
  final File videoFile;
  final String videoPath;

  const UploadRecipe({
    Key? key,
    required this.videoFile,
    required this.videoPath,
  }) : super(key: key);

  @override
  State<UploadRecipe> createState() => _UploadRecipeState();
}

class _UploadRecipeState extends State<UploadRecipe> {
  late VideoPlayerController _controller;
  Timer? _timer;
  int recipeCounter = 7; // Initialize the recipe counter
  List<String> recipeSteps = [];
  List<Map<String, dynamic>> ingredientsList = [];
  File? _imageFile;
  final TextEditingController _titleController = TextEditingController();

  String? _userEmail; // New variable to hold the user's email
  String? selectedMeal;
  String? selectedOccasion;
  String? selectedDiet;
  int servingCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
        _startTimer();
      });
    // Load the recipe counter from shared preferences when the widget is initialized
    _loadRecipeCounter();
  }

  Future<void> _getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('email');
      print('get userid');
    });
  }

  Future<void> _loadRecipeCounter() async {
    final prefs = await SharedPreferences.getInstance();
   prefs.setInt('recipeCounter',6);
    setState(() {
      // Load the recipe counter from shared preferences, defaulting to 0 if not found
      recipeCounter = prefs.getInt('recipeCounter') ?? 0;
    });
  }

  Future<void> _incrementRecipeCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Increment the recipe counter
      recipeCounter++;
      // Save the updated recipe counter to shared preferences
      prefs.setInt('recipeCounter', recipeCounter);
    });
  }

  CollectionReference recipe = FirebaseFirestore.instance.collection('recipe');

  Future<void> uploadFile() async {
    // Existing code

    await _incrementRecipeCounter();
    final String extension = widget.videoPath.split('.').last;
    final videoPath = 'video/r00$recipeCounter.$extension';
    final videoRef = FirebaseStorage.instance.ref().child(videoPath);
    await videoRef.putFile(widget.videoFile);

    late String imagePath;
    // Upload image if available
    if (_imageFile != null) {
      imagePath =
          'images/r00$recipeCounter.${_imageFile!.path.split('.').last}';
      final imageRef = FirebaseStorage.instance.ref().child(imagePath);
      await imageRef.putFile(_imageFile!);
    }

    // Generate the recipe ID
    String recipeId = 'r' + recipeCounter.toString().padLeft(3, '0');
    print('Recipe ID: $recipeId');

    //add recipe to firestore
    DocumentReference recipeDocRef = recipe.doc(recipeId);
    await recipeDocRef.set({
      'title': _titleController.text, // Retrieve text from the controller
      'thumbnail': imagePath,
      'video': videoPath,
      'likes': 0,
      'userid': _userEmail,
      'diet': selectedDiet,
      'occasion': selectedOccasion,
      'meal': selectedMeal,
      'serving': servingCount,
    });

    // Reference to the steps collection for the current recipe
    CollectionReference stepsCollectionRef = recipeDocRef.collection('steps');

// Loop through each recipe step and add it as a separate document in the steps collection
    for (int i = 0; i < recipeSteps.length; i++) {
      // Construct the document reference for the current step
      DocumentReference stepDocRef = stepsCollectionRef.doc('step${i + 1}');

      // Set the step details in the current step document
      await stepDocRef.set({
        'description': recipeSteps[i],
      });
    }

    // Reference to the steps collection for the current recipe
    CollectionReference ingredientsCollectionRef =
        recipeDocRef.collection('ingredients');



// Convert servingCount to Fraction
Fraction servingFraction = Fraction(servingCount, 1);

// Loop through each ingredient and add it as a separate document in the ingredients collection
for (int i = 0; i < ingredientsList.length; i++) {
  // Construct the document reference for the current ingredient
  DocumentReference ingredientDocRef =
      ingredientsCollectionRef.doc(ingredientsList[i]['name']);

  // Parse the quantity as a fraction
  Fraction qty;
  List<String> parts = ingredientsList[i]['quantity'].split(' ');
  if (parts.length == 2) {
    int whole = int.parse(parts[0]);
    qty = Fraction.fromString(parts[1]);
    qty += Fraction(whole);
  } else {
    qty = Fraction.fromString(ingredientsList[i]['quantity']);
  }

  // Calculate the quantity per serving
  Fraction qtyPerServing = qty / servingFraction;

  // Set the ingredient details in the current ingredient document
  await ingredientDocRef.set({
    'quantity': ingredientsList[i]['quantity'],
    'unit': ingredientsList[i]['unit'],
    'quantityPerServing': qtyPerServing.toString(),
  });
}

    for (int i = 0; i < ingredientsList.length; i++) {
      String ingredientName = ingredientsList[i]['name']!;

      // Query the "ingredient" collection to get documents matching ingredientName
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("ingredient")
          .where(FieldPath.documentId, isEqualTo: ingredientName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // There's a document with the ingredientName, update it with recipeId
        var doc = querySnapshot.docs.first;
        print("Updating document ${doc.id} with recipeId $recipeId");
        await doc.reference.update({
          recipeId: recipeId,
        });
      }
    }

//diets
    QuerySnapshot queryDiet = await FirebaseFirestore.instance
        .collection("diets")
        .where(FieldPath.documentId, isEqualTo: selectedDiet!.toLowerCase())
        .get();
    print(selectedDiet!.toLowerCase());
    if (queryDiet.docs.isNotEmpty) {
      // There's a document with the ingredientName, update it with recipeId
      var doc = queryDiet.docs.first;
      print("Updating document ${doc.id} with recipeId $recipeId");
      await doc.reference.update({
        recipeId: recipeId,
      });
    }

    //occasion
    QuerySnapshot queryOccasion = await FirebaseFirestore.instance
        .collection("occasion")
        .where(FieldPath.documentId, isEqualTo: selectedOccasion!.toLowerCase())
        .get();
    print(selectedOccasion!.toLowerCase());
    if (queryOccasion.docs.isNotEmpty) {
      // There's a document with the ingredientName, update it with recipeId
      var doc = queryOccasion.docs.first;
      print("Updating document ${doc.id} with recipeId $recipeId");
      await doc.reference.update({
        recipeId: recipeId,
      });
    }

    //meal
    QuerySnapshot queryMeal = await FirebaseFirestore.instance
        .collection("meals")
        .where(FieldPath.documentId, isEqualTo:selectedMeal!.toLowerCase())
        .get();
    print(selectedMeal!.toLowerCase());
    if (queryMeal.docs.isNotEmpty) {
      // There's a document with the ingredientName, update it with recipeId
      var doc = queryMeal.docs.first;
      print("Updating document ${doc.id} with recipeId $recipeId");
      await doc.reference.update({
        recipeId: recipeId,
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_controller.value.isPlaying) {
        setState(() {});
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    setState(() {
      _imageFile = pickedFile != null ? File(pickedFile.path) : null;
    });
  }
//   void _getImage(ImageSource source) async {
//   final pickedFile = await ImagePicker().pickImage(source: source);

//   if (pickedFile != null) {
//     // Reduce image resolution
//     final File? reducedImage = await reduceImageSize(File(pickedFile.path));

//     // Use the reducedImage for further processing or display
//     setState(() {
//       _imageFile = reducedImage;
//     });
//   }
// }
//   Future<File?> reduceImageSize(File originalImage) async {
//   // Use FlutterImageCompress or other libraries to reduce image size
//   // Example:
//   final result = await FlutterImageCompress.compressAndGetFile(
//      originalImage.path,
//      originalImage.path,
//      quality: 50, // Adjust quality as needed
//    );

//   // For demonstration, returning original image itself
//   return originalImage;
// }

  void incrementServing() {
    setState(() {
      servingCount++;
    });
  }

  void decrementServing() {
    setState(() {
      if (servingCount > 0) {
        servingCount--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        routes: {
          '/home': (context) => Home(),
        },
        // other MaterialApp properties

        home: Scaffold(
          // body: SafeArea(
          body: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppBar(
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    title: Text(
                      'Create Your Recipe',
                      style: TextStyle(
                        color: Color(0xFF437D28),
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Rest of your widgets...
                  Stack(
                    children: [
                      if (widget.videoFile != null &&
                          widget.videoPath.isNotEmpty)
                        FittedBox(
                          fit: BoxFit.cover,
                          child: GestureDetector(
                              onTap: () {
                                if (_controller.value.isPlaying) {
                                  _controller.pause();
                                } else {
                                  _controller.play();
                                }
                                setState(
                                    () {}); // Update UI to reflect play/pause state change
                              },
                              child: SizedBox(
                                width: 300, // Custom width
                                height: 400, // Custom height
                                child: Stack(
                                  children: [
                                    VideoPlayer(_controller),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: VideoProgressIndicator(
                                        _controller,
                                        allowScrubbing:
                                            true, // Allows scrubbing (dragging) the progress indicator
                                        colors: VideoProgressColors(
                                          playedColor: Colors
                                              .white, // Color of the played part of the progress indicator
                                          bufferedColor: Colors
                                              .grey, // Color of the buffered part of the progress indicator
                                          backgroundColor: Colors
                                              .transparent, // Background color of the progress indicator
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.skip_previous,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              // Move 10 seconds backward
                                              _controller.seekTo(
                                                  _controller.value.position -
                                                      Duration(seconds: 10));
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              _controller.value.isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              if (_controller.value.isPlaying) {
                                                _controller.pause();
                                              } else {
                                                _controller.play();
                                              }
                                              setState(
                                                  () {}); // Update UI to reflect play/pause state change
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.skip_next,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              // Move 10 seconds forward
                                              _controller.seekTo(
                                                  _controller.value.position +
                                                      Duration(seconds: 10));
                                            },
                                          ),
                                          Text(
                                            _formatDuration(_controller
                                                    .value.position) +
                                                " / " +
                                                _formatDuration(_controller
                                                        .value.duration ??
                                                    Duration.zero),
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _imageFile != null
                            ? SizedBox(
                                width: 300,
                                height: 400,
                                child:
                                    Image.file(_imageFile!, fit: BoxFit.cover),
                              )
                            : Container(),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => _getImage(ImageSource.gallery),
                              icon: Icon(
                                Icons.photo,
                                color: const Color.fromARGB(255, 171, 171, 171),
                              ),
                            ),
                            // IconButton(
                            //   onPressed: () => _getImage(ImageSource.camera),
                            //   icon: Icon(
                            //     Icons.camera_alt,
                            //     color: const Color.fromARGB(255, 171, 171, 171),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: '                  Enter Recipe Name',
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add Recipe steps',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 75, 75, 75),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF437D28),
                          shape: CircleBorder(),
                        ),
                        onPressed: () {
                          setState(() {
                            // Add an empty string as a placeholder for a new recipe step
                            recipeSteps.add('');
                          });
                        },
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Display text fields for recipe steps
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: recipeSteps.length,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                onChanged: (value) {
                                  // Update the recipe step in the list
                                  recipeSteps[index] = value;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Step ${index + 1}',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  // Add ingredients
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add ingredients',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 75, 75, 75),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF437D28),
                          shape: CircleBorder(),
                        ),
                        onPressed: () {
                          setState(() {
                            // Add an empty ingredient entry
                            ingredientsList
                                .add({'ingredient': '', 'quantity': ''});
                          });
                        },
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Display text fields for ingredients
                  Column(
                    children: ingredientsList.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> ingredient = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: TextField(
                                onChanged: (value) {
                                  // Update the ingredient name in the list
                                  ingredientsList[index]['name'] = value;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Ingredient Name ${index + 1}',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      onChanged: (value) {
                                        // Update the ingredient quantity in the list
                                        ingredientsList[index]['quantity'] =
                                            value;
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Qty ${index + 1}',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      width:
                                          2), // Add spacing between quantity and unit dropdown
                                  Expanded(
                                    flex: 1,
                                    child: DropdownButtonFormField<String>(
                                      value: ingredientsList[index]
                                          ['unit'], // Current value of unit
                                      onChanged: (newValue) {
                                        setState(() {
                                          ingredientsList[index]['unit'] =
                                              newValue!;
                                        });
                                      },
                                      items: <String>[
                                        'g',
                                        'kg',
                                        'ml',
                                        'l',
                                        'tsp',
                                        'tbsp',
                                        'cup',
                                        'oz',
                                        'lb',
                                        'no'
                                      ].map<DropdownMenuItem<String>>(
                                          (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Serving',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 75, 75, 75),
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF437D28),
                              shape: CircleBorder(),
                            ),
                            onPressed: decrementServing,
                            child: Icon(
                              Icons.remove,
                              color: Colors.white,
                            ),
                          ),
                          Text('$servingCount'),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF437D28),
                              shape: CircleBorder(),
                            ),
                            onPressed: incrementServing,
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Dropdown list for diet category
                  SizedBox(
                    height: 10,
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedDiet,
                    hint: Text('Select Diet Type'), // Initial hint
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDiet = newValue;
                      });
                    },
                    items: <String>[
                      'Keto',
                      'Liquid',
                      'Paleo',
                      'Vegan',
                      'Others'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),

                  // Dropdown list for occasion
                  DropdownButtonFormField<String>(
                    value: selectedOccasion,
                    hint: Text('Select Occasion'),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedOccasion = newValue;
                      });
                    },
                    items: <String>[
                      'Christmas',
                      'Diwali',
                      'Eid-al-Fitr',
                      'Onam',
                      'Others'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),

// Dropdown list for meal

                  DropdownButtonFormField<String>(
                    value: selectedMeal,
                    hint: Text('Select Meal Category'), // Initial hint
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedMeal = newValue;
                      });
                    },
                    items: <String>[
                      'Main Course',
                      'Side Dish',
                      'Dessert',
                      'Appetizer',
                      'Others'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF437D28),
                    ),
                    onPressed: () async {
                      // Check if any of the required fields are empty
                      if (_imageFile == null ||
                          _titleController.text.isEmpty ||
                          recipeSteps.isEmpty ||
                          ingredientsList.isEmpty ||
                          selectedDiet == null ||
                          selectedOccasion == null ||
                          selectedMeal == null) {
                        print('-------mandatory');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              'Please fill all fields before uploading',
                              style: TextStyle(color: Colors.white),
                            ),
                            margin: EdgeInsets.all(10),
                            backgroundColor: Colors.grey[700],
                            duration: Duration(seconds: 5),
                          ),
                        );
                        return; // Stop further execution
                      }

                      // Call _getUserEmail() to fetch the user's email
                      _getUserEmail().then((_) {
                        print('User: $_userEmail');
                        // Call uploadFile() only after retrieving the user's email
                        uploadFile();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              'Successfully uploaded recipe',
                              style: TextStyle(color: Colors.white),
                            ),
                            margin: EdgeInsets.all(10),
                            backgroundColor: Colors.grey[700],
                            duration: Duration(seconds: 5),
                          ),
                        );

                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                      'Upload',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          //),
        ));
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the video controller
    _titleController.dispose();
    super.dispose();
  }
}
