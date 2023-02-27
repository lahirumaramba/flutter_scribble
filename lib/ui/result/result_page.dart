import 'package:flutter/material.dart';
import 'package:flutter_scribble/models/prediction_model.dart';
import 'package:flutter_scribble/repository/prediction_repo.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_gifs/loading_gifs.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key, required this.id});

  final String id;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final PredictionRepository _predictionRepository = GetIt.instance();
  PredictionModel? _predictionModel;

  @override
  void initState() {
    _getPredicitonResult();
    super.initState();
  }

  void _getPredicitonResult() async {
    if (widget.id.isNotEmpty) {
      final result = await _predictionRepository.getPrediction(widget.id);
      setState(() {
        _predictionModel = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
            child: ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Create Your Own'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _predictionModel == null
                    ? [
                        const Center(
                          child: Text(
                            'Uh oh, we could not find the results you were looking for.',
                          ),
                        ),
                      ]
                    : buildResults(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> buildResults() {
    final prediction = _predictionModel!;
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 8.0, 20.0),
              child: Container(
                color: const Color.fromARGB(200, 255, 255, 255),
                child: FadeInImage.assetNetwork(
                    fit: BoxFit.contain,
                    placeholder: circularProgressIndicatorSmall,
                    image: prediction.inputImageUrl,
                    placeholderScale: 5),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 20.0, 20.0, 20.0),
              child: prediction.outputImageUrl.isEmpty
                  ? Image.asset(circularProgressIndicatorSmall)
                  : FadeInImage.assetNetwork(
                      fit: BoxFit.contain,
                      placeholder: circularProgressIndicatorSmall,
                      image: prediction.outputImageUrl,
                      placeholderScale: 5),
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 20.0, left: 10.0),
        child: Text(prediction.prompt.toUpperCase()),
      ),
    ];
  }
}
