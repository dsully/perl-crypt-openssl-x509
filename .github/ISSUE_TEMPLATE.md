# Issue Template

## Description

_If you raise an issue on bug/issue please provide the requested information, where not possible, please provide as many details as possible and ultimately a thorough description of your issue._

_Please file your issue in English, this makes in generally consumable._

_Do note that issue reports are public available information, so please filter out any sensitive or personal information prior to submitting._

### Expected behaviour

_What behaviour did you expect did occur?_

### Actual behaviour

_What unexpected behaviour occurred?_

## Operating system and version

_Please provide version on the operating system etc. used._

### Windows (pre version 7)

`C:\> ver`

### Windows (Version 7 and newer)

`C:\> systeminfo | findstr /B /C:"OS Name" /C:"OS Version"`

### Linux and Unix based systems

`$ uname -a`

_For information on the specific distribution. Please consult your distribution documentation._

## Crypt::OpenSSL::X509 version

_Please provide version on the Crypt::OpenSSL::X509 version used_

_If working in a fork of the GitHub project, obtain this information post installation using:_

```bash
$ perl -I lib -MCrypt::OpenSSL::X509 \
-e 'print "$Crypt::OpenSSL::X509::VERSION\n"'
```

_If you are working on code, which has diverged from the lastest release, please mention this_.

## Perl version

_Please provide version on the Perl version used._

`$ perl -V`

## OpenSSL version

_Please provide version on the OpenSSL version used._

`$ openssl version`

## Output, if available

_Please add output, which can be used to describe the issue or circumstances surrounding the issue._

## Step by step guide to reproducing the issue

_If possible a code snipppet or unit-test to demonstrate the issue or step by step description of how to get reproduce the error._

_If the issue is related to a broken build please provide information on your build environment, like compiler, compiler version, parameters and environment_



