import 'package:equatable/equatable.dart';
import 'package:flutter_scribble/models/prediction_model.dart';

abstract class PredictionState extends Equatable {
  const PredictionState();

  @override
  List<Object> get props => [];
}

class InitialState extends PredictionState {}

class PredictionStarted extends PredictionState {}

class PredictionUpdated extends PredictionState {
  final PredictionModel data;
  const PredictionUpdated(this.data);

  @override
  List<Object> get props => [data];
}

class PredictionCompleted extends PredictionState {}

class PredictionsLoading extends PredictionState {}

class PredictionsLoaded extends PredictionState {
  final List<PredictionModel> data;
  const PredictionsLoaded(this.data);

  @override
  List<Object> get props => [data];
}
