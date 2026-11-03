import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/preview/domain/transition_visual.dart';

void main() {
  test(
    'zoom transition scales the outgoing image then reveals the incoming image',
    () {
      expect(TransitionVisual.zoomOutgoingScale(0), 1);
      expect(TransitionVisual.zoomOutgoingScale(0.25), closeTo(2, 0.001));
      expect(TransitionVisual.zoomIncomingOpacity(0.5), 0);
      expect(TransitionVisual.zoomIncomingOpacity(0.75), closeTo(0.5, 0.001));
      expect(TransitionVisual.zoomIncomingOpacity(1), 1);
    },
  );
}
