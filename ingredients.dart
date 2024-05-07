import 'package:cookitup/camera_search.dart';
import 'package:cookitup/form.dart';
import 'package:cookitup/grocery.dart';
import 'package:cookitup/home.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SelectionPage extends StatefulWidget {
  @override
  _SelectionPageState createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  Set<String> detectedLabels = {};

  void toggleSelection(String item) {
    setState(() {
      if (detectedLabels.contains(item)) {
        detectedLabels.remove(item);
      } else {
        detectedLabels.add(item);
      }
    });
  }

  bool isItemSelected(String item) {
    return detectedLabels.contains(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD1E7D2),
      appBar: AppBar(
        //title: Text('Select Items'),
        backgroundColor: Color(0xFFD1E7D2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Fruits', ['apple', 'banana', 'orange']),
            _buildSection('Vegetables', ['carrot', 'potato', 'tomato', 'onion']),
            _buildSection('Pantry Essentials', ['rice', 'pasta', 'beans']),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: detectedLabels.isNotEmpty ? () => _applySelection() : null,
              child: Text(
                'Apply',
                style: TextStyle(
                  color: detectedLabels.isNotEmpty ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 65,
        color: Color(0xFFD1E7D2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Home()),
                );
              
              },
              icon: Icon(Icons.home),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/filter');
              },
              icon: FaIcon(
                FontAwesomeIcons.seedling,
                size: 20,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => YourRecipeApp()),
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
                Navigator.pushNamed(context, '/chatbot');
              },
              icon: Icon(Icons.person_4_sharp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: items.map((item) {
            bool isSelected = isItemSelected(item);
            return GestureDetector(
              onTap: () {
                toggleSelection(item);
              },
              child: Chip(
                label: Text(item),
                backgroundColor: isSelected ? Colors.green[200] : Color(0xFFD1E7D2),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  void _applySelection() {
    // Implement your logic for applying the selected items here
    print('Applying selected items: $detectedLabels');
    // Optionally, you can reset the selection after applying
    setState(() {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) {
            return CameraSearch(documentIds: detectedLabels);
          },
        ),
      );
    });
  }
}
