import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:graphic/graphic.dart';
import 'dart:math';

/// A thermal updraft shape.
class ThermalShape extends PointShape {
  /// Creates a oblong circle shape.
  ThermalShape({
    bool hollow = false,
    double strokeWidth = 1,
  }) : super(hollow, strokeWidth);

  @override
  bool equalTo(Object other) => super.equalTo(other) && other is CircleShape;

  @override
  MarkElement drawPoint(Attributes item, CoordConv coord) {
    final initialPoint = coord.convert(item.position.last);
    final size = item.size ?? defaultSize;
    // move top of thermal bubble up to approx match appropriate altitude
    final point = Offset(initialPoint.dx, initialPoint.dy - (size/2.2)   );
    return ThermalElement(
      point: point,
      size: size,
      style: getPaintStyle(item, (item.shape as PointShape).hollow,
          (item.shape as PointShape).strokeWidth, null, null),
    );
  }
}

class ThermalElement extends PrimitiveElement {
  /// The center point of this drawing
  final Offset point;

  /// size of drawing
  final double size;

  ThermalElement({
    required this.point,
    required this.size,
    required PaintStyle style,
    double? rotation,
    Offset? rotationAxis,
    String? tag,
  }) : super(
          style: style,
          rotation: rotation,
          rotationAxis: rotationAxis,
          tag: tag,
        );

  @override
  void drawPath(Path path) {
    path
      ..addOval(Rect.fromCenter(
        center: Offset(point.dx, point.dy + size),
        width: size,
        height: size * 1.5,
      ));
  }

  @override
  ThermalElement lerpFrom(covariant ThermalElement from, double t) =>
      ThermalElement(
        point: Offset.lerp(from.point, point, t)!,
        size: lerpDouble(from.size, size, t)!,
        style: style.lerpFrom(from.style, t),
        rotation: lerpDouble(from.rotation, rotation, t),
        rotationAxis: Offset.lerp(from.rotationAxis, rotationAxis, t),
        tag: tag,
      );

