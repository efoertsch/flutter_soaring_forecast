import 'dart:async';

class RaspViewModel {

var _counterController = StreamController<int>.broadcast();

int _counter = 0;

void dispose() => _counterController.close();

Stream<int> get steamCounter => _counterController.stream.map((val) {
_counter += val;
if (_counter > 3) _counter = 0;
return _counter;
});

Sink get sinkCounter => _counterController;
}

