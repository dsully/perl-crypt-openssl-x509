# OpenSSL Link-Check Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the six code-review findings on the `prototype/openssl-link-check` branch (PR #138) so the fail-fast OpenSSL link diagnostic is safe, cross-platform, and doesn't hand-edit a generated file.

**Architecture:** Replace the hand-rolled backtick compile/link probe in `maint/Makefile_header.PL` with `ExtUtils::CBuilder` (already a core module, already used transitively by the toolchain this project targets). `ExtUtils::CBuilder` invokes the compiler/linker via list-form `system()` — no shell string interpolation, so guessed flags and `$ENV{OPENSSL_PREFIX}` can never be re-parsed by a shell — and it already knows the right invocation syntax for both GNU-style and MSVC-style (`cl`/`link`) toolchains, which a hand-rolled `-c ... -o` command does not. Its `split_like_shell` method (built on `Text::ParseWords::shellwords`) replaces naive whitespace-splitting so quoted paths with spaces survive. Then discard the direct edit to the generated `Makefile.PL` and regenerate it properly via `dzil build`, per this repo's CLAUDE.md rule.

**Tech Stack:** Perl, `ExtUtils::CBuilder` (core), `ExtUtils::MakeMaker`, `Dist::Zilla` (`dzil build`).

## Global Constraints

- Do not hand-edit `Makefile.PL` — it is Dist::Zilla-generated from `maint/Makefile_header.PL` (`header_file = maint/Makefile_header.PL` in `dist.ini`); only `maint/Makefile_header.PL` may be edited by hand, then regenerate via `dzil build`.
- The check must work across OpenSSL 1.0.x–4.x and across GNU and MSVC-style Perl toolchains (macOS/Homebrew, Windows/Strawberry+chocolatey, Cygwin, MSYS2/MinGW — the CI matrix in `.github/workflows/`).
- No user-influenced string (guessed `INC`/`LIBS`, `$ENV{OPENSSL_PREFIX}`) may be interpolated into a shell string; all compiler/linker invocation must go through list-form execution.
- Preserve existing opt-out: `$ENV{PERL_CRYPT_OPENSSL_X509_SKIP_OPENSSL_CHECK}` must still fully skip the check.
- Preserve the existing diagnostic's intent: on failure, `warn` a clear multi-paragraph explanation (mentioning the OPENSSL_PREFIX workaround and the skip env var) before `die`.

---

### Task 1: Rewrite the trial compile/link check using ExtUtils::CBuilder

**Files:**
- Modify: `maint/Makefile_header.PL:54-135` (the `unless ($ENV{PERL_CRYPT_OPENSSL_X509_SKIP_OPENSSL_CHECK}) { ... }` block, plus the `my $libs` inside it at line 85)

**Interfaces:**
- Consumes: `%args` (`INC`, `LIBS`, `CCFLAGS`, `OPTIMIZE`) already built earlier in this same file (lines 9-52); `$ENV{PERL_CRYPT_OPENSSL_X509_SKIP_OPENSSL_CHECK}`.
- Produces: no new symbols consumed elsewhere — this block only warns/dies or falls through silently. The outer `my $libs = ' -lssl -lcrypto';` (line 4) must remain untouched and must no longer be shadowed by an inner variable of the same name.

- [ ] **Step 1: Replace the check block**

Replace the entire block currently at `maint/Makefile_header.PL:54-135` (from the `# Crypt::OpenSSL::Guess can silently return...` comment down through the closing `}` of the `unless (...)` block) with:

