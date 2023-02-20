import 'package:perfect_freehand/perfect_freehand.dart';

class Stroke {
  final List<Point> points;

  const Stroke(this.points);

  Stroke.fromJson(Map<String, dynamic> json) : points = json['points'];

  Map<String, dynamic> toJson() => {'points': points};
}

class SerializablePoint extends Point {
  const SerializablePoint(
    x,
    y, [
    p = 0.5,
  ]) : super(x, y, p);

  SerializablePoint.fromJson(Map<String, dynamic> json)
      : super(json['x'], json['y'], json['p']);

  Map<String, dynamic> toJson() => {'x': 100};
}
