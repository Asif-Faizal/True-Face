
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'second_screen.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

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
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras found on the device');
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      debugPrint('Selected camera: ${frontCamera.name}');
      debugPrint('Camera lens direction: ${frontCamera.lensDirection}');

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
        frontCamera,
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

        if (_eyesClosedDetected) {
          final headRotation = face.headEulerAngleY ?? 0.0;
          debugPrint('Head Rotation: $headRotation');

          if (headRotation > 25.0 && !_headMovedRight) {
            setState(() {
              _headMovedRight = true;
            });
            _onHeadMovedRight();
            await _controller!.stopImageStream();
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing camera image: $e');
    } finally {
      _isDetecting = false;
    }
  }

  void _onEyesClosed() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        content: Text('Blink has been detected'),
      ));
    }
  }

  void _onHeadMovedRight() {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SecondPage(
            onReturn: () {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const CameraPage()));
            },
          ),
        ),
      );
    }
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
                    borderRadius:
                        BorderRadius.circular(_isFaceDetected ? 15 : 13),
                    border: Border.all(
                        width: _isFaceDetected ? 5 : 3,
                        color: _isFaceDetected ? Colors.green : Colors.red),
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
                          Icon(
                            _eyesClosedDetected ? Icons.done : Icons.close,
                            color: _eyesClosedDetected
                                ? Colors.green
                                : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Blink Detected',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            _headMovedRight ? Icons.done : Icons.close,
                            color:
                                _headMovedRight ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Head Movement',
                            style: TextStyle(color: Colors.white),
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