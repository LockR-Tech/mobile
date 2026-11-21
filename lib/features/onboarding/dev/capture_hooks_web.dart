import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Bản web ở localhost: `window.__lockrGo('/orders')` đổi trang ngay trong app (tải lại trang thì app khởi động lại
/// và tự về trang chủ). Bản web production (app.locker-drone.tech) không đăng ký.
/// `__lockrReset()` đóng bảng / hộp thoại còn mở; `__lockrReveal('neo')` cuộn phần tử có neo vào tầm nhìn (tab nằm
/// ngoài thanh tab cuộn ngang, phần dưới của trang dài…), trả true nếu neo đang có trên màn hình.
void registerCaptureHooks(
  void Function(String route) go, {
  void Function()? reset,
  bool Function(String anchor)? reveal,
}) {
  final host = Uri.base.host;
  if (host != 'localhost' && host != '127.0.0.1') return;
  globalContext.setProperty('__lockrGo'.toJS, ((JSString route) => go(route.toDart)).toJS);
  if (reset != null) globalContext.setProperty('__lockrReset'.toJS, (() => reset()).toJS);
  if (reveal != null) globalContext.setProperty('__lockrReveal'.toJS, ((JSString a) => reveal(a.toDart).toJS).toJS);
}
