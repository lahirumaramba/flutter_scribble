import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scribble/blocs/app_cubit.dart';
import 'package:flutter_scribble/blocs/app_states.dart';
import 'package:flutter_scribble/models/prediction_model.dart';
import 'package:flutter_scribble/ui/draw/drawing_page.dart';
import 'package:loading_gifs/loading_gifs.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color.fromRGBO(32, 32, 36, 1),
      ),
      body: Center(
        child: BlocListener<AppCubit, PredictionState>(
          listener: (context, state) {
            if (state is PredictionStarted) {
              if (kDebugMode) {
                print('prediction started with id: ${state.id}');
              }
              context.read<AppCubit>().listenToPrediction(state.id);
            }
          },
          child: const HomeList(),
        ),
      ),
    );
  }
}

class HomeList extends StatefulWidget {
  const HomeList({super.key});

  @override
  State<HomeList> createState() => _HomeListState();
}

class _HomeListState extends State<HomeList> {
  bool _isDrawing = false;
  bool _isReadyForPrediction = true;
  bool _isWaitingForInitial = false;
  final List<PredictionModel> _results = [
    const PredictionModel(
      id: 'id',
      prompt: 'prompt',
      inputImageUrl:
          'https://storage.googleapis.com/flutter-scribble.appspot.com/images/f9fe5943-dd71-4216-abce-e09f82edf331.png?GoogleAccessId=flutter-scribble%40appspot.gserviceaccount.com&Expires=16731014400&Signature=UYfzb5qgI%2FzuKmtVUTQmhesNsThFu7UkZNNJoOZRxpUvYiJexLZ6G9CrNyuQ%2BIlYt7FtJd%2FCep7XA6aaFj6s0v9hGUNVhySTzc5oC9XrUNGdoYVNJfuQ%2BxGo1Jk1HzIiLy3ap0%2FxlhpiRO3cuMGXpC4G%2FL2mxKR2OIQ3E5NAU0TS28q0dMJfP1otGmiNl9jDyakpSEvRuOcpuSSOrDYwUVce%2FVuRFQdSrO9mIPpXTRk%2FXT4q2ShWyTE7x%2BPIwdLPW9YLb2UuR%2FMHYU1k3SH86wnuPDfYK605U%2BnLom6fSy2hiZjSEiflkEa2vBlF94URN3ebYnMQWq8b1wtwv8IMzw%3D%3D',
      outputImageUrl:
          'https://storage.googleapis.com/flutter-scribble.appspot.com/images/5d5f6c19-3e20-474f-b16d-00eb3a805d9c.png?GoogleAccessId=957935913819-compute%40developer.gserviceaccount.com&Expires=16731014400&Signature=dPW%2BJW6oMwn1JufQZwjsY6ckUhFDot5NdWFKb3C3%2FINEMsC24pawiIZNM%2FTaPFxcgWMdgKPk%2Br9kwqI%2BEyaH7W6mM4kWKe3m6Fzi6RKBh2UlSL9Tb%2F4sqUsTmOaMI4qW2ADIN7ofnOyYj2ekYdrNOiiiHSWWPf4HXInAScAahwWBHvweQch0W2jS%2BEqX8Gx8rlqARyxpn%2FsvCuA6WCd6LsDk%2Bg3CJpFAVYx3jUkCsCvtOug%2Fu7DYhE1OpDZdV11xB5rAe1MShBB%2FFpzsSR1cRd9xZp0XCaOtoPnUHwftZBTiXzd6Vj85nrobb1RIQRt9HFXBGkGC%2FlVA9GVjTFBlwg%3D%3D',
    )
  ];

  final _promptController = TextEditingController(text: 'A glass shaped heart');

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void callback({drawing}) {
    setState(() {
      _isDrawing = drawing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppCubit, PredictionState>(
      listener: (context, state) {
        if (state is PredictionCompleted) {
          setState(() {
            _isReadyForPrediction = true;
          });
        }
        if (state is PredictionUpdated) {
          setState(() {
            _isWaitingForInitial = false;
            final index =
                _results.indexWhere((element) => element.id == state.data.id);
            index == -1
                ? _results.insert(0, state.data)
                : _results[index] = state.data;
          });
          if (kDebugMode) {
            print("Prediction Updated");
          }
        }
      },
      child: ListView(
        shrinkWrap: true,
        physics: _isDrawing
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(15.0),
        children: <Widget>[
          Align(
            child: Container(
              constraints:
                  const BoxConstraints(maxHeight: 500.0, maxWidth: 500.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: DrawingPage(callback: callback),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 7,
                    child: TextField(
                      controller: _promptController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Text Prompt',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(55.0)),
                        onPressed: _isReadyForPrediction
                            ? () {
                                setState(() {
                                  _isReadyForPrediction = false;
                                  _isWaitingForInitial = true;
                                });
                                context
                                    .read<AppCubit>()
                                    .startPrediction(_promptController.text);
                              }
                            : null,
                        child: const Icon(Icons.draw_outlined)),
                  )
                ],
              ),
            ),
          ),
          Column(
            children: _isWaitingForInitial
                ? const <Widget>[
                    SizedBox(height: 10),
                    Card(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 108.0, bottom: 108.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ]
                : [],
          ),
          Column(
            children: buildResults(),
          ),
        ],
      ),
    );
  }

  List<Widget> buildResults() {
    var resultWidgets = <Widget>[];
    resultWidgets.add(
      const SizedBox(
        height: 20,
      ),
    );

    for (var prediction in _results) {
      resultWidgets.add(
        Card(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 20.0),
                      child: FadeInImage.assetNetwork(
                          fit: BoxFit.contain,
                          placeholder: circularProgressIndicatorSmall,
                          image: prediction.inputImageUrl,
                          placeholderScale: 5),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 20.0),
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
                child: Text(
                  prediction.prompt,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return resultWidgets;
  }
}
