#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# start_integrationtests.sh — Run SMAG integration tests inside a Docker
# container that provides an Android emulator, or against a connected device.
#
# Prerequisites (Docker mode):
#   - Docker installed and running on the host.
#   - KVM support enabled (/dev/kvm accessible).
#   - Internet access (first run downloads ~5 GB image).
#
# Prerequisites (local mode):
#   - A running Android emulator or connected device (via `adb devices`).
#
# Usage:
#   chmod +x start_integrationtests.sh
#   ./start_integrationtests.sh           # Docker emulator (requires KVM)
#   ./start_integrationtests.sh --local   # Run against connected device
# ---------------------------------------------------------------------------
set -euo pipefail

IMAGE="budtmo/docker-android:emulator_14.0"
CONTAINER_NAME="smag-android-emulator"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
EMULATOR_PORT=5554
DEVICE_SERIAL="localhost:$EMULATOR_PORT"
APP_ID="de.karoc.smag"
MODE="docker"

wait_for_host_device_ready() {
  local max_wait="${1:-120}"
  local elapsed=0

  echo "==> Waiting for host adb and Android services to settle…"
  if [[ "$DEVICE_SERIAL" == localhost:* ]]; then
    adb connect "$DEVICE_SERIAL" >/dev/null 2>&1 || true
  fi
  adb -s "$DEVICE_SERIAL" wait-for-device

  while [ $elapsed -lt $max_wait ]; do
    local boot_completed
    local dev_bootcomplete
    local bootanim

    boot_completed="$(adb -s "$DEVICE_SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')"
    dev_bootcomplete="$(adb -s "$DEVICE_SERIAL" shell getprop dev.bootcomplete 2>/dev/null | tr -d '\r')"
    bootanim="$(adb -s "$DEVICE_SERIAL" shell getprop init.svc.bootanim 2>/dev/null | tr -d '\r')"

    if adb -s "$DEVICE_SERIAL" shell pm path android >/dev/null 2>&1 &&
      [[ "$boot_completed" == "1" ]] &&
      [[ -z "$dev_bootcomplete" || "$dev_bootcomplete" == "1" ]] &&
      [[ -z "$bootanim" || "$bootanim" == "stopped" ]]; then
      adb -s "$DEVICE_SERIAL" shell input keyevent 82 >/dev/null 2>&1 || true
      adb -s "$DEVICE_SERIAL" shell settings put global window_animation_scale 0 >/dev/null 2>&1 || true
      adb -s "$DEVICE_SERIAL" shell settings put global transition_animation_scale 0 >/dev/null 2>&1 || true
      adb -s "$DEVICE_SERIAL" shell settings put global animator_duration_scale 0 >/dev/null 2>&1 || true
      sleep 3
      echo "==> Host adb and Android services are ready."
      return 0
    fi

    sleep 5
    elapsed=$((elapsed + 5))
    echo "    … waiting for adb/device services ($elapsed s / $max_wait s)"
  done

  echo "ERROR: Emulator connected but Android services did not settle in time."
  return 1
}

run_integration_tests() {
  local log_file="$1"
  local test_exit=0

  set +e
  flutter test integration_test/ -d "$DEVICE_SERIAL" 2>&1 | tee "$log_file"
  test_exit=${PIPESTATUS[0]}
  set -e

  return "$test_exit"
}

# Parse arguments.
if [[ "${1:-}" == "--local" ]]; then
  MODE="local"
fi

# ── Local mode: run against an already-connected device ──────────────────
if [[ "$MODE" == "local" ]]; then
  echo "==> Running integration tests against connected device…"
  DEVICES=$(adb devices | grep -w "device" | head -1 | awk '{print $1}')
  if [[ -z "$DEVICES" ]]; then
    echo "ERROR: No connected Android device found. Check 'adb devices'."
    exit 1
  fi
  echo "    Using device: $DEVICES"
  cd "$PROJECT_DIR"
  DEVICE_SERIAL="$DEVICES"
  wait_for_host_device_ready 60
  flutter test integration_test/ -d "$DEVICES"
  echo "SUCCESS: All integration tests passed."
  exit 0
fi

# ── Docker mode: start emulator in container ─────────────────────────────

# Check KVM support.
if [[ ! -e /dev/kvm ]]; then
  echo "ERROR: /dev/kvm not found — KVM is not available on this host."
  echo ""
  echo "The Docker Android emulator requires hardware-accelerated"
  echo "virtualisation (KVM). Options:"
  echo "  1. Enable KVM in your BIOS/UEFI settings."
  echo "  2. Run on a host with KVM support (bare-metal Linux or a VM with"
  echo "     nested virtualisation enabled)."
  echo "  3. Use --local to run tests against a connected device instead:"
  echo "       ./start_integrationtests.sh --local"
  exit 1
fi

echo "==> Pulling Docker Android emulator image (may take a while on first run)…"
docker pull "$IMAGE"

echo "==> Stopping any previous container…"
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

echo "==> Starting Android emulator container…"
docker run -d \
  --name "$CONTAINER_NAME" \
  --privileged \
  --device /dev/kvm \
  -e DEVICE="pixel_7" \
  -e WEB_VNC=true \
  -p 6080:6080 \
  -p "$EMULATOR_PORT:5555" \
  "$IMAGE"

echo "==> Waiting for emulator to boot (this can take 2–5 minutes)…"
MAX_WAIT=360
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
  # Check if the emulator's adb is reachable from inside the container.
  BOOT=$(docker exec "$CONTAINER_NAME" adb shell getprop sys.boot_completed 2>/dev/null || echo "")
  if [ "$BOOT" = "1" ]; then
    echo "==> Emulator is ready."
    break
  fi
  sleep 5
  ELAPSED=$((ELAPSED + 5))
  echo "    … still waiting ($ELAPSED s / $MAX_WAIT s)"
done

if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
  echo "ERROR: Emulator did not boot within $MAX_WAIT seconds."
  docker logs "$CONTAINER_NAME" | tail -40
  docker rm -f "$CONTAINER_NAME"
  exit 1
fi

echo "==> Connecting host adb to the emulator…"
adb connect "$DEVICE_SERIAL" || true
adb -s "$DEVICE_SERIAL" wait-for-device
wait_for_host_device_ready 120

echo "==> Running integration tests…"
cd "$PROJECT_DIR"
TEST_LOG="$(mktemp)"
TEST_EXIT=0
run_integration_tests "$TEST_LOG" || TEST_EXIT=$?

if [ "$TEST_EXIT" -ne 0 ] && grep -q "No tests ran." "$TEST_LOG"; then
  echo "WARN: Flutter did not attach to the test app. Retrying once…"
  adb -s "$DEVICE_SERIAL" shell am force-stop "$APP_ID" >/dev/null 2>&1 || true
  adb disconnect "$DEVICE_SERIAL" >/dev/null 2>&1 || true
  adb connect "$DEVICE_SERIAL" >/dev/null 2>&1 || true
  wait_for_host_device_ready 120
  TEST_EXIT=0
  run_integration_tests "$TEST_LOG" || TEST_EXIT=$?
fi
rm -f "$TEST_LOG"

echo "==> Stopping emulator container…"
docker rm -f "$CONTAINER_NAME"

if [ "${TEST_EXIT:-0}" -ne 0 ]; then
  echo "FAIL: Integration tests exited with code ${TEST_EXIT}."
  exit "${TEST_EXIT}"
fi

echo "SUCCESS: All integration tests passed."
