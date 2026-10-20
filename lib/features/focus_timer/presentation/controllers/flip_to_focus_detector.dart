import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

/// Flip-to-Focus detector listening to device accelerometer hardware
/// Triggers face-down event when Z-axis acceleration is <= -9.2 m/s^2 with a 1500ms debounce window.
class FlipToFocusDetector {
  static const double faceDownZThreshold = -9.2;
  static const Duration debounceDuration = Duration(milliseconds: 1500);

  final void Function(bool isFaceDown)? onFlipChanged;
  final StreamController<bool> _flipStreamController = StreamController<bool>.broadcast();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isFaceDown = false;
  DateTime? _lastTriggerEpoch;

  FlipToFocusDetector({this.onFlipChanged});

  bool get isFaceDown => _isFaceDown;
  Stream<bool> get flipStream => _flipStreamController.stream;

  /// Starts listening to device accelerometer sensor with graceful fallback for desktop/tests
  void start() {
    _accelerometerSubscription?.cancel();
    try {
      _accelerometerSubscription = accelerometerEventStream().listen(
        (event) {
          handleSensorValues(z: event.z, x: event.x, y: event.y);
        },
        onError: (_) {
          // Gracefully ignore missing sensor platform channels on desktop
        },
        cancelOnError: false,
      );
    } catch (_) {
      // Fallback for environments without accelerometer hardware
    }
  }

  /// Processes accelerometer updates and applies debounce & threshold checks
  void handleSensorValues({
    required double z,
    double x = 0.0,
    double y = 0.0,
  }) {
    final now = DateTime.now();
    final isDown = z <= faceDownZThreshold;

    if (isDown != _isFaceDown) {
      if (_lastTriggerEpoch == null ||
          now.difference(_lastTriggerEpoch!) >= debounceDuration) {
        _isFaceDown = isDown;
        _lastTriggerEpoch = now;
        _flipStreamController.add(_isFaceDown);
        onFlipChanged?.call(_isFaceDown);
      }
    }
  }

  /// Stops listening to accelerometer events
  void stop() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  /// Disposes subscriptions and stream controllers
  void dispose() {
    stop();
    _flipStreamController.close();
  }
}
