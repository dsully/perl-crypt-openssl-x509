# Revision history for Perl extension Crypt::OpenSSL::X509

## 2.1.3 2026-07-12

- Fixed CVE-2026-58102: heap out-of-bounds read in `hv_exts()`. The function allocated a fixed 128-byte buffer for an extension's OID string but used `OBJ_obj2txt()`'s return value (the full required length, not the number of bytes actually written) as the key length passed to `hv_store()`. A certificate with an extension whose OID stringifies to more than 128 bytes caused a heap over-read. Fixed with a two-phase `OBJ_obj2txt()` call (probe the required length, allocate exactly, then format) and by using `strlen(key)` rather than the `OBJ_obj2txt()` return value for the `hv_store()` key length. This is a **security fix; update is strongly recommended**

- Fixed CVE-2026-58101: NULL-pointer dereference in several `Crypt::OpenSSL::X509::Extension` helpers. `X509V3_EXT_d2i()` returns `NULL` when an extension's DER payload fails to parse, and the `AUTHORITY_KEYID` `keyid` field is legitimately `NULL` for Authority Key Identifiers that carry only issuer/serial. `basicC()`, `ia5string()`, `auth_att()`, and `keyid_data()` dereferenced these values unconditionally, allowing an attacker-supplied certificate to crash any process that parsed it. All four helpers now guard against `NULL`; `basicC()` croaks on unparseable DER (since it feeds a CA/pathLen security decision), the others fall back to safe empty values. This is a **security fix; update is strongly recommended**

- Hardened `bit_string()` and `extendedKeyUsage()` with the same defence-in-depth `NULL` guards as the CVE-2026-58101 fix, for consistency across all extension helpers, even though the underlying OpenSSL calls were already `NULL`-tolerant

- Fixed several memory leaks and undefined-behaviour issues found during review of the above fixes: `auth_att()` no longer leaks the `AUTHORITY_KEYID` on every call; `extendedKeyUsage()` no longer leaks the popped `ASN1_OBJECT`s or the `STACK_OF(ASN1_OBJECT)` container, and now guards `OBJ_nid2sn()`'s result (which can be `NULL` for unregistered NIDs) before passing it to `BIO_printf()`'s `%s` format; `bit_string()` no longer leaks the `ASN1_BIT_STRING` returned by `X509V3_EXT_d2i()`; `hv_exts()` now rejects empty OIDs and checks the return value of its second `OBJ_obj2txt()` call rather than assuming success

- Documented `basicC()`, `ia5string()`, `bit_string()`, `auth_att()`, `keyid_data()`, and `extendedKeyUsage()` in the `Crypt::OpenSSL::X509::Extension` POD, explicitly noting that `basicC()` throws on malformed DER so callers should wrap it in `eval {}`

## 2.1.2 2026-06-25

