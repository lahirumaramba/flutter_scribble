import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scribble/repository/prediction_repo.dart';

import 'app_events.dart';
import 'app_states.dart';

class PredictionBloc extends Bloc<PredictionEvent, PredictionState> {
  final PredictionRepository predcitionRepository;
  StreamSubscription? _predictionSubscription;

  PredictionBloc({required this.predcitionRepository}) : super(InitialState()) {
    on<EndPrediction>((event, emit) async {
      emit(PredictionCompleted());
      // Firestore
    });
    on<CreatePrediction>((event, emit) async {
      print('CreatePrediction CreatePrediction CreatePrediction');
    });
    on<GetPrediction>(_listenOnPrediction);
  }

  Future<void> _listenOnPrediction(
    GetPrediction event,
    Emitter<PredictionState> emit,
  ) async {
    _predictionSubscription?.cancel();
    _predictionSubscription =
        predcitionRepository.prediction(event.id).listen((data) {
      emit(PredictionUpdated(data));
    });
  }
}
