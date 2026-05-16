# OpenSSL 4.0.0 Compatibility Testing Guide

## Overview

This guide provides instructions for building and testing Crypt::OpenSSL::X509 with both OpenSSL 3.x and OpenSSL 4.x to ensure compatibility across versions.

## Changes Summary

The following changes were made to support OpenSSL 4.0.0's opaque ASN1 string types:

### Modified Functions
1. **sig_print()** - Use `ASN1_STRING_length()` and `ASN1_STRING_get0_data()` instead of direct struct access
2. **ia5string()** - Use `ASN1_STRING_get0_data()` for string data
3. **keyid_data()** - Use `ASN1_STRING_get0_data()` for AKID and SKID data
4. **is_asn1_type()** - Use `ASN1_STRING_type()` to check string type
5. **encoding()** - Use `ASN1_STRING_type()` to determine encoding

All changes use conditional compilation (`#if OPENSSL_VERSION_NUMBER >= 0x40000000L`) to maintain backward compatibility.

## Prerequisites

### Perl Dependencies (Carton)

This project uses [Carton](https://metacpan.org/pod/Carton) for dependency management. Install it if you don't have it:

```bash
# Install Carton
cpanm Carton

# Or via system package manager
brew install carton  # macOS
```

### macOS (Homebrew)

Install multiple OpenSSL versions:

```bash
# Install OpenSSL 3.x (current stable)
brew install openssl@3

# Install OpenSSL 4.x (when available - as of May 2026, use from source or pre-release)
# Note: OpenSSL 4.0 may not be in Homebrew yet, see "Building from Source" below
brew install openssl@4  # When available
```

### Building OpenSSL 4.0 from Source (if not in Homebrew)

```bash
# Clone OpenSSL repository
git clone https://github.com/openssl/openssl.git
cd openssl
git checkout openssl-4.0.0  # Or appropriate 4.0 tag/branch

# Configure and build
./Configure --prefix=/usr/local/openssl-4.0.0 \
            --openssldir=/usr/local/openssl-4.0.0 \
            darwin64-x86_64-cc shared

make -j$(sysctl -n hw.ncpu)
make test
sudo make install
```

## Testing with OpenSSL 3.x

### Set Environment Variables

```bash
# Homebrew OpenSSL 3.x path
export OPENSSL_PREFIX=/opt/homebrew/opt/openssl@3
export PKG_CONFIG_PATH="$OPENSSL_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export LDFLAGS="-L$OPENSSL_PREFIX/lib"
export CPPFLAGS="-I$OPENSSL_PREFIX/include"
```

### Install Dependencies and Build

```bash
# Install Perl dependencies via Carton (installs to local/)
carton install

# Clean previous builds
make clean 2>/dev/null || true
rm -f Makefile.old

# Generate Makefile with OpenSSL 3.x
carton exec perl Makefile.PL

# Verify OpenSSL version detected
grep OPENSSL_VERSION Makefile

# Build
carton exec make

# Run tests with Carton environment
carton exec make test

# Check for successful compilation
echo $?  # Should be 0
```

## Testing with OpenSSL 4.x

### Set Environment Variables

```bash
# For Homebrew OpenSSL 4.x (when available)
export OPENSSL_PREFIX=/opt/homebrew/opt/openssl@4

# OR for source-built OpenSSL 4.x
export OPENSSL_PREFIX=/usr/local/openssl-4.0.0

export PKG_CONFIG_PATH="$OPENSSL_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export LDFLAGS="-L$OPENSSL_PREFIX/lib"
export CPPFLAGS="-I$OPENSSL_PREFIX/include"
export DYLD_LIBRARY_PATH="$OPENSSL_PREFIX/lib:$DYLD_LIBRARY_PATH"
```

### Install Dependencies and Build

```bash
# Install Perl dependencies via Carton (if not already done)
carton install

# Clean previous builds
make clean 2>/dev/null || true
rm -f Makefile.old

# Generate Makefile with OpenSSL 4.x
carton exec perl Makefile.PL

# Verify OpenSSL version detected
grep OPENSSL_VERSION Makefile
# Should show 0x40000000 or higher

# Build (should compile without ASN1 struct errors)
carton exec make

# Run tests
carton exec make test

# Verify all tests pass
echo $?  # Should be 0
```

## Comprehensive Test Script

Create a test script to verify both versions:

```bash
#!/bin/bash
# test.sh

set -e

# Install dependencies once at the start
echo "Installing Perl dependencies via Carton..."
carton install

test_openssl_version() {
    local VERSION=$1
    local PREFIX=$2
    
    echo "================================"
    echo "Testing with OpenSSL $VERSION"
    echo "================================"
    
    export OPENSSL_PREFIX="$PREFIX"
    export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
    export LDFLAGS="-L$PREFIX/lib"
    export CPPFLAGS="-I$PREFIX/include"
    export DYLD_LIBRARY_PATH="$PREFIX/lib:$DYLD_LIBRARY_PATH"
    
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
}

# Test OpenSSL 3.x
test_openssl_version "3.x" "/opt/homebrew/opt/openssl@3"

# Test OpenSSL 4.x (adjust path as needed)
test_openssl_version "4.x" "/opt/homebrew/opt/openssl@4"  # or /usr/local/openssl-4.0.0

echo "================================"
echo "All tests completed successfully!"
echo "================================"
```

Make it executable and run:

```bash
chmod +x test.sh
./test.sh
```

## Manual Verification

### Check OpenSSL Version at Runtime

```bash
# Using Carton environment
carton exec perl -Mblib -MCrypt::OpenSSL::X509 -e 'print Crypt::OpenSSL::X509->OPENSSL_VERSION_NUMBER . "\n"'
```

### Verify No Direct Struct Access Compilation Errors

When building with OpenSSL 4.x, ensure none of these errors appear:

- ❌ `error: invalid use of incomplete typedef 'ASN1_OCTET_STRING'`
- ❌ `error: invalid use of incomplete typedef 'ASN1_BIT_STRING'`
- ❌ `error: invalid use of incomplete typedef 'ASN1_STRING'`

You may still see warnings about discarded const qualifiers (these are pre-existing and non-fatal):

- ⚠️ `warning: assignment discards 'const' qualifier from pointer target type`

## Troubleshooting

### Issue: Wrong OpenSSL Version Detected

```bash
# Force specific OpenSSL path with Carton
carton exec perl Makefile.PL INC="-I/path/to/openssl/include" \
                              LIBS="-L/path/to/openssl/lib -lssl -lcrypto"
```

### Issue: Library Not Found at Runtime

```bash
# Add to library path (macOS)
export DYLD_LIBRARY_PATH="/path/to/openssl/lib:$DYLD_LIBRARY_PATH"

# Or install_name_tool to fix the binary
otool -L blib/arch/auto/Crypt/OpenSSL/X509/X509.bundle
```

### Issue: Multiple OpenSSL Versions Conflict

```bash
# Check which OpenSSL is being used
carton exec perl Makefile.PL
grep -E "OPENSSL|INC|LIBS" Makefile

# Explicitly set paths
unset PKG_CONFIG_PATH
export PKG_CONFIG_PATH="/specific/openssl/lib/pkgconfig"
```

### Issue: Missing Perl Dependencies

```bash
# Ensure Carton dependencies are installed
carton install --deployment

# Check installed modules
carton list
```

## CI/CD Considerations

For automated testing in CI pipelines:

```yaml
# Example GitHub Actions matrix
matrix:
  openssl-version: ['3.0', '3.5', '4.0']
  
steps:
  - name: Install Carton
    run: cpanm -n Carton
    
  - name: Install Perl dependencies
    run: carton install --deployment
      
  - name: Install OpenSSL
    run: |
      # Install specific OpenSSL version
      
  - name: Build and Test
    run: |
      export OPENSSL_PREFIX=/path/to/openssl-${{ matrix.openssl-version }}
      carton exec perl Makefile.PL
      carton exec make
      carton exec make test
```

## Expected Results

### OpenSSL 3.x
- ✅ All tests pass
- ✅ Backward compatibility maintained
- ✅ Uses old direct struct access code path

### OpenSSL 4.x
- ✅ Compiles without ASN1 typedef errors
- ✅ All tests pass
- ✅ Uses new accessor function code path
- ⚠️ May have const qualifier warnings (non-fatal)

## Further Testing

For comprehensive validation:

```bash
# Run extended tests with Carton
carton exec prove -lv t/

# Test specific functionality
carton exec perl -Mblib t/x509.t
carton exec perl -Mblib t/san.t
carton exec perl -Mblib t/utf8.t
```

## Reporting Issues

When reporting issues, please include:

1. OpenSSL version: `openssl version`
2. Build output: Full output from `perl Makefile.PL` and `make`
3. Test results: Output from `make test`
4. Environment: `echo $OPENSSL_PREFIX`, `pkg-config --modversion openssl`

## References

- [OpenSSL 4.0 NEWS](https://github.com/openssl/openssl/blob/master/NEWS.md#openssl-40)
- [OpenSSL Migration Guide](https://github.com/openssl/openssl/blob/master/doc/man7/migration_guide.pod)
- Issue #123: Fails to build with OpenSSL 4.0.0
