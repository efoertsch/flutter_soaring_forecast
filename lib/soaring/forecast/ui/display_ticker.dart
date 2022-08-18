import 'dart:async';

class DisplayTimer {
  late Duration duration;
  int _limit = 0;
  int _start = 0;
  var _count = 1;
  Timer? _timer;
  late StreamController<int> _controller;

  DisplayTimer(this.duration) {
    _controller = StreamController<int>(
        onListen: startTimer,
        onPause: stopTimer,
        onResume: startTimer,
        onCancel: stopTimer);
  }

  void tick(_) {
    //print('timer ticked: $_count');
    _controller.sink.add(_count);
    _count++;
    if (_count >= _limit) {
      _count = 0;
    }
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    print('Stopped timer');
  }

  Timer getTimer() {
    print('Getting timer');
    return Timer.periodic(duration, tick);
  }

  void setStartAndLimit(int start, int limit) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _count = start;
    this._limit = limit;
  }

  void startTimer() {
    print('Starting timer');
    _timer = Timer.periodic(duration, tick);
  }

  void closeStream() {
    _controller.close();
    print('Closed timer controller');
  }

  void cancelTimer() {
    if (_timer != null) {
      _timer!.cancel();
      print('Cancelled timer controller');
    } else {
      print('cancelTimer called but timer already cancelled');
    }
  }

  Stream<int> get stream => _controller.stream;
}
