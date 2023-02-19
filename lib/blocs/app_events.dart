import 'package:equatable/equatable.dart';

abstract class PredictionEvent extends Equatable {
  const PredictionEvent();

  @override
  List<Object> get props => [];
}

class GetPredictions extends PredictionEvent {
  const GetPredictions();
}

class CreatePrediction extends PredictionEvent {}

class EndPrediction extends PredictionEvent {}

class GetPrediction extends PredictionEvent {
  final String id;
  const GetPrediction(this.id);

  @override
  List<Object> get props => [id];
}
