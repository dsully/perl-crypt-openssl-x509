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