  // no idea what segments do, code below adapted from CircleElement but darn if I
  // know if is correct.
  @override
  List<Segment> toSegments() {
    const factor = ((-1 + sqrt2) / 3) * 4;
    final d = size / 2 * factor;
    return [
      MoveSegment(end: point.translate(-size / 2, 0)),
      CubicSegment(
          control1: point.translate(-size / 2, -d),
          control2: point.translate(-d, -size / 2),
          end: point.translate(0, -size / 2),
          tag: SegmentTags.top),
      CubicSegment(
          control1: point.translate(d, -size / 2),
          control2: point.translate(size / 2, -d),
          end: point.translate(size / 2, 0),
          tag: SegmentTags.right),
      CubicSegment(
          control1: point.translate(size / 2, d),
          control2: point.translate(d, size / 2),
          end: point.translate(0, size / 2),
          tag: SegmentTags.bottom),
      CubicSegment(
          control1: point.translate(-d, size / 2),
          control2: point.translate(-size / 2, d),
          end: point.translate(-size / 2, 0),
          tag: SegmentTags.left),
      CloseSegment(),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is ThermalElement &&
      super == other &&
      size == other.size &&
      point == other.point;
}

/// A cumulus cloud shape.
/// Used https://fluttershapemaker.com/  to convert svg's to Path statements
class CumulusShape extends PointShape {
  CumulusShape({
    bool hollow = false,
    double strokeWidth = 1,
  }) : super(hollow, strokeWidth);

  @override
  bool equalTo(Object other) => super.equalTo(other) && other is CumulusShape;

  @override
  MarkElement drawPoint(Attributes item, CoordConv coord) {
    final initialPoint = coord.convert(item.position.last);
    final size = item.size ?? defaultSize;
    // need to move the bottom of cloud 'up' to proper altitude
   // debugPrint("Cloud point: ${initialPoint.dx}  ${initialPoint.dy}");
    final point  = Offset(initialPoint.dx, initialPoint.dy - size);
    return CloudElement(
      point: point,
      size: size,
      style: getPaintStyle(item, (item.shape as PointShape).hollow,
          (item.shape as PointShape).strokeWidth, null, null),
    );
  }
}

class CloudElement extends PrimitiveElement {
  /// The center point of this drawing
  final Offset point;

  /// size of drawing
  final double size;

  CloudElement({
    required this.point,
    required this.size,
    required PaintStyle style,
    double? rotation,
    Offset? rotationAxis,
    String? tag,
  }) : super(
          style: style,
          rotation: rotation,
          rotationAxis: rotationAxis,
          tag: tag,
        );

  @override
  Path drawPath(Path path) {
    final point = this.point;
    final xpos = point.dx;
    final ypos = point.dy;
    final size = this.size;
    final width = size;
    final height = size * 1.5;
    path.moveTo(
        xpos - (0.5 * width) + width * 0.6726178, ypos + height * 0.2808022);
    path.cubicTo(
        xpos - (0.5 * width) + width * 0.4975869,
        ypos + height * 0.1094080,
        xpos - (0.5 * width) + width * 0.1999410,
        ypos + height * 0.2026871,
        xpos - (0.5 * width) + width * 0.1559079,
        ypos + height * 0.4447257);
    path.cubicTo(
        xpos - (0.5 * width) + width * 0.09370294,
        ypos + height * 0.4537061,
        xpos - (0.5 * width) + width * 0.04040422,
        ypos + height * 0.4944229,
        xpos - (0.5 * width) + width * 0.01524802,
        ypos + height * 0.5522958);
    path.cubicTo(
        xpos - (0.5 * width) + width * 0.01521677,
        ypos + height * 0.5523642,
        xpos - (0.5 * width) + width * 0.01518552,
        ypos + height * 0.5524325,
        xpos - (0.5 * width) + width * 0.01515622,
        ypos + height * 0.5525048);
    path.cubicTo(
        xpos - (0.5 * width) + width * -0.03696672,
        ypos + height * 0.6728210,
        xpos - (0.5 * width) + width * 0.05184365,
        ypos + height * 0.8068637,
        xpos - (0.5 * width) + width * 0.1821676,
        ypos + height * 0.8068637);
    path.lineTo(
        xpos - (0.5 * width) + width * 0.7334693, ypos + height * 0.8068637);
    path.cubicTo(
        xpos - (0.5 * width) + width * 0.8804338,
        ypos + height * 0.8068637,
        xpos - (0.5 * width) + width * 0.9999980,
        ypos + height * 0.6873014,
        xpos - (0.5 * width) + width * 0.9999980,
        ypos + height * 0.5403368);
    path.cubicTo(
        xpos - (0.5 * width) + width * 0.9999980,
        ypos + height * 0.3696106,
        xpos - (0.5 * width) + width * 0.8404554,
        ypos + height * 0.2415659,
        xpos - (0.5 * width) + width * 0.6726178,
        ypos + height * 0.2808022);
    path.close();
    path.moveTo(
        xpos - (0.5 * width) + width * 0.7334693, ypos + height * 0.7443735);
    path.lineTo(
        xpos - (0.5 * width) + width * 0.1821696, ypos + height * 0.7443735);
    path.cubicTo(
        xpos - (0.5 * width) + width * 0.04692374,
        ypos + height * 0.7443735,
        xpos - (0.5 * width) + width * 0.01706442,
        ypos + height * 0.5524540,
        xpos - (0.5 * width) + width * 0.1456189,
        ypos + height * 0.5110615);
    path.cubicTo(
        xpos - (0.5 * width) + width * 0.1744333,
        ypos + height * 0.5019795,
        xpos - (0.5 * width) + width * 0.2296226,
        ypos + height * 0.4967100,
        xpos - (0.5 * width) + width * 0.2908920,
        ypos + height * 0.5538192);
    path.cubicTo(
        xpos - (0.5 * width) + width * 0.3035170,
        ypos + height * 0.5655848,
        xpos - (0.5 * width) + width * 0.3232865,
        ypos + height * 0.5648876,
        xpos - (0.5 * width) + width * 0.3350521,
        ypos + height * 0.5522685);
    path.cubicTo(
        xpos - (0.5 * width) + width * 0.3468177,
        ypos + height * 0.5396435,
        xpos - (0.5 * width) + width * 0.3461224,
        ypos + height * 0.5198740,
        xpos - (0.5 * width) + width * 0.3335013,
        ypos + height * 0.5081084);
    path.cubicTo(
        xpos - (0.5 * width) + width * 0.2984818,
        ypos + height * 0.4754678,
        xpos - (0.5 * width) + width * 0.2591440,
        ypos + height * 0.4547296,
        xpos - (0.5 * width) + width * 0.2192750,
        ypos + height * 0.4466769);
    path.cubicTo(
        xpos - (0.5 * width) + width * 0.2623100,
        ypos + height * 0.2531675,
        xpos - (0.5 * width) + width * 0.5071142,
        ypos + height * 0.1891559,
        xpos - (0.5 * width) + width * 0.6396784,
        ypos + height * 0.3367064);
    path.cubicTo(
        xpos - (0.5 * width) + width * 0.6478601,
        ypos + height * 0.3458099,
        xpos - (0.5 * width) + width * 0.6606042,
        ypos + height * 0.3493060,
        xpos - (0.5 * width) + width * 0.6722819,
        ypos + height * 0.3456321);
    path.cubicTo(
        xpos - (0.5 * width) + width * 0.8036723,
        ypos + height * 0.3043881,
        xpos - (0.5 * width) + width * 0.9375060,
        ypos + height * 0.4030031,
        xpos - (0.5 * width) + width * 0.9375060,
        ypos + height * 0.5403388);
    path.cubicTo(
        xpos - (0.5 * width) + width * 0.9375079,
        ypos + height * 0.6528425,
        xpos - (0.5 * width) + width * 0.8459769,
        ypos + height * 0.7443735,
        xpos - (0.5 * width) + width * 0.7334693,
        ypos + height * 0.7443735);
    path.close();
    return path;
  }

  @override
  CloudElement lerpFrom(covariant CloudElement from, double t) => CloudElement(
        point: Offset.lerp(from.point, point, t)!,
        size: lerpDouble(from.size, size, t)!,
        style: style.lerpFrom(from.style, t),
        rotation: lerpDouble(from.rotation, rotation, t),
        rotationAxis: Offset.lerp(from.rotationAxis, rotationAxis, t),
        tag: tag,
      );

// no idea what segments do, code below adapted from CircleElement but darn if I
// know if is correct.
  @override
  List<Segment> toSegments() {
    const factor = ((-1 + sqrt2) / 3) * 4;
    final d = size / 2 * factor;
    return [
      MoveSegment(end: point.translate(-size / 2, 0)),
      CubicSegment(
          control1: point.translate(-size / 2, -d),
          control2: point.translate(-d, -size / 2),
          end: point.translate(0, -size / 2),
          tag: SegmentTags.top),
      CubicSegment(
          control1: point.translate(d, -size / 2),
          control2: point.translate(size / 2, -d),
          end: point.translate(size / 2, 0),
          tag: SegmentTags.right),
      CubicSegment(
          control1: point.translate(size / 2, d),
          control2: point.translate(d, size / 2),
          end: point.translate(0, size / 2),
          tag: SegmentTags.bottom),
      CubicSegment(
          control1: point.translate(-d, size / 2),
          control2: point.translate(-size / 2, d),
          end: point.translate(-size / 2, 0),
          tag: SegmentTags.left),
      CloseSegment(),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is CloudElement &&
      super == other &&
      size == other.size &&
      point == other.point;
}
