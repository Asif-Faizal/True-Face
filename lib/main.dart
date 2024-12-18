import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get available cameras
  final cameras = await availableCameras();

  // Select front camera
  final frontCamera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras.first, // Fallback to first camera if no front camera
  );

  runApp(MyApp(camera: frontCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraPage(camera: camera),
    );
  }
}

class CameraPage extends StatefulWidget {
  final CameraDescription camera;

  const CameraPage({super.key, required this.camera});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  bool _isFaceDetected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Dispose of existing controller if any
      if (_controller != null) {
        await _controller!.dispose();
      }

      // Reinitialize face detector
      _faceDetector ??= FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableContours: false,
          enableTracking: false,
          enableLandmarks: true,  // Ensure landmarks are enabled
          enableClassification: true,
        ),
      );

      // Create new camera controller
      _controller = CameraController(
        widget.camera,
        ResolutionPreset.ultraHigh,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Add listener to detect errors
      _controller!.addListener(() {
        if (mounted && _controller!.value.hasError) {
          print('Camera error: ${_controller!.value.errorDescription}');
        }
      });

      // Initialize the controller and start image stream
      await _controller!.initialize();
      if (mounted) {
        setState(() {}); // Trigger UI rebuild after initialization
        await _controller!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  void _processCameraImage(CameraImage cameraImage) async {
    if (_isDetecting || _controller == null) return;
    _isDetecting = true;

    try {
      // Convert image to InputImage for ML Kit
      final InputImage inputImage = _getInputImage(cameraImage);

      // Detect faces
      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      if (mounted) {
        setState(() {
          _isFaceDetected = faces.isNotEmpty;
        });
      }

      if (faces.isNotEmpty) {
        final face = faces.first;

        // Log eye probabilities for debugging
        final leftEyeOpenProbability = face.leftEyeOpenProbability ?? 1.0;
        final rightEyeOpenProbability = face.rightEyeOpenProbability ?? 1.0;

        print('Left Eye Open Probability: $leftEyeOpenProbability');
        print('Right Eye Open Probability: $rightEyeOpenProbability');

        // Adjust the threshold as needed
        bool areEyesClosed =
            leftEyeOpenProbability < 0.3 && rightEyeOpenProbability < 0.3;

        if (areEyesClosed) {
          // Navigate to the next page immediately when eyes are closed
          _onEyesClosed();
        }
      }
    } catch (e) {
      print('Error processing camera image: $e');
    } finally {
      _isDetecting = false;
    }
  }

  void _onEyesClosed() {
    // Navigate to the next page when eyes are closed
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SecondPage()),
      );
    }
  }

  InputImage _getInputImage(CameraImage cameraImage) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // Metadata for ML Kit's InputImage
    final InputImageMetadata metadata = InputImageMetadata(
      size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
      rotation: InputImageRotation.rotation0deg, // Adjust if necessary
      format: InputImageFormat.nv21, // Use nv21 or the appropriate format
      bytesPerRow: cameraImage.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Face Detection & Eye Closure')),
      body: Stack(
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            CameraPreview(_controller!),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Face Detected: ${_isFaceDetected ? 'Yes' : 'No'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second Page')),
      body: const Center(child: Text('Eyes were closed!')),
    );
  }
}
