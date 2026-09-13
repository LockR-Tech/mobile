String? parseQrSessionId(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasQuery) {
    final fromQuery =
        uri.queryParameters['sessionId'] ?? uri.queryParameters['session_id'];
    if (fromQuery != null && fromQuery.trim().isNotEmpty) {
      return fromQuery.trim();
    }
  }

  if (uri != null && uri.pathSegments.isNotEmpty) {
    final last = uri.pathSegments.last;
    if (last.isNotEmpty &&
        last.toLowerCase() != 'login-qr' &&
        last.toLowerCase() != 'qr') {
      return last;
    }
  }

  return trimmed;
}
