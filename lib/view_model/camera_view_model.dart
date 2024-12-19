import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraViewModel extends ChangeNotifier {
  CameraController? _controller;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  bool _isFaceDetected = false;
  bool _eyesClosedDetected = false;
  bool _headMovedRight = false;
  bool _hasNavigated = false;

  CameraController? get controller => _controller;

  // Getter for navigation status
  bool get hasNavigated => _hasNavigated;
  bool get isFaceDetected => _isFaceDetected;
  bool get eyesClosedDetected => _eyesClosedDetected;
  bool get headMovedRight => _headMovedRight;

  Future<void> initializeCamera() async {
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
        if (_controller!.value.hasError) {
          debugPrint('Camera error: ${_controller!.value.errorDescription}');
        }
      });

      debugPrint('Initializing camera...');
      await _controller!.initialize();
      debugPrint('Camera initialized.');

      notifyListeners();

      await _controller!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void setNavigated(bool value) {
    _hasNavigated = value;
    notifyListeners();
  }

  void checkForNavigation() {
    if (eyesClosedDetected && headMovedRight && !_hasNavigated) {
      setNavigated(true);  // Set navigation status
    }
  }

  void _processCameraImage(CameraImage cameraImage) async {
    if (_isDetecting || _controller == null) return;
    _isDetecting = true;

    try {
      final InputImage inputImage = _getInputImage(cameraImage);
      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      _isFaceDetected = faces.isNotEmpty;
      notifyListeners();

      if (faces.isNotEmpty) {
        final face = faces.first;

        final leftEyeOpenProbability = face.leftEyeOpenProbability ?? 1.0;
        final rightEyeOpenProbability = face.rightEyeOpenProbability ?? 1.0;

        bool areEyesClosed =
            leftEyeOpenProbability < 0.3 && rightEyeOpenProbability < 0.3;

        if (areEyesClosed && !_eyesClosedDetected) {
          _eyesClosedDetected = true;
          notifyListeners();
        }

        if (_eyesClosedDetected) {
          final headRotation = face.headEulerAngleY ?? 0.0;

          if (headRotation > 25.0 && !_headMovedRight) {
            _headMovedRight = true;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing camera image: $e');
    } finally {
      _isDetecting = false;
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

  void disposeCamera() {
    // _controller?.dispose();
    _faceDetector?.close();
  }
  void diposeController(){
    _controller?.dispose();
  }
}
