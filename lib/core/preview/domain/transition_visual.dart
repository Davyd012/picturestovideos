/// Parameters for the preview of the renderer's zoom-in transition.
class TransitionVisual {
  const TransitionVisual._();

  static double _smooth(double value) {
    final t = value.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  static double zoomOutgoingScale(double progress) {
    final sampleScale = 1 - _smooth(progress * 2);
    return 1 / sampleScale.clamp(0.001, 1.0);
  }

  static double zoomIncomingOpacity(double progress) =>
      _smooth((progress - 0.5) * 2);
}
