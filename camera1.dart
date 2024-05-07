import 'dart:math';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:tflite/tflite.dart';
import 'camera_search.dart';
import 'package:flutter_vision/flutter_vision.dart';
enum Options { none, imagev5, vision }

late List<CameraDescription> cameras;
// Define a global variable to store the list of cameras
class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController controller;
  bool isModelRunning = false;
  bool isCameraInitialized = false;
  String result = "";
  Set<String> detectedLabels = {};
  late FlutterVision vision;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }
   getCameras() async {
  // Get the available cameras
  cameras = await availableCameras();
}
  initializeCamera() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await getCameras();
      await loadVisionModel();
      controller = CameraController(cameras[0], ResolutionPreset.medium);
      await controller.initialize();
      setState(() {
        isCameraInitialized = true;
      });
      controller.startImageStream((CameraImage img) {
        runModel(img);
      });
    } catch (e) {
      print("Error initializing camera: $e");
      setState(() {
        isCameraInitialized = false;
      });
    }
  }

  loadVisionModel() async {
    // Load the YOLO model using FlutterVision
    vision = FlutterVision();
    await vision.loadYoloModel(
      labels: 'assets/models/best_labels.txt',
      modelPath: 'assets/models/best_float16.tflite',
      modelVersion: "yolov5",
      quantization: true,
      numThreads: 2,
      useGpu: true,
    );
  }

  void runModel(CameraImage img) async {
  // Check if the widget is still mounted
  if (!mounted || img == null) {
    return;
  }

  // Check if the model is already running
  if (isModelRunning) {
    return;
  }

  // Set the flag to indicate that the model is running
  isModelRunning = true;

  try {
    
    
      final output = await vision.yoloOnFrame(
        bytesList: img.planes.map((plane) => plane.bytes).toList(),
        imageHeight:img.height,
        imageWidth: img.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5);

      // Process the output...
    

      // Initialize an empty list to store the labels
      List<String> labels = [];

      // Extract labels from the output
      output.forEach((result) {
        labels.add(result['tag']);
      });

      // Set the state and update the result, only if the widget is still mounted
      if (mounted) {
        setState(() {
          detectedLabels.addAll(labels);
          result = labels.join('\n');
          print(detectedLabels);
        });
      }
    
  } catch (e) {
    // Handle any errors
    print("Error running model: $e");
  } finally {
    // Reset the flag to indicate that the model is not running anymore
    isModelRunning = false;
  }
}

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
   Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("What's in Your Kitchen"),
      ),
      body: Stack(
        fit: StackFit.expand, // Ensure the Stack fills the entire screen
        children: <Widget>[
          // Camera Preview or Placeholder
          if (isCameraInitialized)
            Positioned.fill(
              child: CameraPreview(controller),
            ),
          // Circular Fading Dots Animation
          if (isModelRunning)
            Positioned.fill(
              child: Center(
                child: CircularFadingDotsAnimation(
                  dotCount: 8,
                  radius: 50.0, // Adjust radius as needed
                  dotSize: 10.0, // Adjust dot size as needed
                  dotColor: Colors.white,
                  duration: Duration(seconds: 1),
                ),
              ),
            ),
          // Detected Labels Container
          Positioned(
            bottom: 16.0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: Colors.black54,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: detectedLabels.map((label) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text(
                          label,
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Color(0xFFD1E7D2),
                        deleteIconColor: Colors.black,
                        onDeleted: () {
                          setState(() {
                            detectedLabels.remove(label);
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          // Stop Button
          Positioned(
            bottom: 16.0,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (ctx) {
                        return CameraSearch(documentIds: detectedLabels);
                      },
                    ),
                  );
                },
                backgroundColor: Color(0xFFD1E7D2),
                foregroundColor: Colors.white,
                elevation: 3.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text("Stop"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CircularFadingDotsAnimation extends StatefulWidget {
  final int dotCount;
  final double radius;
  final double dotSize;
  final Color dotColor;
  final Duration duration;

  const CircularFadingDotsAnimation({
    Key? key,
    required this.dotCount,
    required this.radius,
    required this.dotSize,
    required this.dotColor,
    required this.duration,
  }) : super(key: key);

  @override
  _CircularFadingDotsAnimationState createState() =>
      _CircularFadingDotsAnimationState();
}

class _CircularFadingDotsAnimationState
    extends State<CircularFadingDotsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.radius * 2,
      height: widget.radius * 2,
      child: Stack(
        children: List.generate(widget.dotCount, (index) {
          final angle = 2 * pi * (index / widget.dotCount);
          final double x = widget.radius * cos(angle);
          final double y = widget.radius * sin(angle);

          return Positioned(
            left: widget.radius + x,
            top: widget.radius + y,
            child: FadeTransition(
              opacity: _controller.drive(
                Tween(begin: 0.0, end: 1.0).chain(
                  CurveTween(
                    curve: Interval(
                      (1 / widget.dotCount) * index,
                      (1 / widget.dotCount) * (index + 1),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ),
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.dotColor,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
