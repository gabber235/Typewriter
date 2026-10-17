/// A mutable damped spring used to animate a scalar toward a target.
///
/// The owning controller updates the value by calling [tick] each frame. Set
/// [target] to animate. Assigning a different [value] updates both current and
/// target values but preserves velocity; assigning the current value does
/// nothing.
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

  /// The current simulated value.
  double get value => _value;
  set value(double value) {
    if (value == _value) return;
    _value = value;
    target = value;
  }

  /// Whether another frame is needed to settle within [epsilon].
  bool get isAnimating {
    return (value - target).abs() > epsilon || velocity.abs() > epsilon;
  }

  /// Advances the spring by [delta] and returns the new current value.
  ///
  /// The simulation is frame driven. Callers own scheduling and should avoid
  /// passing a negative duration.
  double tick(Duration delta) {
    final dt = delta.inMicroseconds / 1000000;

    final acceleration = stiffness * (target - value) - damping * velocity;

    velocity += acceleration * dt;
    return _value += velocity * dt;
  }
}
