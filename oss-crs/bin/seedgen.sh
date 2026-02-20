#!/bin/bash
# Lacrosse Seedgen Entrypoint
# LLM-powered seed generation with model rotation

set -e

export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

echo "=== Lacrosse Seedgen ==="
echo "OSS_CRS_TARGET: ${OSS_CRS_TARGET:-unset}"
echo "OSS_CRS_TARGET_HARNESS: ${OSS_CRS_TARGET_HARNESS:-unset}"

# Download build output (includes harness_src/ with source files)
libCRS download-build-output build-libfuzzer /out

# Register seed output directory with libCRS watchdog
mkdir -p /artifacts/seeds
libCRS register-submit-dir seed /artifacts/seeds

# Map OSS-CRS LiteLLM env vars to lacrosse's expected env vars
# find_inputs.py -> standard_args.py -> init_llm() reads these
if [ -n "$OSS_CRS_LLM_API_URL" ]; then
    export AIXCC_LITELLM_HOSTNAME="$OSS_CRS_LLM_API_URL"
    echo "[seedgen] AIXCC_LITELLM_HOSTNAME=$AIXCC_LITELLM_HOSTNAME"
else
    echo "[seedgen] WARNING: OSS_CRS_LLM_API_URL not set"
fi

if [ -n "$OSS_CRS_LLM_API_KEY" ]; then
    export LITELLM_KEY="$OSS_CRS_LLM_API_KEY"
    echo "[seedgen] LITELLM_KEY is set"
else
    echo "[seedgen] WARNING: OSS_CRS_LLM_API_KEY not set"
fi

# Configuration from crs.yaml additional_env
MODELS=(${SEEDGEN_MODELS//,/ })
EXAMPLES="${SEEDGEN_EXAMPLES:-10}"
ROUNDS="${SEEDGEN_ROUNDS:-0}"
HARNESS="${OSS_CRS_TARGET_HARNESS}"

echo "[seedgen] Models: ${MODELS[*]}"
echo "[seedgen] Examples per model: $EXAMPLES"
echo "[seedgen] Rounds: $ROUNDS (0=infinite)"

# Find harness source file from builder output
# The builder copies harness source files to /out/harness_src/
HARNESS_SRC=""
if [ -d "/out/harness_src" ]; then
    # Try exact match first
    HARNESS_SRC=$(find /out/harness_src -name "*${HARNESS}*" -type f 2>/dev/null | head -1)
    # Fall back to any harness source file
    if [ -z "$HARNESS_SRC" ]; then
        HARNESS_SRC=$(find /out/harness_src -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.cc" \) 2>/dev/null | head -1)
    fi
fi

if [ -z "$HARNESS_SRC" ]; then
    echo "[seedgen] ERROR: No harness source file found in /out/harness_src/"
    echo "[seedgen] Contents of /out/harness_src/:"
    ls -la /out/harness_src/ 2>/dev/null || echo "  (directory does not exist)"
    exit 1
fi

echo "[seedgen] Using harness source: $HARNESS_SRC"

# Main seed generation loop
round=0
while [ "$ROUNDS" -eq 0 ] || [ "$round" -lt "$ROUNDS" ]; do
    round=$((round + 1))
    echo "[seedgen] === Round $round ==="

    for model_flag in "${MODELS[@]}"; do
        echo "[seedgen] Generating seeds with model: $model_flag"
        cd /crs/langchain && python -m lacrosse_llm.find_inputs \
            --examples "$EXAMPLES" \
            --harness-file "$HARNESS_SRC" \
            --output-dir /artifacts/seeds \
            "--${model_flag}" \
            || echo "[seedgen] WARNING: find_inputs.py failed for model $model_flag (continuing)"
    done

    echo "[seedgen] Round $round complete. Seeds in /artifacts/seeds/:"
    ls /artifacts/seeds/ 2>/dev/null | wc -l

    # Sleep between rounds (only if looping)
    if [ "$ROUNDS" -eq 0 ] || [ "$round" -lt "$ROUNDS" ]; then
        echo "[seedgen] Sleeping 30s before next round..."
        sleep 30
    fi
done

echo "[seedgen] All rounds complete."
# Keep container alive so oss-crs doesn't abort the run
while true; do sleep 60; done
