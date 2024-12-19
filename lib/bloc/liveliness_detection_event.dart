part of 'liveliness_detection_bloc.dart';

sealed class LivelinessDetectionEvent extends Equatable {
  const LivelinessDetectionEvent();

  @override
  List<Object> get props => [];
}
class StartCameraEvent extends LivelinessDetectionEvent {}

class ProcessCameraImageEvent extends LivelinessDetectionEvent {
  final CameraImage cameraImage;

  const ProcessCameraImageEvent(this.cameraImage);

  @override
  List<Object> get props => [cameraImage];
}

class EyesClosedDetectedEvent extends LivelinessDetectionEvent {}

class HeadMovedRightDetectedEvent extends LivelinessDetectionEvent {}