# TODO

## Follow-up items from PR 128 review

PR 128 fixed a real bug (package-level cache shared across all certificate instances in
`has_extension_oid`). The patch was accepted as-is, but the review surfaced two
correctness/performance concerns worth addressing in a future pass.

### 1. `has_extension_oid` croaks on certs with no extensions (API contract broken)

`extensions_by_oid` in XS croaks with `"No extensions found\n"` when
`X509_get_ext_count == 0`. The new code calls it unconditionally, so any cert with zero
extensions will throw instead of returning false, contradicting the documented contract
("Return true if the certificate has the extension specified by OID").

`subjectaltname()` already handles this identically-named croak with an `eval {}` wrapper
(X509.pm line 93-96). `has_extension_oid` needs the same treatment.

### 2. No per-instance caching — O(n) XS work on every call

`extensions_by_oid` allocates a new HV and iterates all extensions on each invocation.
With the global cache removed and no replacement, every `has_extension_oid` call pays the
full per-extension cost. A caller checking N OIDs on the same certificate triggers N
allocations.

A per-instance cache would fix both issues above:

```perl
sub Crypt::OpenSSL::X509::has_extension_oid {
  my $x509 = shift;
  my $oid  = shift;

  unless (exists $x509->{_exts_by_oid}) {
    eval { $x509->{_exts_by_oid} = $x509->extensions_by_oid };
    $x509->{_exts_by_oid} //= {};
  }

  return $x509->{_exts_by_oid}{$oid} ? 1 : 0;
}
```

### 3. No test coverage for the no-extension cert path

Neither test for `has_extension_oid` uses a cert with zero extensions, so the croak in
item 1 goes undetected by CI. A test using a minimal cert (or mocking
`extensions_by_oid` to croak) should be added alongside the fix for item 1.

---

## Follow-up from CVE-2026-58101 fix

### 4. `extendedKeyUsage` leaks the STACK_OF(ASN1_OBJECT) container

`extendedKeyUsage()` in `X509.xs` (~line 1236) drains the stack with `sk_ASN1_OBJECT_pop`
inside the NULL guard added for CVE-2026-58101, but never calls `sk_ASN1_OBJECT_free()` on
the container after the loop. The elements are popped (and their memory freed by
`sk_ASN1_OBJECT_pop` → `ASN1_OBJECT_free`), but the `STACK_OF` header itself leaks.

Fix: add `sk_ASN1_OBJECT_free(extku);` after the while loop, inside the `if (extku != NULL)`
block.

---

## Follow-up from macOS CI OpenSSL version discussion

### 5. `macos-latest.yml` only tests a single OpenSSL version per run

The workflow currently installs one Homebrew OpenSSL formula (`openssl@3`) and points
`OPENSSL_PREFIX` at it. This matches the pattern used for multi-version testing locally
(`scripts/test.sh`, `OPENSSL4_TESTING.md`), but CI still only exercises one version per
push, unlike the local script which loops over 1.1/3.0/3.5/4.x.

Consider converting the `Run Tests` step to a build matrix so PRs are checked against
multiple OpenSSL versions on macOS, e.g.:

```yaml
strategy:
  fail-fast: false
  matrix:
    openssl: ["openssl@1.1", "openssl@3"]

steps:
  - uses: actions/checkout@v4.2.0
  - name: install dependencies
    run: |
      brew install ${{ matrix.openssl }}
  - name: uses install-with-cpanm
    uses: perl-actions/install-with-cpanm@v1.7
    with:
      cpanfile: "cpanfile"
      args: "--with-configure"
      sudo: false
  - name: perl -V
    run: perl -V
  - name: Run Tests
    run: |
      export OPENSSL_PREFIX="$(brew --prefix ${{ matrix.openssl }})"
      export PKG_CONFIG_PATH="$OPENSSL_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
      export LDFLAGS="-L$OPENSSL_PREFIX/lib"
      export CPPFLAGS="-I$OPENSSL_PREFIX/include"
      export DYLD_LIBRARY_PATH="$OPENSSL_PREFIX/lib:$DYLD_LIBRARY_PATH"
      perl Makefile.PL
      make
      make test
```

Using `brew --prefix` instead of a hardcoded `/opt/homebrew/opt/...` path also avoids
breakage on Intel runners (`/usr/local`) vs Apple Silicon runners (`/opt/homebrew`).
