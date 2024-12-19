part of 'liveliness_detection_bloc.dart';

abstract class LivelinessEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartLivelinessDetection extends LivelinessEvent {}

class StopLivelinessDetection extends LivelinessEvent {}

class FaceDetectedEvent extends LivelinessEvent {}

class BlinkDetectedEvent extends LivelinessEvent {}

class HeadMovementDetectedEvent extends LivelinessEvent {}

class LivelinessErrorEvent extends LivelinessEvent {
  final String message;

  LivelinessErrorEvent(this.message);

  @override
  List<Object?> get props => [message];
}