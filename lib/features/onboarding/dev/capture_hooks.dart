// Hook cho script chụp ảnh HDSD (F3-G13, `npm run hdsd:capture` ở repo frontend): mở thẳng một route trong app
// đang chạy. Chỉ bản Flutter web chạy ở localhost mới đăng ký; app Android/iOS và bản web production không có.
export 'capture_hooks_stub.dart' if (dart.library.js_interop) 'capture_hooks_web.dart';
