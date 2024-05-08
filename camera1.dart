import 'camera_search.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
  bool isLoading=true;
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
      labels: 'assets/models/best_label.txt',
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
          imageHeight: img.height,
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
        title: Text("What's in your kitchen"),
      ),
      body: Stack(
        children: <Widget>[
          // Camera Preview Widget
          if (isCameraInitialized)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: CameraPreview(controller),
              ),
            ),

          // Display detected labels at the bottom
          if (detectedLabels.isNotEmpty)
            Positioned(
              bottom: 46.0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
                color: Colors.transparent,
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
                          backgroundColor: Colors.black.withOpacity(0.5),
                          deleteIconColor: Colors.white,
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

          // Loading Indicator (Dotted Fading Circle Animation)
          // if (isLoading)
          //   Positioned.fill(
          //     child: Center(
          //       child:  SpinKitFadingCircle(
          //         color: Colors.white,
          //         size: 100.0,
          //       ),
          //     ),
          //   ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          
          // Simulate a delay (replace this with your actual logic)
          Future.delayed(Duration(seconds: 2), () {
            // Navigate to CameraSearch
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (ctx) {
                  return CameraSearch(documentIds: detectedLabels);
                },
              ),
            );
            setState(() {
              isLoading = false; // Hide loading indicator
            });
          });
        },
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey[800],
        elevation: 0.0,
        shape: CircleBorder(), // Use CircleBorder for circular shape
        child: Icon(
          Icons.stop_circle_outlined,
          size: 70,
        ), // Change to camera capture icon
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
