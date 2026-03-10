#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
ARTIFACTS_DIR=${ARTIFACTS_DIR:-$SCRIPT_DIR/artifacts}

first_existing_path() {
  local candidate
  for candidate in "$@"; do
    if [ -n "$candidate" ] && [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

SDK_DEFAULT="$HOME/Library/Android/sdk/system-images/android-33/default/arm64-v8a"
SDK_DIR=${SDK_DIR:-$SDK_DEFAULT}
KERNEL=${KERNEL:-$SDK_DIR/kernel-ranchu}
DATA_IMG=${DATA_IMG:-$ARTIFACTS_DIR/qemu_userdata.img}
LOG=${LOG:-$ARTIFACTS_DIR/qemu_boot.log}

if ! command -v qemu-system-aarch64 >/dev/null 2>&1; then
  echo "qemu-system-aarch64 不在 PATH 中" >&2
  exit 1
fi

mkdir -p "$ARTIFACTS_DIR"

if [ "$#" -gt 0 ] && [ "$1" = "twrp" ]; then
  if [ -n "${RAMDISK:-}" ]; then
    :
  else
    RAMDISK=$(first_existing_path \
      "$SCRIPT_DIR/ramdisk-recovery.cpio" \
      "$ARTIFACTS_DIR/ramdisk-recovery.cpio") || true
  fi
  EXTRA_APPEND="skip_initramfs"
  echo "=== 启动 TWRP recovery ==="
else
  RAMDISK=${RAMDISK:-$SDK_DIR/ramdisk.img}
  EXTRA_APPEND=""
  echo "=== 启动 android-33 正常系统 ==="
fi

if [ ! -f "$KERNEL" ]; then
  echo "kernel-ranchu 不存在: $KERNEL" >&2
  exit 1
fi

if [ ! -f "$RAMDISK" ]; then
  echo "ramdisk 不存在: $RAMDISK" >&2
  echo "可将 ramdisk-recovery.cpio 放到当前目录或 $ARTIFACTS_DIR" >&2
  exit 1
fi

if [ ! -f "$DATA_IMG" ]; then
  echo "创建数据盘: $DATA_IMG"
  truncate -s 8G "$DATA_IMG"
fi

: > "$LOG"

qemu-system-aarch64 \
  -machine virt \
  -cpu max \
  -smp 2 \
  -m 3072 \
  -kernel "$KERNEL" \
  -initrd "$RAMDISK" \
  -append "console=ttyAMA0 androidboot.hardware=ranchu androidboot.selinux=permissive androidboot.serialno=QEMU0001 $EXTRA_APPEND" \
  -drive file="$DATA_IMG",if=none,id=data,format=raw \
  -device virtio-blk-pci,drive=data \
  -device virtio-gpu-pci,edid=on,xres=1280,yres=720 \
  -display cocoa,show-cursor=on \
  -device usb-ehci \
  -device usb-tablet \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::5556-:5555 \
  -serial file:"$LOG" \
  -no-reboot