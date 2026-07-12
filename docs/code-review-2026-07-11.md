# Code Review Findings — Branch `fix/CVE-2026-58101-CVE-2026-58102`

**Date:** 2026-07-11
**Effort:** High (8 angles × parallel verify)
**Scope:** `X509.xs` diff against `master` (3 commits: CVE-2026-58102 hv_exts fix, CVE-2026-58101 extension-helper NULL guards, defence-in-depth + extendedKeyUsage leak fix)

**Status:** The findings below were identified during review of earlier snapshots and have since been addressed in later commits on this branch; keep this document as historical review notes rather than a statement of current defects.

---

## CONFIRMED findings

### 1. `bit_string()` leaks `ASN1_BIT_STRING` on every call — X509.xs ~line 1221

`X509V3_EXT_d2i()` returns a caller-owned allocation. The sibling functions `basicC()` and `ia5string()` both free their allocations (`BASIC_CONSTRAINTS_free(bs)`, `ASN1_IA5STRING_free(str)`). The new `if (bit_str != NULL)` block in `bit_string()` uses `bit_str` but has no corresponding `ASN1_BIT_STRING_free(bit_str)`.

**Fix:** add `ASN1_BIT_STRING_free(bit_str);` after the closing brace of the `if (bit_str != NULL)` block, matching the pattern in `ia5string()`.

---

### 2. `extendedKeyUsage()` — `BIO_printf("%s", NULL)` UB on custom EKU OIDs — X509.xs ~line 1272

After `ASN1_OBJECT_free(obj)` the code does:
```c
value = OBJ_nid2sn(nid);
BIO_printf(bio, "%s", value);
```
`OBJ_obj2nid()` returns `NID_undef` for any OID not in OpenSSL's built-in table; `OBJ_nid2sn(NID_undef)` returns `NULL`. A certificate carrying a private or custom extended key usage OID causes `BIO_printf(bio, "%s", NULL)` — undefined behaviour, crash in practice.

**Fix:** guard the printf:
```c
value = OBJ_nid2sn(nid);
if (value != NULL) {
    BIO_printf(bio, "%s ", value);
}
```
Or fall back to a dotted-decimal representation for unrecognised NIDs to preserve them in the output.

---

### 3. `basicC()` croak is undocumented — no caller wraps it in `eval{}` — X509.xs ~line 1159

The new `if (bs == NULL) croak("Error parsing basicConstraints extension\n")` throws a fatal Perl exception for a malformed `basicConstraints` extension. `X509.pm` POD documents no exception from `basicC()`; `t/x509.t` calls it bare without `eval{}`. Any caller processing attacker-supplied certificates will receive an uncaught fatal error rather than a distinguishable false return. This is a silent breaking API change.

**Fix:** document the exception in `X509.pm` POD for `basicC()`. Consider wrapping call sites (or advising callers to do so), consistent with the `eval{}` pattern already used in `subjectaltname()` (X509.pm line 93–96).

---

## PLAUSIBLE findings

### 4. Second `OBJ_obj2txt()` call return value discarded — `strlen()` on uninitialised buffer if it fails — X509.xs ~line 299

The probe call at line 295 is checked for `< 0`. The formatting call at line 299:
```c
OBJ_obj2txt(key, r + 1, X509_EXTENSION_get_object(ext), no_name);
```
is not checked. If it returns `-1` (e.g. internal BIO error or pre-existing OpenSSL error state), `key[]` was `malloc`'d (not `calloc`'d) and contains uninitialised bytes. `strlen(key)` then reads past the `r+1`-byte allocation and the resulting garbage length is passed to `hv_store()`.

**Fix:** capture the return value and croak on failure:
```c
if (OBJ_obj2txt(key, r + 1, X509_EXTENSION_get_object(ext), no_name) < 0) {
    free(key); SvREFCNT_dec(rv);
    croak("OBJ_obj2txt format failed for extension %d\n", i);
}
```

---

### 5. `strlen(ckey)` in `no_name==2` branch has no NULL guard — X509.xs ~line 306

```c
ckey = OBJ_nid2sn(OBJ_obj2nid(X509_EXTENSION_get_object(ext)));
r = strlen(ckey);
```
`OBJ_nid2sn()` returns `NULL` when a NID was registered via `OBJ_create()` with a `NULL` short-name. This line is unchanged in a touched function; `strlen(NULL)` is undefined behaviour. The `r < 0` guard added to the `no_name==0/1` branch in this diff has no equivalent here.

**Fix:**
```c
if (ckey == NULL) croak("OBJ_nid2sn failed for extension %d\n", i);
```

---

### 6. No guard against `r==0` from `OBJ_obj2txt` probe — extension silently stored under empty-string key — X509.xs ~line 296

The guard at line 296 rejects only `r < 0`. If the probe returns `0` (corrupt or empty `ASN1_OBJECT` inside an extension), `malloc(1)` is called, the second `OBJ_obj2txt` call writes only `'\0'`, `strlen` returns `0`, and `hv_store` inserts the extension under key `""`. A second such extension silently overwrites the first. Under `no_name==0` and `no_name==1`, a valid OID always produces a positive length (fallback to dotted-decimal), so the trigger requires a malformed extension object — but the gap is unguarded.

**Fix:** treat `r == 0` as an error alongside `r < 0`:
```c
if (r <= 0) { SvREFCNT_dec(rv); croak("OBJ_obj2txt length query failed for extension %d\n", i); }
```

---

## Refuted / out of scope

| Candidate | Verdict | Reason |
|---|---|---|
| `extendedKeyUsage` reverses EKU order | REFUTED | Pop-based loop pre-existed the patch; order was already LIFO before this diff |
| `extKeyUsage()` — `split(/ /, "")` false positive | REFUTED | Perl's `split(/ /, "")` returns an empty list, not `("")` |
| `ObjectID::name`/`::oid` still use 128-byte fixed buffer | Out of scope | Pre-existing; not introduced by this branch — log as separate TODO |
