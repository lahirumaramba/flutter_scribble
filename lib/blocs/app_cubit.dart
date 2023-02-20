import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scribble/blocs/app_states.dart';
import 'package:flutter_scribble/models/prediction_model.dart';
import 'package:flutter_scribble/repository/prediction_repo.dart';
import 'package:flutter_scribble/services/backend_service.dart';
import 'package:get_it/get_it.dart';

class AppCubit extends Cubit<PredictionState> {
  final PredictionRepository _predcitionRepository = GetIt.instance();
  final BackendService _backendService = GetIt.instance();
  StreamSubscription? _predictionSubscription;

  AppCubit() : super(InitialState());

  void init() {
    emit(InitialState());
  }

  Future<void> listenToPrediction(String id) async {
    // Subscribe to listen for changes in the prediction state
    _predictionSubscription?.cancel();
    _predictionSubscription = _predcitionRepository
        .onPredictionUpdated(id)
        .listen(_predictionChanged);
  }

  Future<void> createPrediction(String imageData, String prompt) async {
    final pid = await _backendService.createPrediction(imageData, prompt);
    pid == null ? emit(PredictionStopped()) : emit(PredictionStarted(pid));
  }

  void startPrediction(String prompt) {
    emit(PredictionTriggered(prompt));
  }

  void _predictionChanged(PredictionModel data) {
    emit(PredictionUpdated(data));
    if (data.outputImageUrl.isNotEmpty) {
      emit(PredictionCompleted());
    }
  }

  @override
  Future<void> close() {
    _predictionSubscription?.cancel();
    return super.close();
  }
}
