# NAME

Crypt::OpenSSL::X509 - Perl extension to OpenSSL's X509 API.

# SYNOPSIS

    use Crypt::OpenSSL::X509;

    my $x509 = Crypt::OpenSSL::X509->new_from_file('cert.pem');

    print $x509->pubkey() . "\n";
    print $x509->subject() . "\n";
    print $x509->hash() . "\n";
    print $x509->email() . "\n";
    print $x509->issuer() . "\n";
    print $x509->issuer_hash() . "\n";
    print $x509->notBefore() . "\n";
    print $x509->notAfter() . "\n";
    print $x509->modulus() . "\n";
    print $x509->exponent() . "\n";
    print $x509->fingerprint_md5() . "\n";
    print $x509->fingerprint_sha256() . "\n";
    print $x509->as_string() . "\n";

    my $x509 = Crypt::OpenSSL::X509->new_from_string(
      $der_encoded_data, Crypt::OpenSSL::X509::FORMAT_ASN1
    );

    # given a time offset of $seconds, will the certificate be valid?
    if ($x509->checkend($seconds)) {
      # cert is expired at $seconds offset
    } else {
      # cert is ok at $seconds offset
    }

    my $exts = $x509->extensions_by_oid();

    foreach my $oid (keys %$exts) {
      my $ext = $$exts{$oid};
      print $oid, " ", $ext->object()->name(), ": ", $ext->value(), "\n";
    }

# ABSTRACT

    Crypt::OpenSSL::X509 - Perl extension to OpenSSL's X509 API.

# DESCRIPTION

    This implement a large majority of OpenSSL's useful X509 API.

    The email() method supports both certificates where the
    subject is of the form:
    "... CN=Firstname lastname/emailAddress=user@domain", and also
    certificates where there is a X509v3 Extension of the form
    "X509v3 Subject Alternative Name: email=user@domain".

## EXPORT

None by default.

On request:

        FORMAT_UNDEF FORMAT_ASN1 FORMAT_TEXT FORMAT_PEM
        FORMAT_PKCS12 FORMAT_SMIME FORMAT_ENGINE FORMAT_IISSGC

# FUNCTIONS

## X509 CONSTRUCTORS

- new ( )

    Create a new X509 object.

- new\_from\_string ( STRING \[ FORMAT \] )
- new\_from\_file ( FILENAME \[ FORMAT \] )

    Create a new X509 object from a string or file. `FORMAT` should be `FORMAT_ASN1` or `FORMAT_PEM`.

## X509 ACCESSORS

- subject

    Subject name as a string.

- issuer

    Issuer name as a string.

- issuer\_hash

    Issuer name hash as a string.

- serial

    Serial number as a string.

- hash

    Alias for subject\_hash

- subject\_hash

    Subject name hash as a string.

- notBefore

    `notBefore` time as a string.

- notAfter

    `notAfter` time as a string.

- email

    Email addresses as string, if multiple addresses found, they are separated by a space (' ').

- version

    Certificate version as a string.

- sig\_alg\_name

    Signature algorithm name as a string.

- key\_alg\_name

    Public key algorithm name as a string.

- curve

    Name of the EC curve used in the public key.

## X509 METHODS

- subject\_name ( )
- issuer\_name ( )

    Return a Name object for the subject or issuer name. Methods for handling Name objects are given below.

- is\_selfsigned ( )

    Return Boolean value if subject and issuer name are the same.

- as\_string ( \[ FORMAT \] )

    Return the certificate as a string in the specified format. `FORMAT` can be one of `FORMAT_PEM` (the default) or `FORMAT_ASN1`.

- modulus ( )

    Return the modulus for an RSA public key as a string of hex digits. For DSA and EC return the public key. Other algorithms are not supported.

- bit\_length ( )

    Return the length of the modulus as a number of bits.

- fingerprint\_md5 ( )
- fingerprint\_sha1 ( )
- fingerprint\_sha224 ( )
- fingerprint\_sha256 ( )
- fingerprint\_sha384 ( )
- fingerprint\_sha512 ( )

    Return the specified message digest for the certificate.

- checkend( OFFSET )

    Given an offset in seconds, will the certificate be expired? Returns True if the certificate will be expired. False otherwise.

