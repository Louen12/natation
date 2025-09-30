class LowPassFilter {
  final double alpha; // proche de 1.0 = plus lisse
  double _value = 0.0;
  bool _initialized = false;

  LowPassFilter({this.alpha = 0.9});

  double next(double input) {
    if (!_initialized) {
      _initialized = true;
      _value = input;
      return _value;
    }
    _value = _value * alpha + input * (1 - alpha);
    return _value;
  }
}
