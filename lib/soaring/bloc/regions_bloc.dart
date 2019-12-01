import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/bloc/regions_event.dart';
import 'package:flutter_soaring_forecast/soaring/bloc/regions_state.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';

/// Various tutorials on Bloc implementation
/// https://pub.dev/packages/bloc  <<< See this for nice explanation of bloc api's
/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
/// Event In - State Out
class RegionsBloc extends Bloc<RegionsEvent, RegionsState> {
  final Repository repository;

  RegionsBloc({@required this.repository});

  /// initialState is the state before any events have been processed (before
  /// mapEventToState has ever been called). initialState must be implemented.
  @override
  RegionsState get initialState => RegionsLoading();

  ///mapEventToState is a method that must be implemented when a class extends Bloc.
  ///The function takes the incoming event as an argument.
  /// mapEventToState is called whenever an event is added.
  /// mapEventToState must convert that event into a new state and return the
  /// new state in the form of a Stream.
  @override
  Stream<RegionsState> mapEventToState(
    RegionsEvent event,
  ) async* {
    // TODO: Add Logic
    if (event is GetRegions) {
      yield* _mapGetRegionsToState();
    }
  }

  Stream<RegionsState> _mapGetRegionsToState() async* {
    try {
      final regions = await this.repository.getRegions();
      yield RegionsLoaded(regions);
    } catch (_) {
      yield RegionsNotLoaded();
    }
  }
}
