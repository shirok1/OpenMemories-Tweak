# OpenMemories: Tweak
An app to unlock settings on your Sony camera.
* Remove the 30min video recording limit
* Unlock the language menu
* Disable the NTSC nag screen
* For developers: Enable telnet and adb daemons

## Installation
Please read [this section](https://github.com/ma1co/Sony-PMCA-RE#installing-android-apps) for up-to-date information on installing the app.

## Compatibility
This app should be compatible with all Sony cameras supporting PlayMemories Camera Apps (PMCA). See [here](https://github.com/ma1co/OpenMemories-Framework/blob/master/docs/Cameras.md) for a full list.

## Building

Run the complete build from the repository root:

```sh
./gradlew assembleDebug
```

The APK is written to `app/build/outputs/apk/debug/app-debug.apk`. The wrapper
uses Gradle 7.6.4 with Android Gradle Plugin 7.4.2 and **JDK 17**. On macOS,
`gradlew` selects an installed JDK 17 when `JAVA_HOME` is unset. For Android Studio,
select JDK 17 as the Gradle JDK. Java sources still target Java 8. Dependency resolution uses Google Maven and Maven
Central.

### SDK and source dependencies

```sh
android sdk install platforms/android-29 build-tools/30.0.3 ndk/16.1.4479499
git submodule update --init app/src/main/jni/platform app/src/main/jni/android_platform_system_core
```

Initialize only these direct submodules, without `--recursive`. The nested
`platform/stlport` checkout is used by Platform's separate Gen1 updater and is
not needed by this app.

Use **NDK r16b (16.1.4479499)** from SDK Manager. Android native code uses
Clang and static libc++, not STLport. It retains `armeabi`; the native compilation
API is 14 because r16b no longer supplies API 9/10. The APK still declares
`minSdkVersion` and `targetSdkVersion` 10. SDK 29 is used for Java compilation.
This adopts the newer host JDK, Build Tools and NDK used by
[Recipe Lab](https://github.com/voxivoid/recipe-lab-sony-pmca/blob/main/build.sh),
while retaining libc++ and a Gradle build entry point.

Gradle calls `ndk-build` through its own task, independently of AGP's supported
native ABI list. It stages only the three intended native files for packaging;
Sony link stubs are never included. Both debug and release APKs use optimized,
stripped native binaries. The `compat/legacy_adbd.h` header preserves the old
property-service wire format required by the bundled Gingerbread adbd.

### Linux helper on macOS

`protectiontweak` runs outside the Android chroot and retains its GNU/Linux ABI.
Build it with native Homebrew Clang/LLD and the headers and ARM libraries from
**Linaro 7.5-2019.12**:

```sh
brew install llvm lld
```

Download and extract
[`gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabi.tar.xz`](https://developer.arm.com/-/cdn-downloads/permalink/legacy-linaro-gnu-toolchains/7.5-2019.12/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabi.tar.xz).
The verified archive SHA-256 is
`dda99cf2fc0a8b6d54440121c47645ab0b4dc921cc2d24f88707ea9741adc933`.
The Linux compiler executables in the archive are not run; no Linux VM is needed.

Copy `local.properties.example` to `local.properties` and set the absolute SDK,
NDK, Linaro, LLVM and LLD paths. Gradle passes the cross-compilation settings to
Make. It uses the old libstdc++ string ABI (`_GLIBCXX_USE_CXX11_ABI=0`) and a
non-PIE Linux executable to stay close to the original build. If `linaro.dir`
is omitted, Make still uses `arm-linux-gnueabi-gcc/g++` from `PATH`.

On Apple Silicon, the r16b host binaries require Rosetta. The Gradle task
selects Rosetta and system awk automatically, without modifying the SDK-managed
NDK. Homebrew Clang/LLD for the Linux helper runs natively on Apple Silicon.

### Verification scope

The complete debug APK has been built with this configuration and its signature
verified for API 10; its DEX format is 035. Native strong imports were checked
against the NDK r14b API 9 stub libraries plus the Sony OSAL link stub, with no
missing symbols. This audit does not make API 10 officially supported by r16b.
It packages only `libtweak.so`, `libadbd.so`, and
`libprotectiontweak.so`; Sony link stubs are excluded. The Linux helper's versioned
imports are `GLIBC_2.4`, `GLIBCXX_3.4`, `CXXABI_1.3`, and `GCC_3.5`.
Linaro's prebuilt startup objects mark this helper as ARMv7 with a Linux 3.2
ABI note, even though project sources use `-march=armv5te`. The original Makefile
intends this helper for Gen3 devices only; it is not an ARMv5-compatible helper.
This is build/link validation, not a guarantee of compatibility with every camera:
loading, exception handling and protection changes still require device testing.

## A word of caution
This is not an official Sony application. All information has been found through reverse engineering. Even though everything worked fine for our developers, it could cause harm to your hardware. If you break your camera, you get to keep both pieces. **We won't take any responsibility.**

## Usage
After installation, you should find the app in the "Application List" on your camera.

* Use the menu button to exit the app
* The app writes a log to the SD card (*TWEAKLOG.TXT*)

There are several different tabs:

### Video
Remove the 30 minute recording limit and enjoy (almost) unlimited video recording.

Additionally, remove the 5 minute 4K recording limit on the RX100M4.

### Region
Is your camera locked to Japanese? Is it set to the wrong region? Unlock all 30+ languages.

Is your camera locked to NTSC? Enable the PAL / NTSC selector.

Does your camera show you the NTSC nag screen on every startup? Disable the PAL / NTSC selector to get rid of the nag screen.

### Protection
Use this option only if you're asked to do so. Some of the above settings may fail because your settings file is locked. Disable the protection here. In practice, it should only matter to this app if your settings are protected or not. Otherwise, this won't change anything. We still recommend re-enabling protection after you're done tweaking your settings.

### Developer
#### Wifi
Check the "Enable Wifi" checkbox to permanently connect the camera to your wifi access point.

Don't forget to increase the "Power save start time" in the menu, or the camera may turn off automatically after a few minutes.

Once wifi is enabled, you can run and connect to the following daemons:

#### Telnet
To get a root shell on your camera, check the "Enable Telnet" checkbox. This starts a telnet daemon listening on port 23. Connect to it via wifi.

A few special commands you can run:

##### To run an Android shell
    android_console.sh

##### To dump the firmware to the sdcard
On Android 2:

    dd if=/dev/nflasha of=/android/mnt/sdcard/DUMP.DAT bs=1M

On Android 4:

    dd if=/dev/nflasha of=/android/storage/sdcard0/DUMP.DAT bs=1M

This operation will take some time (it copies about 500MB). Use [fwtool.py](https://github.com/ma1co/fwtool.py) to unpack the dump file.

#### ADB
To install and debug Android apps from your computer, check the "Enable ADB" checkbox. This starts an ADB daemon listening on port 5555. Connect to it via wifi:

    adb connect <your camera's ip>

## FAQ
### How does it all work?
[nex-hack](http://www.personal-view.com/faqs/sony-hack/hack-development) managed to decrypt firmware updates (see [fwtool.py](https://github.com/ma1co/fwtool.py) for a more recent unpacker). The [PMCA-RE](https://github.com/ma1co/Sony-PMCA-RE) project reverse engineered how apps are installed. This allows us to run custom code. With the knowledge from the firmware, we found out how settings are stored on the camera (hint: in a file called *Backup.bin*). We can now change these settings directly, also the ones locked by Sony.

### It doesn't work for me!
First, thanks for testing. If you encounter a bug, please open an issue!

### How can I remove the app?
You can uninstall it normally with the "Application Management" app. The modified settings are preserved even if you remove the app.

### What happens if i do a factory reset?
Some settings might be removed, others will be permanent. We still have to investigate a bit more to find out which features are reset and how. In the worst case, you can reinstall the app (all apps are removed in a factory reset) and apply the settings again.

### What happens if i do a firmware update?
See above.

### I have an old camera that doesn't support apps
Depending on your camera, tweaks may be applied using a method based on the firmware update process: [More information](https://github.com/ma1co/Sony-PMCA-RE#tweaking-camera-settings)

### Can you add feature X?
Keep in mind that this app can only change settings that are already there and just hidden by Sony. However, there are still about 15 000 entries in the settings file. So finding out what a particular setting does is quite an effort. But if you have ideas, feel free to open an issue!
