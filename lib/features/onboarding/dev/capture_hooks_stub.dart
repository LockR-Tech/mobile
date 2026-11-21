/// App Android/iOS: không có hook.
void registerCaptureHooks(
  void Function(String route) go, {
  void Function()? reset,
  bool Function(String anchor)? reveal,
}) {}
