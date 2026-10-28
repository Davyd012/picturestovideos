import 'dart:async';

class RenderCancelled implements Exception {
  const RenderCancelled();
}

class RenderCancellation {
  bool _cancelled = false;
  final _whenCancelled = Completer<void>();
  final _listeners = <void Function()>{};
  bool get isCancelled => _cancelled;
  Future<void> get whenCancelled => _whenCancelled.future;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _whenCancelled.complete();
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }

  void addListener(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }

  void removeListener(void Function() listener) => _listeners.remove(listener);
  void throwIfCancelled() {
    if (_cancelled) throw const RenderCancelled();
  }
}
