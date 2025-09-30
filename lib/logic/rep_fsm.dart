enum Phase { idle, goingDown, bottom, goingUp }

class RepFsm {
  Phase phase = Phase.idle;
  DateTime _bottomAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastRep = DateTime.fromMillisecondsSinceEpoch(0);

  final Duration bottomHoldMin;
  final Duration repCooldown;

  RepFsm({
    this.bottomHoldMin = const Duration(milliseconds: 120),
    this.repCooldown   = const Duration(milliseconds: 400),
  });

  /// Retourne true lorsqu'une répétition est validée.
  bool step(double z, double downThresh, double upThresh) {
    final now = DateTime.now();

    switch (phase) {
      case Phase.idle:
        if (z < downThresh) phase = Phase.goingDown;
        break;

      case Phase.goingDown:
        if (z >= downThresh) {
          phase = Phase.bottom;
          _bottomAt = now;
        }
        break;

      case Phase.bottom:
        if (now.difference(_bottomAt) >= bottomHoldMin && z > upThresh) {
          phase = Phase.goingUp;
        }
        break;

      case Phase.goingUp:
        if (z <= upThresh) {
          if (now.difference(_lastRep) >= repCooldown) {
            _lastRep = now;
            phase = Phase.idle;
            return true;
          }
          phase = Phase.idle;
        }
        break;
    }
    return false;
  }

  void reset() {
    phase = Phase.idle;
    _bottomAt = DateTime.fromMillisecondsSinceEpoch(0);
    _lastRep  = DateTime.fromMillisecondsSinceEpoch(0);
  }
}
