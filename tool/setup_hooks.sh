#!/usr/bin/env bash
# Bật git hook của repo (một lần cho mỗi bản clone): pre-commit nhắc cập nhật hướng dẫn trên màn hình khi đổi
# giao diện (F3-G13). Chạy từ thư mục repo mobile: bash tool/setup_hooks.sh
set -euo pipefail
cd "$(dirname "$0")/.."
git config core.hooksPath .githooks
chmod +x .githooks/* 2>/dev/null || true
echo "Đã bật git hook: $(git config core.hooksPath)"
