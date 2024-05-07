import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  final List messages;
  const MessagesScreen({Key? key, required this.messages}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    return ListView.separated(
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage:
                      AssetImage('assets/bot_image.jpeg'), // Bot image
                  radius: 20,
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                      topLeft: Radius.circular(20),
                    ),
                    color: Color.fromARGB(255, 93, 129, 92).withOpacity(0.8),
                  ),
                  constraints: BoxConstraints(maxWidth: w * 2 / 3),
                  child: Text(
                    "Welcome to CookItUp meal planner chatbot! Let's start the meal planning journey by setting your desired calorie target!.",
                  ),
                ),
              ],
            ),
          );
        } else {
          final message = widget.messages[index - 1]['message'];
          final isUserMessage = widget.messages[index - 1]['isUserMessage'];

          return Container(
            margin: EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: isUserMessage
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!isUserMessage) ...[
                  CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/bot_image.jpeg'), // Bot image
                    radius: 20,
                  ),
                  SizedBox(width: 8),
                ],
                Container(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(
                          widget.messages[index - 1]['isUserMessage'] ? 0 : 20),
                      topLeft: Radius.circular(
                          widget.messages[index - 1]['isUserMessage'] ? 20 : 0),
                    ),
                    color: widget.messages[index - 1]['isUserMessage']
                        ? Color.fromARGB(255, 170, 219, 180)
                        : Color.fromARGB(255, 93, 129, 92).withOpacity(0.8),
                  ),
                  constraints: BoxConstraints(maxWidth: w * 2 / 3),
                  child: Text(
                    widget.messages[index - 1]['message'].text.text[0],
                  ),
                ),
                if (isUserMessage) ...[
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/user_image.jpg'), // User image
                    radius: 20,
                  ),
                ],
              ],
            ),
          );
        }
      },
      separatorBuilder: (_, i) => Padding(padding: EdgeInsets.only(top: 10)),
      itemCount: widget.messages.length + 1, // Add 1 for the welcome message
    );
  }
}