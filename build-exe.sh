#!/usr/bin/env bash
set -e

echo "=== Сборка React-приложения ==="
npm run build

echo "=== Сборка .exe для Windows ==="
GOOS=windows GOARCH=amd64 go build \
  -ldflags="-s -w -H windowsgui" \
  -o "Декоратор.exe" \
  .

echo ""
echo "✓ Готово: Декоратор.exe"
echo "  Размер: $(du -sh "Декоратор.exe" | cut -f1)"
