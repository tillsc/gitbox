#!/bin/bash
set -e

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
  -showBuildSettings 2>/dev/null | grep "BUILT_PRODUCTS_DIR" | awk '{print $3}')

echo ""
echo "==> Done! App is at:"
echo "    $BUILD_DIR/Gitbox.app"
echo ""
echo "    To open: open \"$BUILD_DIR/Gitbox.app\""