```perl
# Crypt::OpenSSL::Guess can silently return empty or wrong include/lib
# paths (e.g. https://github.com/dsully/perl-crypt-openssl-x509/issues/67),
# which otherwise surfaces only much later as a wall of "undefined
# reference" linker errors with no indication that OpenSSL is the cause.
# Do a throwaway compile+link here so we can fail fast with a clear
# diagnostic instead.
unless ($ENV{PERL_CRYPT_OPENSSL_X509_SKIP_OPENSSL_CHECK}) {
  require ExtUtils::CBuilder;
  require File::Temp;

  my $dir = File::Temp::tempdir(CLEANUP => 1);
  my $src = "$dir/openssl_check.c";

  open my $fh, '>', $src or die "Can't write $src: $!";
  print {$fh} <<'C_SRC';
#include <openssl/x509.h>
#include <openssl/err.h>

int main(void) {
    X509 *x = X509_new();
    if (x) {
        X509_free(x);
    }
    ERR_clear_error();
    return 0;
}
C_SRC
  close $fh;

  my $trial_inc  = $args{INC} || '';
  my $trial_libs = $args{LIBS}[0] || '';

  my $builder = ExtUtils::CBuilder->new(quiet => 1);

  my @extra_compiler_flags = $builder->split_like_shell(
    join ' ', grep { defined && length } $trial_inc, $args{CCFLAGS}, $args{OPTIMIZE}
  );
  my @extra_linker_flags = $builder->split_like_shell($trial_libs);

  my $ok = eval {
    my $obj = $builder->compile(
      source               => $src,
      extra_compiler_flags => \@extra_compiler_flags,
    );
    $builder->link_executable(
      objects            => [$obj],
      extra_linker_flags => \@extra_linker_flags,
    );
    1;
  };
  my $err = $@ || '(no error captured)';

  unless ($ok) {
    warn <<"DIAG";

*** OpenSSL could not be found or linked ***

Crypt::OpenSSL::X509 needs OpenSSL's headers and libraries (libssl /
libcrypto) to build. A trial compile/link against them just failed
(any compiler/linker output should appear above this message):

  $err
Guessed include flags: @{[ $trial_inc  || '(none)' ]}
Guessed library flags: @{[ $trial_libs || '(none)' ]}

This usually means OpenSSL's development headers/libraries are not
installed, or Crypt::OpenSSL::Guess could not find them on this system.

Try:
  * installing your OS's OpenSSL "-dev"/"-devel" package, or
  * setting \$ENV{OPENSSL_PREFIX} to your OpenSSL installation, e.g.:
      OPENSSL_PREFIX=/usr/local/opt/openssl perl Makefile.PL

See https://github.com/dsully/perl-crypt-openssl-x509/issues/67 for
background on this failure mode.

(Set \$ENV{PERL_CRYPT_OPENSSL_X509_SKIP_OPENSSL_CHECK}=1 to skip this
check and proceed anyway.)
DIAG

    die "OpenSSL not found or not linkable - aborting Makefile.PL\n";
  }
}
```

This removes the hand-rolled `qq{$cc -c $inc -o "$obj" "$src"}` / backtick invocation entirely (fixes the shell-injection/quoting finding), lets `ExtUtils::CBuilder` pick correct GNU vs. MSVC compiler/linker syntax (fixes the MSVC finding), folds `CCFLAGS`/`OPTIMIZE` into the trial compile (fixes the missing-flags finding), reuses `ExtUtils::CBuilder` instead of reinventing a compiler probe (fixes the simplification finding), and renames the inner `libs` variable to `$trial_libs` so it no longer shadows the outer `my $libs` at line 4 (fixes the shadowing finding).

- [ ] **Step 2: Syntax-check the file**

