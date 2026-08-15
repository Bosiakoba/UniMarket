import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Maps thrown errors to short, user-safe messages (no hosts, ports, or stack traces).
String userFacingError(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is SocketException || error is TimeoutException) {
    return 'Could not connect. Check your internet connection and try again.';
  }
  if (error is http.ClientException) {
    return 'Could not reach the server. Please try again in a moment.';
  }

  final message = error.toString();
  if (message.contains('SocketException') ||
      message.contains('Connection timed out') ||
      message.contains('Connection refused') ||
      message.contains('Failed host lookup') ||
      message.contains('Network is unreachable')) {
    return 'Could not connect. Check your internet connection and try again.';
  }
  if (message.contains('ClientException') || message.contains('HandshakeException')) {
    return 'Could not reach the server. Please try again in a moment.';
  }

  return fallback;
}
