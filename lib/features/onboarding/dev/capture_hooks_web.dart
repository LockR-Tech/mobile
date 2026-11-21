import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Bản web ở localhost: `window.__lockrGo('/orders')` đổi trang ngay trong app (tải lại trang thì app khởi động lại
/// và tự về trang chủ). Bản web production (app.locker-drone.tech) không đăng ký.
void registerCaptureHooks(void Function(String route) go) {
  final host = Uri.base.host;
  if (host != 'localhost' && host != '127.0.0.1') return;
  globalContext.setProperty('__lockrGo'.toJS, ((JSString route) => go(route.toDart)).toJS);
}
