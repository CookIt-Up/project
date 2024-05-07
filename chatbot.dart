import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Message.dart';

class ChatbotApp extends StatelessWidget {
  const ChatbotApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatBot',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late DialogFlowtter dialogFlowtter;
  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> messages = [];

  void initState() {
    DialogFlowtter.fromFile().then((instance) => dialogFlowtter = instance);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFD1E7D2),
        title:Text("Let's Chat")
      ),
      backgroundColor: Color(0xFFD1E7D2),
      body: Container(
        child: Column(
          children: [
            Expanded(child: MessagesScreen(messages: messages)),
            Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 71, 119, 74),
                borderRadius: BorderRadius.circular(
                    17), // Set border radius to make sides rounded
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: Color.fromARGB(255, 41, 41, 41)),
                      decoration: InputDecoration(
                        hintText: 'Message CookItUp...',
                        hintStyle: TextStyle(
                          color: Colors.white70,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal:
                                20), // Move text a little bit to the right
                        border: InputBorder.none,
                      ),
                      onSubmitted: (String text) {
                        sendMessage(text);
                        _controller.clear();
                      },
                      autofocus: true,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      sendMessage(_controller.text);
                      _controller.clear();
                    },
                    icon: Icon(Icons.send),
                    color: Colors.white70,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  sendMessage(String text) async {
    if (text.isEmpty) {
      print('Message is empty');
    } else {
      setState(() {
        addMessage(Message(text: DialogText(text: [text])), true);
      });

      // Check if the message contains "okay" or "ok"
      if (text.toLowerCase().contains('okay') ||
          text.toLowerCase().contains('ok') ||
          text.toLowerCase() == 'k' ||
          text.toLowerCase() == 'kk') {
        // Ask for the target calories
        setState(() {
          addMessage(
              Message(
                  text: DialogText(text: [
                'Sure! What is your desired target calories for the meal plan?'
              ])),
              false);
        });
      } else {
        // Check if the message contains a number
        final containsNumber = RegExp(r'\b\d+\b').hasMatch(text);
        if (containsNumber) {
          // Extract the number from the text
          final extractedNumber = double.tryParse(text);
          if (extractedNumber != null) {
            // _controller.clear();
            setState(() {
              addMessage(
                  Message(
                      text: DialogText(text: [
                    'Would you like the meal plan for a day or a week?'
                  ])),
                  false);
              final String cleanedText =
                  text.replaceAll(RegExp(r'\b\d+\b'), '');
              _controller.text = cleanedText;
              text = cleanedText; // Update the text variable
              _controller.clear();
            });

            //  await handleUserInput(_controller.text, extractedNumber);
            // Wait for the user's response
            // print(cleanedText);

            Map<String, dynamic> response = await getUserResponse();
            String userResponse = response['response'];
            String diet = response['diet'];

            // Handle the user's response
            await handleUserInput(userResponse, extractedNumber, diet);
          } else {
            // If parsing fails, continue with Dialogflow
            await fetchDialogFlowResponse(text);
          }
        } else {
          // Check if the message is "day" or "week"
          final lowerCaseText = text.trim().toLowerCase();
          if (lowerCaseText == 'day' || lowerCaseText == 'week') {
            handleUserInput(lowerCaseText, 200, 'vegan');
          } else {
            // If the message is neither a number, "day", nor "week", continue with Dialogflow
            await fetchDialogFlowResponse(text);
          }
        }
      }
    }
  }

  Future<Map<String, dynamic>> getUserResponse() async {
    // Initialize the response variables
    String? userResponse;
    String? selectedDiet;

    // Show a dialog with a text input field and a dropdown for diet selection
    Map<String, dynamic>? response = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController controller = TextEditingController();
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                'Customize your meal plan',
                style: TextStyle(fontSize: 18), // Reduce the text size
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: controller,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Enter "day" or "week"',
                      hintStyle: TextStyle(color: Colors.black),
                    ),
                    autofocus: true,
                  ),
                  SizedBox(height: 20),
                  DropdownButton<String>(
                    hint: Text('Select your diet',
                        style: TextStyle(color: Colors.black)),
                    value: selectedDiet,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDiet = newValue;
                      });
                    },
                    dropdownColor: Color.fromARGB(255, 175, 187, 163),
                    focusColor: Colors
                        .transparent, // Set focus color to transparent to remove highlighting effect
                    focusNode: FocusNode(skipTraversal: true),
                    items: <String>[
                      'Gluten Free',
                      'Ketogenic',
                      'Vegetarian',
                      'Lacto-Vegetarian',
                      'Ovo-Vegetarian',
                      'Vegan',
                      'Pescetarian',
                      'Paleo',
                      'Primal',
                      'Low FODMAP',
                      'Whole30'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child:
                      Text('Cancel', style: TextStyle(color: Colors.grey[700])),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('OK', style: TextStyle(color: Colors.grey[700])),
                  onPressed: selectedDiet == null
                      ? null // Disable the button if no option is selected
                      : () {
                          Navigator.of(context).pop({
                            'response': controller.text.trim().toLowerCase(),
                            'diet': selectedDiet,
                          });
                        },
                ),
              ],
              backgroundColor: Colors.lightGreen[100],
            );
          },
        );
      },
    );
    // Return the user's response
    return response ?? {'response': '', 'diet': ''};
  }

  Future<void> handleUserInput(
      String response, double extractedNumber, String diet) async {
    String timeFrame = '';

    // Convert the response to lowercase for consistency
    final lowerCaseResponse = response.toLowerCase();

    if (lowerCaseResponse == 'day' || lowerCaseResponse == 'week') {
      // If the response is "day" or "week", store it in the timeFrame variable
      timeFrame = lowerCaseResponse;

      // Fetch meals based on the selected time frame
      await fetchSpoonacularData(timeFrame, extractedNumber, diet);
    } else {
      // If the response is neither "day" nor "week", inform the user that the response is invalid
      addMessage(
        Message(
            text: DialogText(text: [
          'Response cancelled. Please enter your calorie goal for the diet plan.'
        ])),
        false,
      );
    }
  }

  Future<void> fetchSpoonacularData(
      String timeFrame, double? extractedNumber, String diet) async {
    try {
      final String apiKey =
          'ff15ea2a66ad401ab0aa564496ceaaa6'; // Replace with your Spoonacular API key
      final int maxFat = 25;
      print(extractedNumber);
      print(timeFrame);
      print(diet);
      final response = await http.get(
        Uri.parse(
          'https://api.spoonacular.com/mealplanner/generate?timeFrame=$timeFrame&targetCalories=$extractedNumber&diet=$diet&maxFat=$maxFat&apiKey=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        String mealPlanMessage = '';
        if (timeFrame == 'day') {
          // Handle day timeframe response
          List<dynamic> meals = jsonData['meals'];
          mealPlanMessage = 'Your meal plan for the day:\n';
          for (var meal in meals) {
            String mealTitle = meal['title'];
            mealPlanMessage += '- $mealTitle\n';
          }
        } else if (timeFrame == 'week') {
          // Handle week timeframe response
          Map<String, dynamic> weekData = jsonData['week'];
          weekData.forEach((key, value) {
            mealPlanMessage += 'Meals for $key:\n';
            List<dynamic> meals = value['meals'];
            for (var meal in meals) {
              String mealTitle = meal['title'];
              mealPlanMessage += '- $mealTitle\n';
            }
            mealPlanMessage += '\n'; // Add newline for readability
          });
        }

        // Set state to add message to the chat
        setState(() {
          addMessage(Message(text: DialogText(text: [mealPlanMessage])), false);
        });
      } else {
        print(
            'Failed to fetch data from Spoonacular API. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching data from Spoonacular API: $e');
    }
  }

  Future<void> fetchDialogFlowResponse(String text) async {
    try {
      // Call Dialogflow API to get response
      DetectIntentResponse response = await dialogFlowtter.detectIntent(
        queryInput: QueryInput(text: TextInput(text: text)),
      );

      // Add Dialogflow response to messages
      setState(() {
        addMessage(response.message!);
      });
    } catch (e) {
      print('Error fetching data from Dialogflow: $e');
    }
  }

  addMessage(Message message, [bool isUserMessage = false]) {
    setState(() {
      messages.add({'message': message, 'isUserMessage': isUserMessage});
    });
  }
}