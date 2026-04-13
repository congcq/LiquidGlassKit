#!/bin/bash

FRAMEWORK_NAME="LiquidGlassKit"
SOURCES_DIR="./Sources/${FRAMEWORK_NAME}"
BUILD_DIR="./build"
RESOURCES_BUNDLE_NAME="${FRAMEWORK_NAME}ShaderResources"
SDK_PATH=$(xcrun --show-sdk-path --sdk iphoneos)

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"


echo "🔨 Compiling Metal shaders..."
mkdir -p "${BUILD_DIR}/shaders"

for metal_file in ${SOURCES_DIR}/*.metal; do
    if [ -f "$metal_file" ]; then
        filename=$(basename "$metal_file" .metal)
        echo " - Compiling $filename.metal..."
        xcrun -sdk ${SDK_PATH} metal \
            -c \
            -target air64-apple-ios13 \
            -ffast-math \
            "$metal_file" \
            -o "${BUILD_DIR}/shaders/$filename.air"
    fi
done

xcrun -sdk iphoneos metallib \
    ${BUILD_DIR}/shaders/*.air \
    -o "${BUILD_DIR}/default.metallib"


echo "📦 Creating resource bundle..."
mkdir -p "${BUILD_DIR}/${RESOURCES_BUNDLE_NAME}.bundle"
cp "${BUILD_DIR}/default.metallib" "${BUILD_DIR}/${RESOURCES_BUNDLE_NAME}.bundle/"


cat > "${BUILD_DIR}/${RESOURCES_BUNDLE_NAME}.bundle/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleIdentifier</key>
    <string>com.DnV1eX.${RESOURCES_BUNDLE_NAME}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>BNDL</string>
    <key>CFBundleName</key>
    <string>${RESOURCES_BUNDLE_NAME}</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF


echo "🔨 Compiling Swift framework..."
mkdir -p "${BUILD_DIR}/${FRAMEWORK_NAME}.framework/Headers"
mkdir -p "${BUILD_DIR}/${FRAMEWORK_NAME}.framework/Modules"

TARGET="arm64-apple-ios13"

xcrun -sdk "${SDK_PATH}" swiftc -emit-library \
    -target "${TARGET}" \
    -module-name "${FRAMEWORK_NAME}" \
    -emit-module \
    -emit-module-path "${BUILD_DIR}/${FRAMEWORK_NAME}.swiftmodule/${TARGET}.swiftmodule" \
    -emit-objc-header \
    -emit-objc-header-path "${BUILD_DIR}/${FRAMEWORK_NAME}.framework/Headers/${FRAMEWORK_NAME}-Swift.h" \
    -parse-as-library \
    -enable-library-evolution \
    -Xfrontend -enable-objc-interop \
    -Xlinker -install_name -Xlinker "@rpath/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" \
    "${SOURCES_DIR}"/*.swift \
    -o "${BUILD_DIR}/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}"

mkdir -p "${BUILD_DIR}/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule"
cp -R "${BUILD_DIR}/${FRAMEWORK_NAME}.swiftmodule/"* "${BUILD_DIR}/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule/"
cp -R "Info.plist" "${BUILD_DIR}/${FRAMEWORK_NAME}.framework/"


echo "✅ Build complete!"
echo "📦 Framework: ${BUILD_DIR}/${FRAMEWORK_NAME}.framework"
echo "📦 Resources: ${BUILD_DIR}/${RESOURCES_BUNDLE_NAME}.bundle"

echo "Creating tbd file..."
xcrun tapi stubify ${BUILD_DIR}/${FRAMEWORK_NAME}.framework/LiquidGlassKit -o ${BUILD_DIR}/tbd/LiquidGlassKit.tbd