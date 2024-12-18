import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final frontCamera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras.first,
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
  bool _eyesClosedDetected = false;
  bool _headMovedRight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      if (_controller != null) {
        await _controller!.dispose();
      }

      _faceDetector ??= FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableContours: false,
          enableTracking: false,
          enableLandmarks: true,
          enableClassification: true,
        ),
      );

      _controller = CameraController(
        widget.camera,
        ResolutionPreset.ultraHigh,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller!.addListener(() {
        if (mounted && _controller!.value.hasError) {
          debugPrint('Camera error: ${_controller!.value.errorDescription}');
        }
      });
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
        await _controller!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _processCameraImage(CameraImage cameraImage) async {
    if (_isDetecting || _controller == null) return;
    _isDetecting = true;

    try {
      final InputImage inputImage = _getInputImage(cameraImage);
      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      if (mounted) {
        setState(() {
          _isFaceDetected = faces.isNotEmpty;
        });
      }

      if (faces.isNotEmpty) {
        final face = faces.first;

        final leftEyeOpenProbability = face.leftEyeOpenProbability ?? 1.0;
        final rightEyeOpenProbability = face.rightEyeOpenProbability ?? 1.0;

        debugPrint('Left Eye Open Probability: $leftEyeOpenProbability');
        debugPrint('Right Eye Open Probability: $rightEyeOpenProbability');
        bool areEyesClosed =
            leftEyeOpenProbability < 0.3 && rightEyeOpenProbability < 0.3;

        if (areEyesClosed && !_eyesClosedDetected) {
          setState(() {
            _eyesClosedDetected = true;
          });
          _onEyesClosed();
        }

        final headRotation = face.headEulerAngleY ?? 0.0;
        debugPrint('Head Rotation: $headRotation');

        // If head is tilted right (consider threshold)
        if (headRotation > 25.0 && !_headMovedRight) {
          setState(() {
            _headMovedRight = true;
          });
          _onHeadMovedRight();
          await _controller!.stopImageStream();
        }
      }
    } catch (e) {
      print('Error processing camera image: $e');
    } finally {
      _isDetecting = false;
    }
  }

  void _onEyesClosed() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Eyes Closed Detected'),
            content: const Text('Please move your head to the right.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _onHeadMovedRight() {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SecondPage(
            onReturn: _resetStates, // Pass reset callback to SecondPage
          ),
        ),
      );
    }
  }

  // New method to reset all states
  void _resetStates() {
    setState(() {
      _isFaceDetected = false;
      _eyesClosedDetected = false;
      _headMovedRight = false;
      _isDetecting = false;
    });
  }

  InputImage _getInputImage(CameraImage cameraImage) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final InputImageMetadata metadata = InputImageMetadata(
      size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
      rotation: InputImageRotation.rotation0deg,
      format: InputImageFormat.nv21,
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Stack(
            children: [
              if (_controller != null && _controller!.value.isInitialized)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_isFaceDetected? 12:11),
                    border: Border.all(
                      width: _isFaceDetected? 2:1, color:_isFaceDetected? Colors.green :Colors.red
                    )
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CameraPreview(_controller!)),
                ),
              Positioned(
                top: 22,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(_eyesClosedDetected ? Icons.done: Icons.close,color: _eyesClosedDetected ? Colors.green :Colors.red,size: 16,),
                          SizedBox(width: 10,),
                          Text(
                            'Blink Detected',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      SizedBox(height: 5,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(_headMovedRight ? Icons.done: Icons.close,color: _headMovedRight ? Colors.green :Colors.red,size: 16,),
                          SizedBox(width: 10,),
                          Text(
                            'Head Movement',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  final VoidCallback onReturn;

  const SecondPage({super.key, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Page'),
        leading: BackButton(
          onPressed: () {
            onReturn();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: const Center(child: Text('Eyes were closed and head moved right!')),
    );
  }
}