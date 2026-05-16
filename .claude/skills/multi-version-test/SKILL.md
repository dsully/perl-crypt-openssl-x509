---
name: multi-version-test
description: Build and test Crypt::OpenSSL::X509 against a specific Homebrew-installed OpenSSL version
disable-model-invocation: true
---

The user has invoked `/multi-version-test` to run the build+test cycle against one or more OpenSSL versions.

## Available OpenSSL versions (Homebrew paths)

| Version arg | Homebrew prefix |
|-------------|-----------------|
| `1.1`       | `/opt/homebrew/opt/openssl@1.1` |
| `3`         | `/opt/homebrew/opt/openssl@3` |
| `3.0`       | `/opt/homebrew/opt/openssl@3.0` |
| `3.5`       | `/opt/homebrew/opt/openssl@3.5` |
| `4`         | `/opt/homebrew/opt/openssl@4` |
| `all`       | run all of the above in sequence |

## Steps

1. If no version argument was given, list the available versions above and ask which to use.
2. For the requested version(s), run `scripts/test.sh` — but for a single version, call the function directly rather than running the full script:

```bash
VERSION="<version>"
PREFIX="/opt/homebrew/opt/openssl@<version>"

export OPENSSL_PREFIX="$PREFIX"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
export LDFLAGS="-L$PREFIX/lib"
export CPPFLAGS="-I$PREFIX/include"
export DYLD_LIBRARY_PATH="$PREFIX/lib"

make clean 2>/dev/null || true
rm -f Makefile.old
carton exec perl Makefile.PL
carton exec make
carton exec make test
```

3. Report pass/fail clearly. For failures, surface the compiler error or failing test file verbatim.
4. If `carton` is not available, try running `perl`, `make` directly after setting the env vars.
