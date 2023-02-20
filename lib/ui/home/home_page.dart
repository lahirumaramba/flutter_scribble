import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_scribble/blocs/app_cubit.dart';
import 'package:flutter_scribble/blocs/app_states.dart';
import 'package:flutter_scribble/models/prediction_model.dart';
import 'package:flutter_scribble/repository/prediction_repo.dart';
import 'package:flutter_scribble/ui/draw/drawing_page.dart';
import 'package:get_it/get_it.dart';
import 'package:loading_gifs/loading_gifs.dart';
import 'package:url_launcher/url_launcher.dart';

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
      // appBar: AppBar(
      //   title: Text(widget.title),
      //   backgroundColor: const Color.fromRGBO(32, 32, 36, 1),
      // ),
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
  final PredictionRepository _predictionRepository = GetIt.instance();
  final List<PredictionModel> _results = [];

  final _promptController = TextEditingController(text: 'A glass shaped heart');

  @override
  void initState() {
    _getRecentResults();
    super.initState();
  }

  Future<void> _getRecentResults() async {
    final results = await _predictionRepository.predictions;
    setState(() {
      _results.addAll(results);
    });
  }

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
      listener: (context, state) async {
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
          const Align(
              child: Padding(
            padding: EdgeInsets.only(top: 15.0, bottom: 8.0),
            child: Text(
              'Scribble Diffusion',
              style: TextStyle(fontSize: 40.0),
            ),
          )),
          const Align(
              child: Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Text(
              'Turn your scribble to an image with AI',
              style: TextStyle(color: Colors.grey, fontSize: 25.0),
            ),
          )),
          const Align(
              child: Padding(
            padding: EdgeInsets.only(bottom: 25.0),
            child: Text(
              'Powered by ControlNet, Replicate, Flutter, and Firebase',
              style: TextStyle(color: Colors.grey),
            ),
          )),
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
                        hintText: 'Type your prompt here',
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
                                if (_promptController.text.isEmpty) {
                                  return;
                                }
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
          Align(
            child: SizedBox(
              width: double.infinity,
              child: Card(
                color: Colors.transparent,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Linkify(
                      onOpen: _launchUrl,
                      style: const TextStyle(color: Colors.grey),
                      text:
                          'Powered by ControlNet, Replicate, Flutter, and Firebase. 💬 http://twitter.com/lahiru',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(LinkableElement linkableElement) async {
    final link = Uri.parse(linkableElement.url);
    if (!await launchUrl(link)) {
      throw Exception('Could not launch $link');
    }
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
                      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 8.0, 20.0),
                      child: FadeInImage.assetNetwork(
                          fit: BoxFit.contain,
                          placeholder: circularProgressIndicatorSmall,
                          image: prediction.inputImageUrl,
                          placeholderScale: 5),
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
                child: Text(prediction.prompt),
              ),
            ],
          ),
        ),
      );
    }
    return resultWidgets;
  }
}
