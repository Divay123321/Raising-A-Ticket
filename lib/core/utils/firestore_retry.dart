/// Wraps a Firestore stream-producing function with retry logic to handle
/// Firebase Web's auth-token propagation timing gap right after login —
/// up to 2 silent retries (400ms, then 800ms) before letting a real error surface.
Stream<T> withRetry<T>(Stream<T> Function() streamBuilder) async* {
  int attempt = 0;
  while (true) {
    try {
      yield* streamBuilder();
      return;
    } catch (e) {
      attempt++;
      if (attempt >= 3) rethrow;
      await Future.delayed(Duration(milliseconds: 400 * attempt));
    }
  }
}