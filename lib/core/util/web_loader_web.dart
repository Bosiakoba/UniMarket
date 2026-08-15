import 'dart:js_interop';

@JS('removeLoader')
external void _jsRemoveLoader();

void removeWebLoader() {
  try {
    _jsRemoveLoader();
  } catch (_) {
    // Suppress errors on non-web platforms or if function is missing
  }
}
