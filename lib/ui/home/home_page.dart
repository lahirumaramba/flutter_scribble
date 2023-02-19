import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scribble/blocs/app_bloc.dart';
import 'package:flutter_scribble/blocs/app_events.dart';
import 'package:flutter_scribble/blocs/app_states.dart';
import 'package:flutter_scribble/repository/prediction_repo.dart';
import 'package:flutter_scribble/ui/draw/drawing_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PredictionBloc(
          predcitionRepository:
              RepositoryProvider.of<PredictionRepository>(context)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: const Color.fromRGBO(32, 32, 36, 1),
        ),
        body: BlocListener<PredictionBloc, PredictionState>(
          listener: (context, state) {
            if (state is PredictionUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prediction Updated')));
            }
          },
          child: const Center(
            child: HomeList(),
          ),
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
  bool _shouldUpload = false;
  String _promptText = '';

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

  void _triggerUpload() {
    setState(() {
      _shouldUpload = true;
      _promptText = _promptController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
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
              child: DrawingPage(
                callback: callback,
                shouldPredict: _shouldUpload,
                promptText: _promptText,
              ),
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
                      onPressed: () {
                        context.read<PredictionBloc>().add(CreatePrediction());
                        //_triggerUpload();
                      },
                      child: const Icon(Icons.draw_outlined)),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
