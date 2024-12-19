import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

part 'liveliness_detection_event.dart';
part 'liveliness_detection_state.dart';

class LivelinessDetectionBloc extends Bloc<LivelinessDetectionEvent, LivelinessDetectionState> {
  CameraController? _controller;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  bool _eyesClosedDetected = false;
  bool _headMovedRight = false;

  LivelinessDetectionBloc() : super(CameraInitializingState()) {
    // Handle StartCameraEvent
    on<StartCameraEvent>((event, emit) async {
      await _initializeCamera();
      emit(CameraInitializedState());
    });

    // Handle ProcessCameraImageEvent
    on<ProcessCameraImageEvent>((event, emit) async {
      await _processCameraImage(event.cameraImage, emit);
    });

    // Handle EyesClosedDetectedEvent
    on<EyesClosedDetectedEvent>((event, emit) {
      emit(EyesClosedState());
    });

    // Handle HeadMovedRightDetectedEvent
    on<HeadMovedRightDetectedEvent>((event, emit) {
      emit(HeadMovedRightState());
    });
  }

  // Initialize the camera and start the image stream
  Future<void> _initializeCamera() async {
    try {
      if (_controller != null) {
        await _controller!.dispose();
      }

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableContours: false,
          enableTracking: false,
          enableLandmarks: true,
          enableClassification: true,
        ),
      );

      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.ultraHigh,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _controller!.startImageStream((cameraImage) {
        add(ProcessCameraImageEvent(cameraImage)); // Trigger event for each frame
      });
    } catch (e) {
      // Handle errors (optional)
    }
  }

  // Process camera image and detect faces, eyes, and head movements
  Future<void> _processCameraImage(CameraImage cameraImage, Emitter<LivelinessDetectionState> emit) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final InputImage inputImage = _getInputImage(cameraImage);
      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;

        final leftEyeOpenProbability = face.leftEyeOpenProbability ?? 1.0;
        final rightEyeOpenProbability = face.rightEyeOpenProbability ?? 1.0;
        bool areEyesClosed = leftEyeOpenProbability < 0.3 && rightEyeOpenProbability < 0.3;

        if (areEyesClosed && !_eyesClosedDetected) {
          _eyesClosedDetected = true;
          add(EyesClosedDetectedEvent()); // Add event when eyes are closed
        }

        final headRotation = face.headEulerAngleY ?? 0.0;

        if (headRotation > 25.0 && !_headMovedRight) {
          _headMovedRight = true;
          add(HeadMovedRightDetectedEvent()); // Add event when head is moved right
        }
      }
    } catch (e) {
      // Handle error
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
}