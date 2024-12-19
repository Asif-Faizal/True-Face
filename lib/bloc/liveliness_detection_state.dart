part of 'liveliness_detection_bloc.dart';

abstract class LivelinessState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LivelinessInitial extends LivelinessState {}

class LivelinessLoading extends LivelinessState {}

class FaceDetected extends LivelinessState {}

class BlinkDetected extends LivelinessState {}

class HeadMovementDetected extends LivelinessState {}

class LivelinessError extends LivelinessState {
  final String message;

  LivelinessError(this.message);

  @override
  List<Object?> get props => [message];
}