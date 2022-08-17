// use this as a MapController for https://pub.dev/packages/flutter_map
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

// from https://gist.github.com/magicleon94/c271e3d2e9f29c6b6743ec843fabe9a3
class AnimatedMapController extends MapControllerImpl {
  final TickerProvider tickerProvider;
  late MapStateWrapper _stateWrapper;

  AnimatedMapController(this.tickerProvider);

  @override
  set state(MapState state) {
    _stateWrapper = MapStateWrapper(state);
    super.state = state;
  }

  void animatedMapMove(LatLng destLocation, double destZoom) =>
      _stateWrapper.animatedMove(destLocation, destZoom, tickerProvider);

  void animatedFitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions options =
        const FitBoundsOptions(padding: EdgeInsets.all(12.0)),
  }) {
    _stateWrapper.animatedFitBounds(bounds, options, tickerProvider);
  }
}

class MapStateWrapper {
  final MapState state;

  MapStateWrapper(this.state);

  //source: https://github.com/fleaflet/flutter_map/blob/15a79377d93ebe26072921ab0176bde5f348a97f/example/lib/pages/animated_map_controller.dart#L40
  void animatedMove(
      LatLng destLocation, double destZoom, TickerProvider tickerProvider) {
    final center = state.center;
    final zoom = state.zoom;
    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the transition be<tween> our current map center and the destination.
    final _latTween =
        Tween<double>(begin: center.latitude, end: destLocation.latitude);
    final _lngTween =
        Tween<double>(begin: center.longitude, end: destLocation.longitude);
    final _zoomTween = Tween<double>(begin: zoom, end: destZoom);

    // Create a animation controller that has a duration and a TickerProvider.
    var controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: tickerProvider);
    // The animation determines what path the animation will take. You can try different Curves values, although I found
    // fastOutSlowIn to be my favorite.
    Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      state.move(
          source: MapEventSource.mapController,
          LatLng(_latTween.evaluate(animation), _lngTween.evaluate(animation)),
          _zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void animatedFitBounds(LatLngBounds bounds, FitBoundsOptions options,
      TickerProvider tickerProvider) {
    if (!bounds.isValid) {
      throw Exception('Bounds are not valid.');
    }
    final target = state.getBoundsCenterZoom(bounds, options);
    animatedMove(target.center, target.zoom, tickerProvider);
  }
}
