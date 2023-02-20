import 'package:equatable/equatable.dart';
import 'package:flutter_scribble/models/prediction_model.dart';

abstract class PredictionState extends Equatable {
  const PredictionState();

  @override
  List<Object> get props => [];
}

class InitialState extends PredictionState {}

class PredictionTriggered extends PredictionState {
  final String prompt;
  const PredictionTriggered(this.prompt);

  @override
  List<Object> get props => [prompt];
}

class PredictionStarted extends PredictionState {
  final String id;
  const PredictionStarted(this.id);

  @override
  List<Object> get props => [id];
}

class PredictionUpdated extends PredictionState {
  final PredictionModel data;
  const PredictionUpdated(this.data);

  @override
  List<Object> get props => [data];
}

class PredictionStopped extends PredictionState {}

class PredictionCompleted extends PredictionState {}

class PredictionsLoading extends PredictionState {}

class PredictionsLoaded extends PredictionState {
  final List<PredictionModel> data;
  const PredictionsLoaded(this.data);

  @override
  List<Object> get props => [data];
}
