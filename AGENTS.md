# AGENTS.md — mobile

Repo này thuộc hệ thống **Lock.R** (org [LockR-Tech](https://github.com/LockR-Tech)). File này chỉ là **con trỏ** — tiến độ, luật và sơ đồ nằm ở repo [**docs**](https://github.com/LockR-Tech/docs). Không ghi tiến độ vào đây.

## Trước khi làm bất cứ việc gì

1. Repo docs phải nằm cạnh repo này (`../docs`). Chưa có: `git clone https://github.com/LockR-Tech/docs.git ../docs`. Có rồi: `git -C ../docs pull --ff-only`.
2. Đọc `../docs/AGENTS.md` — giao thức bắt đầu/kết thúc phiên.
3. Đọc `../docs/STATUS.md` — tiến độ, rủi ro, việc đang làm, việc tiếp theo.
4. Đọc file luồng liên quan trong `../docs/02-flows/`.

## Luật bắt buộc

- `main` = production. **Merge vào `main` là deploy thật.** Không push thẳng `main` — nhánh + PR + review + squash merge.
- Nhánh `<type>/<gap-id>-<mo-ta>`; commit và tiêu đề PR theo Conventional Commits; footer `Refs: F2-G01`.
- Không commit secret, `.env` thật, file build. Không thêm trailer `Co-Authored-By` của công cụ AI.
- Việc chỉ xong khi tài liệu ở `../docs` đã cập nhật (STATUS, file luồng, sơ đồ nếu đổi trạng thái).
- **Đổi giao diện ⇒ cập nhật hướng dẫn trên màn hình + HDSD trong cùng PR** ([luật](https://github.com/LockR-Tech/docs/blob/main/04-engineering/huong-dan-giao-dien.md), mục cuối file). Check CI "Hướng dẫn trên màn hình" chặn merge nếu quên.

## Riêng repo này

- **Deploy:** merge `main` (trừ `**.md`, `docs/**`) ⇒ `deploy-web.yml` chạy `flutter test` (fail = không deploy) → build web → Worker `laundry-locker-mobile-web`. App Android/iOS build tay, tăng `version:` trong `pubspec.yaml`.
- **Lệnh:** `flutter pub get` · `flutter run` · `flutter test` · `flutter analyze`.
- **Cấu hình API:** `envied` đọc biến `API_BASE_URL` (không phải `API_URL`) từ `.env` (gitignore). `lib/core/config/env_config.g.dart` đã commit sẵn trỏ `https://api.locker-drone.tech`. Đổi `.env` ⇒ chạy `dart run build_runner build --delete-conflicting-outputs`. Emulator + backend local: `API_BASE_URL=http://10.0.2.2:18080`.
- **Không xoá** `assets/markdown/*.md` — `pubspec.yaml` khai báo làm asset.
- Luồng tủ dùng `lib/features/locker_ops/data/locker_ops_service.dart` (endpoint `/api/...`). Nhiều màn hình legacy (`features/orders`, `features/delegations`) còn gọi endpoint không có `/api` — đừng mở rộng chúng.
- Đăng nhập Google/Facebook cần SHA-1 và key hash của keystore đã khai trên Firebase / Facebook console.

## Hướng dẫn lần đầu trên màn hình (F3-G13) — LUẬT bắt buộc

Áp dụng cho mọi người và AI agent ([luật đầy đủ](https://github.com/LockR-Tech/docs/blob/main/04-engineering/huong-dan-giao-dien.md)). Bạn được nhắc ở mọi bước:

- **Claude Code**: `.claude/settings.json` (đã commit) có hook nhắc luật khi mở phiên, khi sửa file giao diện, và cuối lượt nếu giao diện đổi mà hướng dẫn chưa đổi.
- **Git**: `.githooks/pre-commit` nhắc khi commit file giao diện mà không kèm neo `TourAnchor` hay `assets/onboarding/`. Bật một lần cho mỗi bản clone: `bash tool/setup_hooks.sh`.
- **PR**: mẫu PR có mục "Hướng dẫn trên màn hình". Check CI **"Hướng dẫn trên màn hình"** (`.github/workflows/huong-dan.yml`) **đỏ** nếu PR đổi giao diện (`lib/**/presentation/`, `lib/shared/widgets/`, `lib/core/routing|presentation/`, `lib/l10n/app_{vi,en}.arb`) mà không có ít nhất một trong các việc sau: thêm / bớt `TourAnchor`, đổi `assets/onboarding/`, tick "Đã cập nhật hướng dẫn" kèm link PR frontend, tick "Không ảnh hưởng hướng dẫn — lý do: …".

Các bước phải làm:

Nội dung tour (nhóm, bước, chữ) dùng chung với web, nguồn duy nhất ở repo frontend `fe/public/onboarding/`; app tải bản mới nhất từ `https://admin.locker-drone.tech/onboarding/`, bản kèm trong `assets/onboarding/` chỉ để chạy khi mất mạng và để test. **Thêm / xoá / sửa một màn hình hay một nút thì cập nhật hướng dẫn NGAY:**

1. Gắn hoặc sửa neo `TourAnchor('<neo>', child: …)` (cùng mã với `data-tour` trên web khi là cùng phần tử).
2. Khai nhóm / bước ở `frontend/fe/public/onboarding/tours.json`: `platforms: ["mobile"]`, `mobileRoute` (route trong `AppRouter`), `placement`, `optional`, `openNav` (trang có ngăn kéo đăng ký `TourNav.register`).
3. Đủ chữ ở `locales/vi.json` và `locales/en.json`; chữ giao diện của tour (nút, hộp thoại) ở `lib/l10n/app_*.arb` (khoá `tour…`).
4. Đổi nội dung một nhóm ⇒ **TĂNG `version` của nhóm**.
5. Chạy `bash tool/sync_onboarding.sh` để chép nội dung + bộ ca kiểm tra sang app, rồi `flutter test test/onboarding` phải xanh (quét neo, route, chữ vi/en, bản kèm khớp nguồn).
6. Chụp lại ảnh HDSD của nhóm (`npm run hdsd:capture` ở repo frontend, chỉ dev/demo).