- Applied PR [#128](https://github.com/dsully/perl-crypt-openssl-x509/pull/128) from @maxbes (Maxime Besson) fixing `has_extension_oid` returning incorrect results when multiple certificates are instantiated in a single Perl process. The previous implementation stored the extension cache in a package variable, causing it to be shared across all certificate objects. The cache is now held per-instance, so each certificate object maintains its own independent extension list. This is a **bug fix release; update is recommended**. Contributed by @maxbes

## 2.1.1 2026-06-03

- Applied PR [#126](https://github.com/dsully/perl-crypt-openssl-x509/pull/126) moving `-DOPENSSL_API_COMPAT` from `OPTIMIZE` to `CCFLAGS`. Previously, users could override `OPTIMIZE` (e.g., `perl Makefile.PL OPTIMIZE='-Wdiscarded-qualifiers'`), which silently dropped the `-DOPENSSL_API_COMPAT` define and caused OpenSSL 3.0 deprecation warnings. Now placed in `CCFLAGS` (appended to existing ccflags) to ensure it is always applied regardless of user `OPTIMIZE` settings. Closes issue [#123](https://github.com/dsully/perl-crypt-openssl-x509/issues/123). Contributed by @jonasbn with co-authoring from Claude

- Applied PR [#125](https://github.com/dsully/perl-crypt-openssl-x509/pull/125) fixing const-correctness warnings reported by @ppisar in follow-up feedback on issue [#123](https://github.com/dsully/perl-crypt-openssl-x509/issues/123). OpenSSL 1.1.0+ returns const-qualified pointers from several accessor functions; added explicit casts at read-only call sites to resolve `-Wdiscarded-qualifiers` and `-Wincompatible-pointer-types-discards-qualifiers` warnings. Affected functions: `X509_get_ext()`, `X509_get_subject_name()`, `X509_get_issuer_name()`, `X509_get_X509_PUBKEY()`, `X509_EXTENSION_get_object()`, `X509_CRL_get_issuer()`, `X509_NAME_get_entry()`. Contributed by @jonasbn with co-authoring from Claude

- Improved OpenSSL version detection in tests when `OPENSSL_PREFIX` is set. Test suite now reports the version of the OpenSSL library actually being tested (as specified by `scripts/test.sh`) rather than the default PATH binary. Also added warning when `OPENSSL_PREFIX` points to a missing or non-executable binary to avoid silent failures. Contributed by @jonasbn with co-authoring from Claude

- Applied PR [#124](https://github.com/dsully/perl-crypt-openssl-x509/pull/124) adding OpenSSL 4.0 compatibility, addressing issue [#123](https://github.com/dsully/perl-crypt-openssl-x509/issues/123). OpenSSL 4.0.0 made `ASN1_STRING` types opaque, breaking direct struct member access. Conditional compilation (`OPENSSL_VERSION_NUMBER >= 0x40000000L`) now uses accessor functions (`ASN1_STRING_length()`, `ASN1_STRING_get0_data()`, `ASN1_STRING_type()`) for OpenSSL 4.x while maintaining backward compatibility with earlier versions. Fixed functions: `sig_print()`, `ia5string()`, `keyid_data()`, `is_asn1_type()`, `encoding()`. Also fixed a buffer over-read and memory leaks in `ia5string()` and `keyid_data()`. Added `OPENSSL4_TESTING.md` with build and test instructions and `scripts/test.sh` for testing against multiple OpenSSL versions. Contributed by @jonasbn with co-authoring from Copilot and Claude

- Applied PR [#122](https://github.com/dsully/perl-crypt-openssl-x509/pull/122) improving documentation for the `subjectaltname` method, addressing issue [#92](https://github.com/dsully/perl-crypt-openssl-x509/issues/92). All eight `GeneralName` types defined in the embedded ASN.1 schema are now listed with type annotations; notes that `otherName` (tag `[0]` per RFC 5280) is not implemented. Contributed by @jonasbn

## 2.0.1 2024-08-09

- Trimming the distribution tarball, removing files not needed for the distribution, see issue [#120](https://github.com/dsully/perl-crypt-openssl-x509/issues/120) reported by @gregoa. Addressed via PR [#121](https://github.com/dsully/perl-crypt-openssl-x509/pull/121) by @jonasbn

## 2.0.0 2024-07-03

- Applied PR [#119](https://github.com/dsully/perl-crypt-openssl-x509/pull/119) from @timlegge improving detection of OpenSSL libraries under if not installed in standard locations

- I am changing the versioning scheme to be more in line with the [Semantic Versioning](https://semver.org/) specification. I am bumping the major version number to 2, since the version number change might cause problems. See:
  [perlhacks: Bumping Version Numbers](https://perlhacks.com/2016/12/version-numbers/)

## 1.9.15 2023-06-16

- Applied patch for issue [#112](https://github.com/dsully/perl-crypt-openssl-x509/issues/112) from @dakkar, via PR [#113](https://github.com/dsully/perl-crypt-openssl-x509/pull/113) by @jonasbn

## 1.9.14 2022-05-03

- Applied PR [#109](https://github.com/dsully/perl-crypt-openssl-x509/pull/108) from @ikedas fixing a bug found in 1.9.14-TRIAL, where the wrong API was called, propably due to a typo in the name

- Applied PR [#108](https://github.com/dsully/perl-crypt-openssl-x509/pull/108) from @skaji a bug found in 1.9.14-TRIAL, where a possible interpolatation was probibited due to quoting

- Applied patch from @ikedas PR [#105](https://github.com/dsully/perl-crypt-openssl-x509/pull/105) make the pattern match for LLVM version number in the 12 series a bit more liberal. This was followed up by PR [#107](https://github.com/dsully/perl-crypt-openssl-x509/pull/107) by @jonasbn

- Applied patch from @timlegge PR [#102](https://github.com/dsully/perl-crypt-openssl-x509/pull/102) adressing issues: [#45](https://github.com/dsully/perl-crypt-openssl-x509/issues/45) and [#95](https://github.com/dsully/perl-crypt-openssl-x509/issues/95) with only a more strict use of compiler flags if environment variable `AUTHOR_TESTING` is set to true

- Added enhancement from @michal-josef-spacek introducing use of [Crypt::OpenSSL::Guess](https://metacpan.org/pod/Crypt::OpenSSL::Guess), which can be used to determine placement of OpenSSL libraries via PR [#104](https://github.com/dsully/perl-crypt-openssl-x509/pull/104). The idea originates from issue [#97](https://github.com/dsully/perl-crypt-openssl-x509/issues/97) raised by @ikedas and addresses: [#94](https://github.com/dsully/perl-crypt-openssl-x509/issues/94) also from @ikedas

- The above was followed up by a PR from @jonasbn [#106](https://github.com/dsully/perl-crypt-openssl-x509/pull/106) enabling installation of `configure` section for CI jobs for both `cpanm` and `cpm`

- Metadata on bug tracker was updated with release 1.9.13, documentation updated with this release. Addressing issue [#80](https://github.com/dsully/perl-crypt-openssl-x509/issues/80) raised by @skaji, update by @jonasbn

- Patch from @timlegge via PR [#103](https://github.com/dsully/perl-crypt-openssl-x509/pull/103) improving handling of OpenSSL API versions

- Patch from @skaji via PR [#100](https://github.com/dsully/perl-crypt-openssl-x509/pull/100) making use of constants in XS code

## 1.9.14-TRIAL 2022-04-26

- Release leading up to 1.9.14, see that release for details

- This is a TRIAL release, in order to get some feedback from CPAN-testers prior to making a proper public release, since the release contains a significant number of changes. Additional trial releases might follow, based on findings and feedback

## 1.9.13 2022-02-26

- The distribution has changed distribution toolchain from Module::Install to Dist::Zilla, thanks to @skaji for PR [#96](https://github.com/dsully/perl-crypt-openssl-x509/pull/96) and thanks to @timlegge for the review of the proposed changes

- The macOS CI jobs have been improved with PRs [#98](https://github.com/dsully/perl-crypt-openssl-x509/pull/98) and [#99](https://github.com/dsully/perl-crypt-openssl-x509/pull/99) from @timlegge

## 1.9.13-TRIAL 2022-02-20

- Release leading up to 1.9.13, see that release for details

- This is a TRIAL release, in order to get some feedback from CPAN-testers prior to making a proper public release, since the changes to the build system has been quite significant. Additional trial releases might follow, based on findings and feedback

## 1.9.12 2022-01-19

- Repair upload, see release 1.9.11, thank you @timlegge for reporting this

> PAUSE doesn't let you upload a file twice.

## 1.9.11 2022-01-18

- Applied patch from @jrouzierinverse PR [#93](https://github.com/dsully/perl-crypt-openssl-x509/pull/93) addressing issue [#66](https://github.com/dsully/perl-crypt-openssl-x509/issues/66)

- Applied patch from @timlegge PR [#92](https://github.com/dsully/perl-crypt-openssl-x509/pull/92) addressing issues [#50](https://github.com/dsully/perl-crypt-openssl-x509/issues/50) and [#40](https://github.com/dsully/perl-crypt-openssl-x509/issues/40)

- Correction to spelling found Debian Linter, thanks @fschlich PR [#90](https://github.com/dsully/perl-crypt-openssl-x509/pull/90)

- Added eliminated compound-token-split-by-macro errors coming from newer clang/LLVM version (>11?), got some good pointers from this [Perl issue](https://github.com/Perl/perl5/issues/18780)

- Forced OpenSSL under Homebrew to 1.1 via `openssl\@1.1`, since OpenSSL version 3 got released we might experience issues and this need to be revisited and tested thoroughly

- Reformatted the Changes file, slowly converting to Markdown

## 1.9.10 2021-08-01

- MANIFEST was not updated with the latest contributions from 1.9.9, see issue [#89](https://github.com/dsully/perl-crypt-openssl-x509/issues/89)

## 1.9.9 2021-07-31

- Contribution by Patrick Cernko. The email method has been extended to return multiple email addresses if available.
  The addresses are concatenated using space (' ') as seperator in order for consumers to extract the multiple email addresses, see PR [#88](https://github.com/dsully/perl-crypt-openssl-x509/pull/88)

## 1.9.8 2021-05-13

- Addressed minor issue, via PR [#87](https://github.com/dsully/perl-crypt-openssl-x509/pull/87), with the implementation added in 1.9.3 - Thanks Shoichi Kaji

## 1.9.7 2021-05-02

- Addressed minor issue with META.yml file not reporting correct version, see issue [#86](https://github.com/dsully/perl-crypt-openssl-x509/issues/86)

## 1.9.6 2021-04-24

- I fell over this [CPAN release checklist](https://github.com/Tux/Release-Checklist/blob/master/Checklist.md), it mentions
  [Devel::PPPort](https://metacpan.org/pod/Devel::PPPort). I have now put this to use, raised a single warning

  ```text
  *** WARNING: Uses is_utf8_string_loclen, which may not be portable below perl 5.9.3, even with 'ppport.h'
  *** Uses 5 C++ style comments, which is not portable
  Analysis completed (1 warning)
  ```

  And provided as single patch, which has now been applied and C++ style comments have been changed to C style comments

## 1.9.5 2021-04-22

- I broke the build for Linux

  - [CPAN testers reports](http://matrix.cpantesters.org/?dist=Crypt-OpenSSL-X509+1.904)

    The issue is that the change introduced in 1.9.4 introduces an option, which is LLVM specific
    and is not understood by GCC.

    See also issue: [#84](https://github.com/dsully/perl-crypt-openssl-x509/issues/84)

    I have rearranged the use of flags and try with a match on the GCC version string, which
    can contain the substring LLVM

## 1.9.4 2021-04-21

- Made a minor change to the Makefile.PL addressing issue with breaking builds on FreeBSD and OpenBSD

  For Perl versions below or equal to 5.20, the error:

  ```text
  error: nonnull parameter 'pv' will evaluate to 'true' on first encounter [-Werror,-Wpointer-bool-conversion]
  if (pv && len > 1) {
  ```

  Has been observed this is now suppressed with converting the error handling into a warning

  See CPAN testers reports: [1](http://www.cpantesters.org/cpan/report/119b4298-9e42-11eb-84bc-edd243e66a77), [2](http://www.cpantesters.org/cpan/report/77bdcdd2-a0e7-11eb-84bc-edd243e66a77) and [3](http://www.cpantesters.org/cpan/report/fd7e66b6-a14b-11eb-84bc-edd243e66a77)

## 1.9.3 2021-04-08

- Addressed issue [#81](https://github.com/dsully/perl-crypt-openssl-x509/issues/81) based on proposed patch from Shoichi Kaji

## 1.9.2 2020-11-12

- Addressed issue [#84](https://github.com/dsully/perl-crypt-openssl-x509/issues/84) via PR [#73](https://github.com/dsully/perl-crypt-openssl-x509/pull/73) removing and excess use of free

## 1.9.1 2020-11-06

- Corrected version number format to address issue [#77](https://github.com/dsully/perl-crypt-openssl-x509/issues/77) via PR [#78](https://github.com/dsully/perl-crypt-openssl-x509/pull/78)

## 1.9 2020-11-05

- Bumped Perl minimum requirement from Perl 5.005 to 5.8 PR [#76](https://github.com/dsully/perl-crypt-openssl-x509/pull/76)

- Changed from use vars definition to the more modern our PR: [#75](https://github.com/dsully/perl-crypt-openssl-x509/pull/75) Thanks to Todd Rinaldo

- Changed from DynaLoader to XSLoader PR: [#75](https://github.com/dsully/perl-crypt-openssl-x509/pull/75) Thanks to Todd Rinaldo

## 1.8.13 2019-10-24

- Ensure `/usr/local` is ahead of `/usr` in include and lib searches, PR: [#74](https://github.com/dsully/perl-crypt-openssl-x509/pull/74)

## 1.8.12 2018-11-22

- Applied patch from @eserte addressing issue (#71) with [current directory no longer included in `@INC` by default from Perl 5.26](https://www.effectiveperlprogramming.com/2017/01/v5-26-removes-dot-from-inc/)

## 1.8.11 2018-10-28

- Re-release of 1.8.10, with corrected version number, indexer error from PAUSE

## 1.8.10 2018-10-28

- Maintenance release, corrected [issue with `MYMETA.*` files included in distribution](https://weblog.bulknews.net/stop-shipping-mymeta-to-cpan-b92215a227f6)

## 1.8.9 2017-05-30

- Patch / PR from kmx improving detection of OpenSSL libraries under strawberry Perl

## 1.8.8 2017-11-10

- Patch from pi-rho exposing the Issuer's name hash; provide `subject_hash()` as an alias to `hash()`

- Patch from stphnlyd `X509_get0_signature()` was introduced to [OpenSSL](https://www.openssl.org/docs/man1.1.0/crypto/X509_get0_signature.html) since 1.0.2.

- Patch from brandond fixing compilation on OpenSSL 1.0.1e

- Patch to support compilation on MacOS Homebrew installed libraries by jonasbn

- Patch from ppisar, patch redefines the accessors only with OpenSSL older than 1.1.0

- Patch from Sebastian Andrzej Siewior fixing compilation against openssl 1.1.0 and keeping it working against openssl 1.0.2j

- Patch from jonasbn reinitializing `inc/` using Module::Install 1.16, fixed issue with `META.ym` version since `META.yml` was not regenerated

## 1.8.7 2016-05-12

- Patch from Bernhard M. Wiedemann to fix compilation errors

## 1.8.6 2015-01-24

- Patch from James Hunt to print OpenSSL version during tests

- Various `MANIFEST` fixes

## 1.8.5 2014-11-22

- Patch from Uli Scholler to expose more SHA1 hash functions

## 1.8.4 2013-12-01

- Fix Github Issues [#16](https://github.com/dsully/perl-crypt-openssl-x509/issues/16) , [#29](https://github.com/dsully/perl-crypt-openssl-x509/issues/29) & [#30](https://github.com/dsully/perl-crypt-openssl-x509/issues/30)

- Possibly fix issue [#31](https://github.com/dsully/perl-crypt-openssl-x509/issues/31)

## 1.8.3 2013-08-12

- Fix Github Issues [#2](https://github.com/dsully/perl-crypt-openssl-x509/issues/2), [#10](https://github.com/dsully/perl-crypt-openssl-x509/issues/10), [#15](https://github.com/dsully/perl-crypt-openssl-x509/issues/15) , [#17](https://github.com/dsully/perl-crypt-openssl-x509/issues/17), [#22](https://github.com/dsully/perl-crypt-openssl-x509/issues/22), [#23](https://github.com/dsully/perl-crypt-openssl-x509/issues/23), [#24](https://github.com/dsully/perl-crypt-openssl-x509/issues/24) & [#25](https://github.com/dsully/perl-crypt-openssl-x509/issues/25)

## 1.8.2 2011-05-07

- Fix warnings under gcc 4.6

## 1.8.1 2011-04-17

- Fix OpenSSL version check.

## 1.8 2011-04-13

- Bump version to deal with CPAN/Perl versioning madness.

## 1.7.1 2011-04-05

- Fix compile issue on i386, etc.

## 1.7 2011-03-29

- Updates from David O'Callaghan to add pubkey, encoding & CRL functions.

## 1.6 2011-01-05

- Fix from Nicholas Harteau for -Wall error. Exhibited by `-O2`
- Update home page & bug tracker.

## 1.5 2010-12-24

- Fix call to utf_loclen to be compatible with CentOS Perl. (CPAN RT #62339)

- Update Module::Install

## 1.4 2010-08-31

- Fix `new_from_string()?

## 1.3 2010-08-06

- Fix `fingerprint_sha1()`

## 1.2 2010-05-31

- Compatible with OpenSSL v1.0.0

- Incompatible change: Removed fingerprint_md2 method

- Fix leaked memory on module END

## 1.1 2010-05-21

- Fix memory leak in sv_bio_final() (CPAN RT #57719)

## 1.0 2010-01-18

- Remove pub_exponent() and alias it to exponent().

## 0.9 2010-01-18

- Patches from David O'Callaghan to access X509 extensions & documenation.

- Patch from Otmar Lendl to allow UTF-8 chars in certificate names.

- Patches from Louise Doran via David O'Callaghan.

- Patch from Daniel Kahn Gillmor adding more examples in the POD SYNOPSIS

- Patch from Daniel Kahn Gillmor adding the exponent() method.

## 0.8 2008-11-08

- Fix error message

## 0.7 2008-05-17

- Stop cpansmoke if libcrypto isn't installed.

## 0.6 2008-02-23

- RT #28684: Failed test 'use Crypt::OpenSSL::X509;'

## 0.5 2007-06-02

- Fix manifest.

## 0.4 2007-01-03

- RT #13861 - patch from dsteinwand@citysearch.com

- RT #8778  - Fix flags for `X509_NAME_print_ex()`

## 0.3.1 2004-11-22

- Patch from Daniel Risacher to add an `email()` method & doc additions

- Remove newline from hash() accessor

## 0.3 2004-10-04

- Patch from Otmar Lendl to remove `NULL` on fingerprint

## 0.2 2004-01-30

- Handle ASN1/DER input

- Additional headers and cleanup

## 0.1   2004-01-29

- Initial release

- Interoperates with Crypt::OpenSSL::Bignum & Crypt::OpenSSL::RSA

## 0.01 2004-01-28

- original version; created by h2xs 1.22 with options
  `-O -b 5.5.3 -a -k --skip-ppport --skip-warnings -c -n Crypt::OpenSSL::X509`
