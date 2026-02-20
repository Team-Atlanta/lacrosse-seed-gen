#!/bin/bash
# Lacrosse Seedgen LibFuzzer Builder
# Compiles target with libfuzzer+ASan and extracts harness source for seedgen

set -e

export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

echo "[builder-libfuzzer] Starting libfuzzer+ASan build..."
echo "[builder-libfuzzer] FUZZING_ENGINE=${FUZZING_ENGINE:-libfuzzer}"
echo "[builder-libfuzzer] SANITIZER=${SANITIZER:-address}"
echo "[builder-libfuzzer] OUT=$OUT"
echo "[builder-libfuzzer] SRC=$SRC"

# Run OSS-Fuzz compile
compile

# Copy harness source files to output for seedgen analysis
HARNESS_DIR="$OUT/harness_src"
mkdir -p "$HARNESS_DIR"
for src_dir in /src /project /fuzz "$SRC"; do
    if [ -d "$src_dir" ]; then
        find "$src_dir" -maxdepth 3 -name "*.c" -o -name "*.cpp" -o -name "*.cc" 2>/dev/null | while read -r f; do
            if grep -q "LLVMFuzzerTestOneInput\|fuzzerTestOneInput" "$f" 2>/dev/null; then
                echo "[builder-libfuzzer] Copying harness source: $f"
                cp "$f" "$HARNESS_DIR/" 2>/dev/null || true
            fi
        done
    fi
done

echo "[builder-libfuzzer] Harness sources found: $(ls "$HARNESS_DIR/" 2>/dev/null | wc -l)"

# Submit build output via libCRS
echo "[builder-libfuzzer] Submitting build output..."
libCRS submit-build-output "$OUT" build-libfuzzer

echo "[builder-libfuzzer] Build complete!"