- pubkey ( )

    Return the RSA, DSA, or EC public key.

- num\_extensions ( )

    Return the number of extensions in the certificate.

- extension ( INDEX )

    Return the Extension specified by the integer `INDEX`.
    Methods for handling Extension objects are given below.

- extensions\_by\_oid ( )
- extensions\_by\_name ( )
- extensions\_by\_long\_name ( )

    Return a hash of Extensions indexed by OID or name.

- has\_extension\_oid ( OID )

    Return true if the certificate has the extension specified by `OID`.

## X509::Extension METHODS

- critical ( )

    Return a value indicating if the extension is critical or not.
    FIXME: the value is an ASN.1 BOOLEAN value.

- object ( )

    Return the ObjectID of the extension.
    Methods for handling ObjectID objects are given below.

- value ( )

    Return the value of the extension as an asn1parse(1) style hex dump.

- as\_string ( )

    Return a human-readable version of the extension as formatted by X509V3\_EXT\_print. Note that this will return an empty string for OIDs with unknown ASN.1 encodings.

## X509::ObjectID METHODS

- name ( )

    Return the long name of the object as a string.

- oid ( )

    Return the numeric dot-separated form of the object identifier as a string.

## X509::Name METHODS

- as\_string ( )

    Return a string representation of the Name

- entries ( )

    Return an array of Name\_Entry objects. Methods for handling Name\_Entry objects are given below.

- has\_entry ( TYPE \[ LASTPOS \] )
- has\_long\_entry ( TYPE \[ LASTPOS \] )
- has\_oid\_entry ( TYPE \[ LASTPOS \] )

    Return true if a name has an entry of the specified `TYPE`. Depending on the function the `TYPE` may be in the short form (e.g. `CN`), long form (`commonName`) or OID (`2.5.4.3`). If `LASTPOS` is specified then the search is made from that index rather than from the start.

- get\_index\_by\_type ( TYPE \[ LASTPOS \] )
- get\_index\_by\_long\_type ( TYPE \[ LASTPOS \] )
- get\_index\_by\_oid\_type ( TYPE \[ LASTPOS \] )

    Return the index of an entry of the specified `TYPE` in a name. Depending on the function the `TYPE` may be in the short form (e.g. `CN`), long form (`commonName`) or OID (`2.5.4.3`). If `LASTPOS` is specified then the search is made from that index rather than from the start.

- get\_entry\_by\_type ( TYPE \[ LASTPOS \] )
- get\_entry\_by\_long\_type ( TYPE \[ LASTPOS \] )

    These methods work similarly to get\_index\_by\_\* but return the Name\_Entry rather than the index.

## X509::Name\_Entry METHODS

- as\_string ( \[ LONG \] )

    Return a string representation of the Name\_Entry of the form `typeName=Value`. If `LONG` is 1, the long form of the type is used.

- type ( \[ LONG \] )

    Return a string representation of the type of the Name\_Entry. If `LONG` is 1, the long form of the type is used.

- value ( )

    Return a string representation of the value of the Name\_Entry.

- is\_printableString ( )
- is\_ia5string ( )
- is\_utf8string ( )
- is\_asn1\_type ( \[ASN1\_TYPE\] )

    Return true if the Name\_Entry value is of the specified type. The value of `ASN1_TYPE` should be as listed in OpenSSL's `asn1.h`.

# SEE ALSO

OpenSSL(1), Crypt::OpenSSL::RSA, Crypt::OpenSSL::Bignum

# AUTHOR

Dan Sully

# CONTRIBUTORS

- Florian Schlichting @fschlich, release 1.9.11
- Timonthy Legge, release 1.9.10
- Patrick Cernko, release 1.9.9
- Shoichi Kaji, release 1.9.3 and 1.9.8
- Neil Bowers, release 1.8.13
- kmx, release 1.8.9
- Sebastian Andrzej Siewior
- David O'Callaghan, <david.ocallaghan@cs.tcd.ie>
- Daniel Kahn Gillmor <dkg@fifthhorseman.net>

# COPYRIGHT AND LICENSE

Copyright 2004-2021 by Dan Sully

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
