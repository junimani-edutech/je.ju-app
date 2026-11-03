#!/bin/bash
set -e

echo "=== GENERATING .ENV FILE ==="
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env

echo "=== CHECKING .ENV CONTENTS ==="
cat .env
echo "============================="

echo "=== RUNNING BUILD_RUNNER ==="
flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs

echo "=== BUILDING WEB ==="
flutter/bin/flutter build web --release
