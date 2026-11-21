#!/usr/bin/env bash
# Chép nội dung hướng dẫn lần đầu (F3-G13) từ repo frontend (nguồn duy nhất, fe/public/onboarding/) vào app:
#   - assets/onboarding/: bản kèm trong app, dùng khi không tải được bản mới từ admin.locker-drone.tech;
#   - test/onboarding/fixtures/: bộ ca kiểm tra engine dùng chung với web.
# Chạy từ thư mục repo mobile, repo frontend phải nằm cạnh (../frontend) hoặc đặt FRONTEND_DIR.
set -euo pipefail
cd "$(dirname "$0")/.."
FE="${FRONTEND_DIR:-../frontend}/fe"
[ -f "$FE/public/onboarding/tours.json" ] || { echo "Không thấy $FE/public/onboarding/tours.json"; exit 1; }
mkdir -p assets/onboarding/locales test/onboarding/fixtures
cp "$FE/public/onboarding/tours.json" assets/onboarding/tours.json
cp "$FE"/public/onboarding/locales/*.json assets/onboarding/locales/
cp "$FE/tests/fixtures/onboarding-cases.json" test/onboarding/fixtures/onboarding-cases.json
echo "Đã chép: tours.json, locales/$(ls "$FE"/public/onboarding/locales | tr '\n' ' '), onboarding-cases.json"
