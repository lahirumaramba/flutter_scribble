import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import "canvas.dart";
import "stroke.dart";
import 'stroke_options.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({Key? key}) : super(key: key);

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  List<Stroke> lines = <Stroke>[];

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

  Future<void> upload() async {
    try {
      final image = await toImage();
      final futureBytes =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = futureBytes!.buffer.asUint8List();

      final result = await FirebaseFunctions.instance
          .httpsCallable('createprediction')
          .call({'image': base64Encode(pngBytes), 'prompt': 'apple'});
      print(result.data);
    } on FirebaseFunctionsException catch (error) {
      print(error);
    }
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
        top: 40.0,
        right: 10.0,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Size',
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Slider(
                  value: options.size,
                  min: 1,
                  max: 50,
                  divisions: 100,
                  label: options.size.round().toString(),
                  onChanged: (double value) => {
                        setState(() {
                          options.size = value;
                        })
                      }),
              const Text(
                'Thinning',
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Slider(
                  value: options.thinning,
                  min: -1,
                  max: 1,
                  divisions: 100,
                  label: options.thinning.toStringAsFixed(2),
                  onChanged: (double value) => {
                        setState(() {
                          options.thinning = value;
                        })
                      }),
              const Text(
                'Streamline',
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Slider(
                  value: options.streamline,
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: options.streamline.toStringAsFixed(2),
                  onChanged: (double value) => {
                        setState(() {
                          options.streamline = value;
                        })
                      }),
              const Text(
                'Smoothing',
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Slider(
                  value: options.smoothing,
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: options.smoothing.toStringAsFixed(2),
                  onChanged: (double value) => {
                        setState(() {
                          options.smoothing = value;
                        })
                      }),
              const Text(
                'Taper Start',
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Slider(
                  value: options.taperStart,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: options.taperStart.toStringAsFixed(2),
                  onChanged: (double value) => {
                        setState(() {
                          options.taperStart = value;
                        })
                      }),
              const Text(
                'Taper End',
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Slider(
                  value: options.taperEnd,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: options.taperEnd.toStringAsFixed(2),
                  onChanged: (double value) => {
                        setState(() {
                          options.taperEnd = value;
                        })
                      }),
              const Text(
                'Clear',
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              buildClearButton(context),
            ]));
  }

  Widget buildClearButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        upload();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          buildAllPaths(context),
          buildCurrentPath(context),
          buildToolbar()
        ],
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
