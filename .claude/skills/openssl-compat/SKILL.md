---
name: openssl-compat
description: Check if an OpenSSL C API function requires version guards in X509.xs, and suggest the correct #if block
---

Given an OpenSSL function name (passed as the argument), do the following:

1. Search X509.xs for any existing use of or guard around that function:
   ```bash
   grep -n "<function_name>" X509.xs
   grep -n "OPENSSL_VERSION_NUMBER" X509.xs
   ```

2. Determine which OpenSSL version introduced or deprecated the function:
   - Functions introduced in OpenSSL 1.1.0 need: `#if OPENSSL_VERSION_NUMBER >= 0x10100000L`
   - Functions deprecated/removed in OpenSSL 1.1.0 need: `#if OPENSSL_VERSION_NUMBER < 0x10100000L`
   - Functions introduced in OpenSSL 3.0 need: `#if OPENSSL_VERSION_NUMBER >= 0x30000000L`
   - Functions introduced in OpenSSL 4.0 need: `#if OPENSSL_VERSION_NUMBER >= 0x40000000L`

3. Check the existing guard pattern in X509.xs (around line 40–80) and match its coding style.

4. Output:
   - Whether the function already has a guard in X509.xs
   - The correct `#if OPENSSL_VERSION_NUMBER` threshold
   - A ready-to-use C preprocessor block in the style of existing guards in X509.xs
   - The OpenSSL changelog version where the function was introduced/changed

Key version hex constants used in this codebase:
- `0x10000000L` = OpenSSL 1.0.0
- `0x10100000L` = OpenSSL 1.1.0
- `0x30000000L` = OpenSSL 3.0.0
- `0x40000000L` = OpenSSL 4.0.0
