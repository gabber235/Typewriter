class SpringValue {
  SpringValue({
    required double value,
    double? targetValue,
    this.velocity = 0,
    this.stiffness = 300.0,
    this.damping = 25.0,
  }) : _value = value,
       target = targetValue ?? value;

  static const double epsilon = 0.001;

  double _value;
  double target;
  double velocity;
  double stiffness;
  double damping;

  double get value => _value;
  set value(double value) {
    if (value == _value) return;
    _value = value;
    target = value;
  }

  bool get isAnimating {
    return (value - target).abs() > epsilon || velocity.abs() > epsilon;
  }

  double tick(Duration delta) {
    final dt = delta.inMicroseconds / 1000000;

    final acceleration = stiffness * (target - value) - damping * velocity;

    velocity += acceleration * dt;
    return _value += velocity * dt;
  }
}