Run: `perl -c maint/Makefile_header.PL`
Expected: `maint/Makefile_header.PL syntax OK` (the file has no `package`/`use strict` of its own — it's spliced into `Makefile.PL` — so this just confirms no stray syntax errors; ignore warnings about barewords if any appear, since this file relies on lexicals from the surrounding splice context).

- [ ] **Step 3: Confirm the happy path still works**

Run: `carton exec perl Makefile.PL 2>&1 | tail -30`
Expected: Makefile.PL completes normally (prints the usual MakeMaker "Writing Makefile for ..." line), no `*** OpenSSL could not be found or linked ***` warning, no die. This proves the trial compile/link succeeds against the real local OpenSSL.

- [ ] **Step 4: Confirm the skip env var still works**

Run: `PERL_CRYPT_OPENSSL_X509_SKIP_OPENSSL_CHECK=1 carton exec perl Makefile.PL 2>&1 | tail -10`
Expected: completes normally with no attempt at the trial compile (no compiler invocation visible even with `quiet => 1` off — behavior is unchanged from before this task since the `unless (...)` guard is untouched).

- [ ] **Step 5: Confirm the failure path still produces the diagnostic**

Run: `PERL_CRYPT_OPENSSL_X509_SKIP_OPENSSL_CHECK=0 OPENSSL_PREFIX=/nonexistent/openssl-prefix carton exec perl Makefile.PL 2>&1 | tail -40`

(If `Crypt::OpenSSL::Guess` ignores `OPENSSL_PREFIX` and still finds the real system OpenSSL on this machine, instead temporarily rename `/usr/local/opt/openssl` or override by exporting `PATH` without the OpenSSL toolchain — whatever locally forces `openssl_lib_paths()`/`openssl_inc_paths()` to return nothing usable. The goal is just to force the trial compile/link to fail.)

Expected: the `*** OpenSSL could not be found or linked ***` warning prints with the `$err` line populated (not empty, not "(no error captured)" unless eval genuinely didn't set `$@`), followed by `OpenSSL not found or not linkable - aborting Makefile.PL` and a non-zero exit. Confirms `$@` from the `eval` around `compile`/`link_executable` is actually being captured and shown.

- [ ] **Step 6: Verify no shell metacharacters get executed**

Run: `OPENSSL_PREFIX='/tmp/x`touch /tmp/PWNED`' carton exec perl Makefile.PL 2>&1 | tail -20; ls /tmp/PWNED 2>&1`
Expected: `perl Makefile.PL` fails with the normal "OpenSSL not found" diagnostic (since `/tmp/x\`touch /tmp/PWNED\`` isn't a real OpenSSL prefix), and `ls /tmp/PWNED` reports "No such file or directory" — proving the backtick metacharacter in the env var was never handed to a shell. Clean up with `rm -f /tmp/PWNED` if it does appear (which would indicate the fix failed).

- [ ] **Step 7: Commit**

```bash
git add maint/Makefile_header.PL
git commit -m "Rebuild the OpenSSL link-check on ExtUtils::CBuilder for safety and portability"
```

---

### Task 2: Regenerate Makefile.PL instead of hand-editing it

**Files:**
- Modify: `Makefile.PL` (fully regenerated, not hand-edited)

**Interfaces:**
- Consumes: `maint/Makefile_header.PL` (fixed in Task 1) via `dist.ini`'s `header_file = maint/Makefile_header.PL`.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Revert the direct hand-edit to Makefile.PL**

Run: `git diff master...HEAD -- Makefile.PL` to see the full hand-applied diff, then:

```bash
git checkout master -- Makefile.PL
```

This restores `Makefile.PL` to its pre-branch (master) generated state so it can be regenerated cleanly rather than patched twice.

- [ ] **Step 2: Regenerate via dzil build**

Run:
```bash
carton exec dzil build --in /tmp/x509-dzil-build
```
Expected: build succeeds and produces `/tmp/x509-dzil-build/Makefile.PL` containing the Task 1 changes (verify with `diff maint/Makefile_header.PL <(sed -n '/^my \$libs/,/^unless/p' /tmp/x509-dzil-build/Makefile.PL)` or simply `grep -n "ExtUtils::CBuilder" /tmp/x509-dzil-build/Makefile.PL` to confirm the new check is present).

- [ ] **Step 3: Copy the regenerated Makefile.PL back**

```bash
cp /tmp/x509-dzil-build/Makefile.PL Makefile.PL
rm -rf /tmp/x509-dzil-build
```

- [ ] **Step 4: Diff-review the result**

Run: `git diff Makefile.PL`
Expected: the diff shows only the same logical change as `maint/Makefile_header.PL` (the ExtUtils::CBuilder rewrite), spliced into the generated boilerplate — no unrelated changes (version strings, other generated sections) should differ from what was already on this branch, other than what naturally flows from a fresh `dzil build` (e.g. a regenerated timestamp/version comment, if `dist.ini` produces one — check for and accept only build-metadata churn).

- [ ] **Step 5: Confirm the regenerated Makefile.PL actually works**

Run: `carton exec perl Makefile.PL 2>&1 | tail -10 && carton exec make test 2>&1 | tail -30`
Expected: Makefile.PL succeeds, `make test` passes (same as before these changes — this task must not change runtime behavior, only how the file was produced).

- [ ] **Step 6: Commit**

```bash
git add Makefile.PL
git commit -m "Regenerate Makefile.PL via dzil build instead of hand-editing it"
```

---

### Task 3: Final full verification

**Files:** none (verification only)

**Interfaces:**
- Consumes: everything from Task 1 and Task 2.
- Produces: nothing.

- [ ] **Step 1: Run the full test suite**

Run: `AUTHOR_TESTING=1 carton exec make test 2>&1 | tail -50`
Expected: all tests pass, including `Test::Pod` checks (POD in `X509.pm` documenting this feature, added in the `Document the OpenSSL link-check diagnostic in POD` commit, is untouched by this plan).

- [ ] **Step 2: Re-confirm CLAUDE.md compliance**

Run: `git diff master...HEAD --stat`
Expected: `Makefile.PL` and `maint/Makefile_header.PL` differ only in the ExtUtils::CBuilder rewrite (logically identical change in both, one hand-written and one regenerated); no other files were touched by this plan beyond what Task 1/2 describe.

- [ ] **Step 3: Push and update PR #138**

```bash
git push origin prototype/openssl-link-check
```

Expected: PR #138 updates with the three new commits; leave a PR comment (or let the diff speak for itself) summarizing that this addresses the six review findings from the earlier `/code-review 138` pass (shell-injection risk, MSVC incompatibility, missing CCFLAGS/OPTIMIZE, generated-file hand-edit, ExtUtils::CBuilder reuse, variable shadowing).
