import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'liveliness_detection_event.dart';
part 'liveliness_detection_state.dart';

class LivelinessBloc extends Bloc<LivelinessEvent, LivelinessState> {
  LivelinessBloc() : super(LivelinessInitial()) {
    on<StartLivelinessDetection>((event, emit) {
      emit(LivelinessLoading());
    });

    on<FaceDetectedEvent>((event, emit) {
      emit(FaceDetected());
    });

    on<BlinkDetectedEvent>((event, emit) {
      emit(BlinkDetected());
    });

    on<HeadMovementDetectedEvent>((event, emit) {
      emit(HeadMovementDetected());
    });

    on<LivelinessErrorEvent>((event, emit) {
      emit(LivelinessError(event.message));
    });
  }
}