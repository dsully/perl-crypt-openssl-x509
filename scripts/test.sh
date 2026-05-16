#!/bin/bash
# test.sh

set -e

# Install dependencies once at the start
echo "Installing Perl dependencies via Carton..."
carton install

test_openssl_version() {
    local VERSION=$1
    local PREFIX=$2

    # Capture original values so they can be restored after each run
    local _ORIG_OPENSSL_PREFIX="$OPENSSL_PREFIX"
    local _ORIG_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    local _ORIG_LDFLAGS="$LDFLAGS"
    local _ORIG_CPPFLAGS="$CPPFLAGS"
    local _ORIG_DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH"

    echo "================================"
    echo "Testing with OpenSSL $VERSION"
    echo "================================"

    export OPENSSL_PREFIX="$PREFIX"
    export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$_ORIG_PKG_CONFIG_PATH"
    export LDFLAGS="-L$PREFIX/lib"
    export CPPFLAGS="-I$PREFIX/include"
    export DYLD_LIBRARY_PATH="$PREFIX/lib:$_ORIG_DYLD_LIBRARY_PATH"

    # Clean
    make clean 2>/dev/null || true
    rm -f Makefile.old

    # Configure
    carton exec perl Makefile.PL

    # Verify version
    echo -n "Detected OpenSSL version: "
    grep "OPENSSL_PREFIX" Makefile || grep "INC.*openssl" Makefile | head -1

    # Build
    echo "Building..."
    carton exec make

    # Test
    echo "Running tests..."
    carton exec make test

    echo "✓ OpenSSL $VERSION: SUCCESS"
    echo ""

    # Restore original environment so subsequent runs start from a clean state
    export OPENSSL_PREFIX="$_ORIG_OPENSSL_PREFIX"
    export PKG_CONFIG_PATH="$_ORIG_PKG_CONFIG_PATH"
    export LDFLAGS="$_ORIG_LDFLAGS"
    export CPPFLAGS="$_ORIG_CPPFLAGS"
    export DYLD_LIBRARY_PATH="$_ORIG_DYLD_LIBRARY_PATH"
}

# Test OpenSSL 3.x
test_openssl_version "3.x" "/opt/homebrew/opt/openssl@3"

# Test OpenSSL 3.0 (adjust path as needed)
test_openssl_version "3.0" "/opt/homebrew/opt/openssl@3.0"

# Test OpenSSL 3.5 (adjust path as needed)
test_openssl_version "3.5" "/opt/homebrew/opt/openssl@3.5"

# Test OpenSSL 4.x (adjust path as needed)
test_openssl_version "4.x" "/opt/homebrew/opt/openssl@4"  # or /usr/local/openssl-4.0.0

echo "================================"
echo "All tests completed successfully!"
echo "================================"