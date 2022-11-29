import 'dart:ui';

import 'package:graphic/graphic.dart';
import "package:graphic/src/shape/point.dart";

/// A thermal updraft shape.
class ThermalShape extends PointShapeBase {
  /// Creates a circle shape.
  ThermalShape({
    bool hollow = false,
    double strokeWidth = 1,
  }) : super(hollow, strokeWidth);

  @override
  bool equalTo(Object other) => super.equalTo(other) && other is CircleShape;

  @override
  Path path(Aes item, CoordConv coord) {
    final point = coord.convert(item.position.last);
    final size = item.size ?? defaultSize;
    return Path()
      ..addOval(Rect.fromCenter(
        center: Offset(point.dx, point.dy + size),
        width: size,
        height: size * 2,
      ));
  }
}

/// A cumulus cloud shape.
/// Used https://fluttershapemaker.com/  to convert svg's to Path statements
class CumulusShape extends PointShapeBase {
  CumulusShape({
    bool hollow = false,
    double strokeWidth = 1,
  }) : super(hollow, strokeWidth);

  @override
  bool equalTo(Object other) => super.equalTo(other) && other is CircleShape;

  @override
  Path path(Aes item, CoordConv coord) {
    final point = coord.convert(item.position.last);
    final xpos = point.dx;
    final ypos = point.dy;
    final size = item.size ?? defaultSize;
    final width = size;
    final height = size * 1.5;
    Path path_0 = Path();
    path_0.moveTo(
        xpos - (0.5 * width) + width * 0.6726178, ypos + height * 0.2808022);
    path_0.cubicTo(
        xpos - (0.5 * width) + width * 0.4975869,
        ypos + height * 0.1094080,
        xpos - (0.5 * width) + width * 0.1999410,
        ypos + height * 0.2026871,
        xpos - (0.5 * width) + width * 0.1559079,
        ypos + height * 0.4447257);
    path_0.cubicTo(
        xpos - (0.5 * width) + width * 0.09370294,
        ypos + height * 0.4537061,
        xpos - (0.5 * width) + width * 0.04040422,
        ypos + height * 0.4944229,
        xpos - (0.5 * width) + width * 0.01524802,
        ypos + height * 0.5522958);
    path_0.cubicTo(
        xpos - (0.5 * width) + width * 0.01521677,
        ypos + height * 0.5523642,
        xpos - (0.5 * width) + width * 0.01518552,
        ypos + height * 0.5524325,
        xpos - (0.5 * width) + width * 0.01515622,
        ypos + height * 0.5525048);
    path_0.cubicTo(
        xpos - (0.5 * width) + width * -0.03696672,
        ypos + height * 0.6728210,
        xpos - (0.5 * width) + width * 0.05184365,
        ypos + height * 0.8068637,
        xpos - (0.5 * width) + width * 0.1821676,
        ypos + height * 0.8068637);
    path_0.lineTo(
        xpos - (0.5 * width) + width * 0.7334693, ypos + height * 0.8068637);
    path_0.cubicTo(
        xpos - (0.5 * width) + width * 0.8804338,
        ypos + height * 0.8068637,
        xpos - (0.5 * width) + width * 0.9999980,
        ypos + height * 0.6873014,
        xpos - (0.5 * width) + width * 0.9999980,
        ypos + height * 0.5403368);
    path_0.cubicTo(
        xpos - (0.5 * width) + width * 0.9999980,
        ypos + height * 0.3696106,
        xpos - (0.5 * width) + width * 0.8404554,
        ypos + height * 0.2415659,
        xpos - (0.5 * width) + width * 0.6726178,
        ypos + height * 0.2808022);
    path_0.close();
    path_0.moveTo(
        xpos - (0.5 * width) + width * 0.7334693, ypos + height * 0.7443735);
    path_0.lineTo(
        xpos - (0.5 * width) + width * 0.1821696, ypos + height * 0.7443735);
    path_0.cubicTo(
        xpos - (0.5 * width) + width * 0.04692374,
        ypos + height * 0.7443735,
        xpos - (0.5 * width) + width * 0.01706442,
        ypos + height * 0.5524540,
        xpos - (0.5 * width) + width * 0.1456189,
        ypos + height * 0.5110615);
    path_0.cubicTo(
        xpos - (0.5 * width) + width * 0.1744333,
        ypos + height * 0.5019795,
        xpos - (0.5 * width) + width * 0.2296226,
        ypos + height * 0.4967100,
        xpos - (0.5 * width) + width * 0.2908920,
        ypos + height * 0.5538192);
    path_0.cubicTo(
        xpos - (0.5 * width) + width * 0.3035170,
        ypos + height * 0.5655848,
        xpos - (0.5 * width) + width * 0.3232865,
        ypos + height * 0.5648876,
        xpos - (0.5 * width) + width * 0.3350521,
        ypos + height * 0.5522685);
    path_0.cubicTo(
        xpos - (0.5 * width) + width * 0.3468177,
        ypos + height * 0.5396435,
        xpos - (0.5 * width) + width * 0.3461224,
        ypos + height * 0.5198740,
        xpos - (0.5 * width) + width * 0.3335013,
        ypos + height * 0.5081084);
    path_0.cubicTo(
        xpos - (0.5 * width) + width * 0.2984818,
        ypos + height * 0.4754678,
        xpos - (0.5 * width) + width * 0.2591440,
        ypos + height * 0.4547296,
        xpos - (0.5 * width) + width * 0.2192750,
        ypos + height * 0.4466769);
    path_0.cubicTo(
        xpos - (0.5 * width) + width * 0.2623100,
        ypos + height * 0.2531675,
        xpos - (0.5 * width) + width * 0.5071142,
        ypos + height * 0.1891559,
        xpos - (0.5 * width) + width * 0.6396784,
        ypos + height * 0.3367064);
    path_0.cubicTo(
        xpos - (0.5 * width) + width * 0.6478601,
        ypos + height * 0.3458099,
        xpos - (0.5 * width) + width * 0.6606042,
        ypos + height * 0.3493060,
        xpos - (0.5 * width) + width * 0.6722819,
        ypos + height * 0.3456321);
    path_0.cubicTo(
        xpos - (0.5 * width) + width * 0.8036723,
        ypos + height * 0.3043881,
        xpos - (0.5 * width) + width * 0.9375060,
        ypos + height * 0.4030031,
        xpos - (0.5 * width) + width * 0.9375060,
        ypos + height * 0.5403388);
    path_0.cubicTo(
        xpos - (0.5 * width) + width * 0.9375079,
        ypos + height * 0.6528425,
        xpos - (0.5 * width) + width * 0.8459769,
        ypos + height * 0.7443735,
        xpos - (0.5 * width) + width * 0.7334693,
        ypos + height * 0.7443735);
    path_0.close();
    return path_0;
  }
}
