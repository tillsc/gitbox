#!/bin/bash
set -e

echo "==> Checking prerequisites..."

if ! command -v xcodebuild &>/dev/null; then
  echo "ERROR: xcodebuild not found. Install Xcode from the App Store."
  exit 1
fi

if ! command -v cmake &>/dev/null; then
  echo "ERROR: cmake not found. Install it via: brew install cmake"
  exit 1
fi

# Check if Xcode first launch setup has been completed
if ! xcodebuild -version &>/dev/null; then
  echo "==> Running xcodebuild -runFirstLaunch (requires sudo)..."
  sudo xcodebuild -runFirstLaunch
fi

# Check if Xcode license has been accepted
if xcodebuild -version 2>&1 | grep -q "license"; then
  echo "ERROR: Xcode license not accepted. Run: sudo xcodebuild -license accept"
  exit 1
fi

echo "==> Initializing submodules..."
git submodule update --init --recursive

echo "==> Building libgit2..."
mkdir -p libgit2/build
cmake -S libgit2 -B libgit2/build \
  -DCMAKE_OSX_ARCHITECTURES=x86_64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=11.5 \
  -DBUILD_SHARED_LIBS=OFF \
  -DUSE_SSH=OFF \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -Wno-dev
make -C libgit2/build -j$(sysctl -n hw.ncpu)

echo "==> Building Gitbox..."
xcodebuild \
  -scheme Gitbox \
  -configuration Debug \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)" | grep -v "^ld: warning"

BUILD_DIR=$(xcodebuild \
  -scheme Gitbox \
  -configuration Debug \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  -showBuildSettings 2>/dev/null | grep -E "^\s+BUILT_PRODUCTS_DIR\s*=" | awk '{print $3}')

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Copying Gitbox.app to project directory..."
rm -rf "$SCRIPT_DIR/Gitbox.app"
ditto "$BUILD_DIR/Gitbox.app" "$SCRIPT_DIR/Gitbox.app"

echo ""
echo "==> Done! App is at:"
echo "    $SCRIPT_DIR/Gitbox.app"
echo ""
echo "    To open: open \"$SCRIPT_DIR/Gitbox.app\""
