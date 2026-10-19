# NDK r16b still supports armeabi; its minimum native API is 14.
# The APK remains API 10. Audit imported symbols before deploying to old cameras.
APP_ABI := armeabi
APP_STL := c++_static
APP_PLATFORM := android-14
NDK_TOOLCHAIN_VERSION := clang
