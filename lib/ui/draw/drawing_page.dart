import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scribble/blocs/app_cubit.dart';
import 'package:flutter_scribble/blocs/app_states.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import "canvas.dart";
import "stroke.dart";
import 'stroke_options.dart';

class DrawingPage extends StatefulWidget {
  final Function({bool drawing}) callback;

  const DrawingPage({Key? key, required this.callback}) : super(key: key);

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  List<Stroke> lines = <Stroke>[
    const Stroke(
      [
        Point(100, 100),
        Point(300, 300),
        Point(400, 300),
        Point(300, 20),
        Point(30, 20),
        Point(60, 150),
      ],
    ),
  ];

  Stroke? line;

  StrokeOptions options = StrokeOptions();

  StreamController<Stroke> currentLineStreamController =
      StreamController<Stroke>.broadcast();

  StreamController<List<Stroke>> linesStreamController =
      StreamController<List<Stroke>>.broadcast();

  Future<void> clear() async {
    setState(() {
      lines = [];
      line = null;
    });
  }

  Future<void> undo() async {
    if (lines.isNotEmpty) {
      setState(() {
        lines.removeLast();
        line = null;
      });
    }
  }

  Future<void> updateSizeOption(double size) async {
    setState(() {
      options.size = size;
    });
  }

  Future<void> image(BuildContext context) async {
    final image = await toImage();
    final futureBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = futureBytes!.buffer.asUint8List();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          elevation: 1,
          insetPadding: const EdgeInsets.all(32.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 500,
              width: 500,
              child: Image.memory(pngBytes),
            ),
          ),
        );
      },
    );
  }

  Future<void> upload(cubit, prompt) async {
    final image = await toImage();
    final futureBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = futureBytes!.buffer.asUint8List();
    final imageData = base64Encode(pngBytes);

    await cubit.createPrediction(imageData, prompt);
  }

  Future<ui.Image> toImage() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();

    final Canvas canvas = Canvas(recorder);

    final sketcher = Paper(lines: lines, options: options);
    const size = Size(500.0, 500.0);
    sketcher.paint(canvas, size);

    final ui.Picture picture = recorder.endRecording();
    return picture.toImage(size.width.toInt(), size.height.toInt());
  }

  void onPointerDown(PointerDownEvent details) {
    widget.callback(drawing: true); // set drawing state to true
    options = StrokeOptions(
      simulatePressure: details.kind != ui.PointerDeviceKind.stylus,
    );

    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.position);
    late final Point point;
    if (details.kind == ui.PointerDeviceKind.stylus) {
      point = Point(
        offset.dx,
        offset.dy,
        (details.pressure - details.pressureMin) /
            (details.pressureMax - details.pressureMin),
      );
    } else {
      point = Point(offset.dx, offset.dy);
    }
    final points = [point];
    line = Stroke(points);
    currentLineStreamController.add(line!);
  }

  void onPointerMove(PointerMoveEvent details) {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.position);
    late final Point point;
    if (details.kind == ui.PointerDeviceKind.stylus) {
      point = Point(
        offset.dx,
        offset.dy,
        (details.pressure - details.pressureMin) /
            (details.pressureMax - details.pressureMin),
      );
    } else {
      point = Point(offset.dx, offset.dy);
    }
    final points = [...line!.points, point];
    line = Stroke(points);
    currentLineStreamController.add(line!);
  }

  void onPointerUp(PointerUpEvent details) {
    lines = List.from(lines)..add(line!);
    linesStreamController.add(lines);
    widget.callback(drawing: false); // reset drawing state
  }

  Widget buildCurrentPath(BuildContext context) {
    return Listener(
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      child: RepaintBoundary(
        child: SizedBox(
            //color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
            child: StreamBuilder<Stroke>(
                stream: currentLineStreamController.stream,
                builder: (context, snapshot) {
                  return CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: Paper(
                      lines: line == null ? [] : [line!],
                      options: options,
                    ),
                  );
                })),
      ),
    );
  }

  Widget buildAllPaths(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: StreamBuilder<List<Stroke>>(
          stream: linesStreamController.stream,
          builder: (context, snapshot) {
            return CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: Paper(
                lines: lines,
                options: options,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildToolbar() {
    return Positioned(
        bottom: 10.0,
        left: 10.0,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              buildClearButton(context),
              buildUndoButton(context),
            ]));
  }

  Widget buildUndoButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        undo();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: const CircleAvatar(
            child: Icon(
          Icons.replay,
          size: 20.0,
          color: Colors.white,
        )),
      ),
    );
  }

  Widget buildClearButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        clear();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: const CircleAvatar(
            child: Icon(
          Icons.clear_outlined,
          size: 20.0,
          color: Colors.white,
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppCubit, PredictionState>(
      listener: (context, state) async {
        if (state is PredictionTriggered) {
          if (kDebugMode) {
            print('PredictionTriggered');
          }
          await upload(context.read<AppCubit>(), state.prompt);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            buildAllPaths(context),
            buildCurrentPath(context),
            buildToolbar()
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    linesStreamController.close();
    currentLineStreamController.close();
    super.dispose();
  }
}
