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

## Riêng repo này

- **Deploy:** merge `main` (trừ `**.md`, `docs/**`) ⇒ `deploy-web.yml` chạy `flutter test` (fail = không deploy) → build web → Worker `laundry-locker-mobile-web`. App Android/iOS build tay, tăng `version:` trong `pubspec.yaml`.
- **Lệnh:** `flutter pub get` · `flutter run` · `flutter test` · `flutter analyze`.
- **Cấu hình API:** `envied` đọc biến `API_BASE_URL` (không phải `API_URL`) từ `.env` (gitignore). `lib/core/config/env_config.g.dart` đã commit sẵn trỏ `https://api.locker-drone.tech`. Đổi `.env` ⇒ chạy `dart run build_runner build --delete-conflicting-outputs`. Emulator + backend local: `API_BASE_URL=http://10.0.2.2:18080`.
- **Không xoá** `assets/markdown/*.md` — `pubspec.yaml` khai báo làm asset.
- Luồng tủ dùng `lib/features/locker_ops/data/locker_ops_service.dart` (endpoint `/api/...`). Nhiều màn hình legacy (`features/orders`, `features/delegations`) còn gọi endpoint không có `/api` — đừng mở rộng chúng.
- Đăng nhập Google/Facebook cần SHA-1 và key hash của keystore đã khai trên Firebase / Facebook console.
