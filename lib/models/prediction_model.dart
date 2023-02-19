import 'package:equatable/equatable.dart';

class PredictionModel extends Equatable {
  final String inputImageUrl;
  final String outputImageUrl;
  final String prompt;
  final String id;

  const PredictionModel(
      {required this.id,
      required this.prompt,
      required this.inputImageUrl,
      required this.outputImageUrl});

  static PredictionModel fromMap(Map<String, dynamic> data) {
    return PredictionModel(
      inputImageUrl: data['input'] ?? '',
      outputImageUrl: data['output'] ?? '',
      prompt: data['prompt'] ?? '',
      id: data['id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'input': inputImageUrl,
      'output': outputImageUrl,
      'prompt': prompt,
      'id': id,
    };
  }

  @override
  String toString() {
    return 'PredictionModel{id: $id, inputImageUrl: $inputImageUrl, outputImageUrl: $outputImageUrl prompt: $prompt}';
  }

  @override
  List<Object?> get props => [id, inputImageUrl, outputImageUrl, prompt];
}
