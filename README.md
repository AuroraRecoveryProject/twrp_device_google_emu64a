# twrp_device_google_emu64a

这个设备树目录同时包含两部分信息：

1. `emu64a` 目标的设备树内容
2. 在 macOS 上用裸 QEMU 启动 TWRP recovery 的最小方法

当前主线已经不是 AVD / emulator 出图，而是裸 QEMU：

```text
qemu-system-aarch64
  + android-33 kernel-ranchu
  + ramdisk-recovery.cpio
  + virtio-gpu-pci
  + 当前设备树里的 recovery root overlay
```

## 前提

需要准备：

1. macOS
2. `qemu-system-aarch64`
3. Android SDK 的 android-33 arm64 system image
4. 已经构建或拉回来的 `ramdisk-recovery.cpio`

### 安装 QEMU

```bash
brew install qemu
```

### Android SDK 路径

默认脚本使用：

```text
$HOME/Library/Android/sdk/system-images/android-33/default/arm64-v8a
```

其中必须存在：

```text
kernel-ranchu
ramdisk.img
```

## recovery 产物

当前启动脚本默认读取仓库根目录下的：

```text
ramdisk-recovery.cpio
```

如果你是在远端编译完成后拉回本地，可以直接把它放到仓库根目录。

## 启动方法

进入设备树目录后，直接运行：

```bash
cd device_tree/twrp_device_google_emu64a
bash launch_qemu.sh twrp
```

这会启动：

1. `kernel-ranchu`
2. 仓库根目录下的 `ramdisk-recovery.cpio`
3. 仓库根目录下的 `qemu_userdata.img`

如果 `qemu_userdata.img` 不存在，脚本会自动创建一个 8G 的 raw 数据盘。

## 启动正常系统

如果只是验证 QEMU + 内核 + 显示链，不启动 TWRP，可以运行：

```bash
cd device_tree/twrp_device_google_emu64a
bash launch_qemu.sh
```

这时会使用 SDK 自带的 `ramdisk.img`。

## 当前脚本默认参数

当前脚本固定使用：

1. `-machine virt`
2. `-device virtio-gpu-pci,edid=on,xres=1280,yres=720`
3. `-device virtio-net-pci`
4. `hostfwd=tcp::5556-:5555`
5. `-display cocoa,show-cursor=on`

也就是说，宿主机上 ADB 应连接：

```bash
adb connect 127.0.0.1:5556
adb -s 127.0.0.1:5556 get-state
```

## 串口调试

当前 `launch_qemu.sh` 默认把串口写到仓库根目录下的：

```text
qemu_boot.log
```

如果需要可交互串口调试，可以临时把脚本里的串口参数改成：

```text
-serial tcp:127.0.0.1:5557,server,nowait
```

然后在宿主机上连接：

```bash
nc 127.0.0.1 5557
```

连上后会看到：

```text
console:/ $
```

这时可以直接执行：

```text
getprop sys.usb.config
getprop init.svc.adbd
ifconfig eth0
ls /dev/socket
cat /tmp/recovery.log
```

如果只想一次性发几条命令：

```bash
{
  printf '\r\ngetprop sys.usb.config\r\n'
  printf 'getprop init.svc.adbd\r\n'
  printf 'ifconfig eth0\r\n'
  sleep 2
} | nc 127.0.0.1 5557
```

## 当前稳定结论

当前设备树里已经收敛了这些关键修复：

1. recovery root overlay 直接放在设备树里
2. 所需 `.ko` 已直接放进 `recovery/root/lib/modules`
3. `init.recovery.ranchu.rc` 已收敛到 QEMU 路线可用版本
4. ADB 通过 `5556 -> guest 5555` 工作
5. `sys.usb.config` 会被强制收敛回 `adb`
6. `eth0` 会在 `sys.usb.config=adb` 时由 init 负责配置

## 环境变量覆盖

如果默认路径不符合本地环境，可以在启动前覆盖：

```bash
SDK_DIR=/your/sdk/path \
RAMDISK=/your/ramdisk-recovery.cpio \
DATA_IMG=/your/qemu_userdata.img \
LOG=/your/qemu_boot.log \
bash launch_qemu.sh twrp
```
