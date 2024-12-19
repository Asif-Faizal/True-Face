part of 'liveliness_detection_bloc.dart';

sealed class LivelinessDetectionState extends Equatable {
  const LivelinessDetectionState();
  
  @override
  List<Object> get props => [];
}

class CameraInitializingState extends LivelinessDetectionState {}

class CameraInitializedState extends LivelinessDetectionState {}

class FaceDetectedState extends LivelinessDetectionState {}

class EyesClosedState extends LivelinessDetectionState {}

class HeadMovedRightState extends LivelinessDetectionState {}