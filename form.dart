import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fraction/fraction.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class YourRecipeApp extends StatefulWidget {
  YourRecipeApp({Key? key}) : super(key: key);

  @override
  State<YourRecipeApp> createState() => _YourRecipeState();
}

class _YourRecipeState extends State<YourRecipeApp> {
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
        if (!showUploadScreen) {
          Navigator.pop(context); // Pop back when tapping outside the container
        }
      },
      child: Container(
        color: Colors
            .transparent, // Make the container transparent to allow taps through
        child: Center(
          child: showUploadScreen
              ? RecipeFormPage(
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

class RecipeFormPage extends StatefulWidget {
  final File videoFile;
  final String videoPath;
  const RecipeFormPage({
    Key? key,
    required this.videoFile,
    required this.videoPath,
  }) : super(key: key);

  @override
  _RecipeFormPageState createState() => _RecipeFormPageState();
}

class _RecipeFormPageState extends State<RecipeFormPage> {
  int currentStep = 0;
  late VideoPlayerController _controller;
  Timer? _timer;
  int recipeCounter = 7; // Initialize the recipe counter
  List<String> recipeSteps = [];
  List<Map<String, dynamic>> ingredientsList = [];
  File? _imageFile;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();

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
    prefs.setInt('recipeCounter', 6);
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
        .where(FieldPath.documentId, isEqualTo: selectedMeal!.toLowerCase())
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

  ScrollController _scrollController = ScrollController();
  void scrollToStep(int step) {
    // Calculate the position of the step
    double stepPosition = step * MediaQuery.of(context).size.height;
    // Scroll to the step position with animation
    _scrollController.animateTo(
      stepPosition,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
bool isAlphanumeric(String value) {
  final RegExp alphaNumeric = RegExp(r'^[a-zA-Z0-9]+$');
  return alphaNumeric.hasMatch(value);
}
bool isValidInteger(String value) {
  // Use a try-catch block to parse the value as an integer
  try {
    int parsedValue = int.parse(value);
    print(parsedValue);
    servingCount =parsedValue;
    return true; // If parsing succeeds, value is a valid integer
  } catch (e) {
    return false; // If parsing fails, value is not a valid integer
  }
}

 bool isThumbnailUploaded = false;
bool isRecipeNameFilled = false;
bool areStepsFilled = false;
bool areIngredientsFilled = false;
bool isServingsFilled = false;
bool isDietSelected = false;
bool isOccasionSelected = false;
bool isMealCategorySelected = false;
  bool isStepComplete(int stepIndex) {
  switch (stepIndex) {
    case 0:
      if(widget.videoFile != null && widget.videoPath.isNotEmpty){
        isThumbnailUploaded=true;
      }
      return isThumbnailUploaded; // Check if video is uploaded
    case 1:
      if(_titleController.text.isNotEmpty && isAlphanumeric(_titleController.text)){
      isRecipeNameFilled =true;
      }
      return isRecipeNameFilled; // Check if recipe name is filled
    case 2:
    if(recipeSteps.isNotEmpty && recipeSteps.every((step) => isAlphanumeric(step))){
        areStepsFilled = true;
    }
      return areStepsFilled; // Check if recipe steps are filled
    case 3:
      if(ingredientsList.isNotEmpty && ingredientsList.every(
            (ingredient) => ingredient['name'].isNotEmpty && ingredient['quantity'].isNotEmpty)){
          areIngredientsFilled=true;
      }
      return areIngredientsFilled; // Check if ingredients are filled
    case 4:
    if(_servingsController.text.isNotEmpty && isValidInteger(_servingsController.text)){
      isRecipeNameFilled =true;
      }
      return isServingsFilled; // Check if servings are filled
    case 5:
      if(selectedDiet!.isNotEmpty){
           isDietSelected=true;
      }
      return isDietSelected; // Check if diet type is selected
    case 6:
      if(selectedOccasion!.isNotEmpty){
        isOccasionSelected=true;
      }
      return isOccasionSelected; // Check if occasion is selected
    case 7:
    if(selectedMeal!.isNotEmpty){
      isMealCategorySelected=true;
    }
      return isMealCategorySelected; // Check if meal category is selected
    default:
      return false;
  }
 
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Your Recipe'),
        centerTitle: true,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary:
                Color(0xFF437D28), // Sets the primary color for the Stepper
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Stepper(
            type: StepperType.vertical,
            currentStep: currentStep,
            onStepContinue: () {
              bool isnext=isStepComplete(currentStep);
              if(isnext){
              final isLastStep = currentStep == getSteps().length - 1;
              if (isLastStep) {
                print('Complete');
              } else {
                setState(() {
                  currentStep += 1;
                  scrollToStep(currentStep); // Scroll to the next step
                });
              }
              }else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Please Complete Current Step',
                        style: TextStyle(color: Colors.white),
                      ),
                      margin: EdgeInsets.all(10),
                      backgroundColor: Colors.grey[700],
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              },
            onStepCancel: () {
              if (currentStep > 0) {
                setState(() {
                  currentStep -= 1;
                  scrollToStep(currentStep); // Scroll to the previous step
                });
              }
            },
            steps: getSteps(),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Step> getSteps() => [
        Step(
          isActive: currentStep >= 0,
          title: Text('Video'),
          content: Column(
            children: [
              Text('Add Thumbnail'),
              Stack(
                children: [
                  if (widget.videoFile != null && widget.videoPath.isNotEmpty)
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
                                        _formatDuration(
                                                _controller.value.position) +
                                            " / " +
                                            _formatDuration(
                                                _controller.value.duration ??
                                                    Duration.zero),
                                        style: TextStyle(color: Colors.white),
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
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
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
            ],
          ), // Replace with actual video content
        ),
        Step(
          isActive: currentStep >= 1,
          title: Text('Name'),
          content: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter Recipe Name',
                ),
              ),
            ),
          ),
        ),
        Step(
          title: Text('Steps'),
          content: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add Recipe Steps',
                        style: TextStyle(
                          fontSize: 16, // Adjust the font size as needed
                          //fontWeight: FontWeight.bold, // Optionally, apply bold font weight
                        ),
                      ),
                    ),
                    SizedBox(width: 30), // Add spacing between text and button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF437D28),
                        shape: CircleBorder(),
                      ),
                      onPressed: () {
                        // Handle button press action
                        // For example, add an empty recipe step
                        setState(() {
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
                    TextEditingController textEditingController =
                        TextEditingController(text: recipeSteps[index]);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: textEditingController,
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
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                // Remove the item from the list
                                recipeSteps.removeAt(index);
                              });
                            },
                            child: Icon(Icons.clear),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          isActive: currentStep >= 2,
        ),
        Step(
            isActive: currentStep >= 3,
            title: Text('Ingredients'),
            content: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF437D28),
                          shape: CircleBorder(),
                        ),
                        onPressed: () {
                          setState(() {
                            // Add an empty ingredient entry
                            ingredientsList
                                .add({'name': '', 'quantity': '', 'unit': 'g'});
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
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: ingredientsList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (value) {
                                  // Update the ingredient name in the list
                                  setState(() {
                                    ingredientsList[index]['name'] = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Ingredient Name ${index + 1}',
                                  border: OutlineInputBorder(),
                                ),
                                controller: TextEditingController(
                                    text: ingredientsList[index]['name']),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (value) {
                                  // Update the ingredient quantity in the list
                                  setState(() {
                                    ingredientsList[index]['quantity'] = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Qty ${index + 1}',
                                  border: OutlineInputBorder(),
                                ),
                                controller: TextEditingController(
                                    text: ingredientsList[index]['quantity']),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: ingredientsList[index]['unit'],
                                onChanged: (newValue) {
                                  setState(() {
                                    ingredientsList[index]['unit'] = newValue!;
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
                                  },
                                ).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            )),
        Step(
          isActive: currentStep >= 4,
          title: Text('Servings'),
          content: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: TextField(
                controller: _servingsController,
                decoration: InputDecoration(
                  hintText: 'Number of Servings',
                ),
              ),
            ),
          ),
        ),
        Step(
          isActive: currentStep >= 5,
          title: Text('Diet'),
          content: Container(
            child: DropdownButtonFormField<String>(
              value: selectedDiet,
              hint: Text('Select Diet Type'),
              onChanged: (String? newValue) {
                setState(() {
                  selectedDiet = newValue!;
                });
              },
              items: <String>['Keto', 'Liquid', 'Paleo', 'Vegan', 'Others']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
        Step(
          isActive: currentStep >= 6,
          title: Text('Occasion'),
          content: Container(
            child: DropdownButtonFormField<String>(
              value: selectedOccasion,
              hint: Text('Select Occasion'),
              onChanged: (String? newValue) {
                setState(() {
                  selectedOccasion = newValue!;
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
          ),
        ),
        Step(
          isActive: currentStep >= 7,
          title: Text('Meal Category'),
          content: Container(
            child: DropdownButtonFormField<String>(
              value: selectedMeal,
              hint: Text('Select Meal Category'),
              onChanged: (String? newValue) {
                setState(() {
                  selectedMeal = newValue!;
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
          ),
        ),
      ];
}
