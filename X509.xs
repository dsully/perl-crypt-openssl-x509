#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <openssl/asn1.h>
#include <openssl/bio.h>
#include <openssl/crypto.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>

/* from openssl/apps/apps.h */
#define FORMAT_UNDEF    0
#define FORMAT_ASN1     1
#define FORMAT_TEXT     2
#define FORMAT_PEM      3
#define FORMAT_NETSCAPE 4
#define FORMAT_PKCS12   5
#define FORMAT_SMIME    6
#define FORMAT_ENGINE   7
#define FORMAT_IISSGC   8

#define NETSCAPE_CERT_HDR "certificate"

/* fake our package name */
typedef X509*	Crypt__OpenSSL__X509;

/* stolen from OpenSSL.xs */
long bio_write_cb(struct bio_st *bm, int m, const char *ptr, int l, long x, long y) {

        if (m == BIO_CB_WRITE) {
                SV *sv = (SV *) BIO_get_callback_arg(bm);
                sv_catpvn(sv, ptr, l);
        }

        if (m == BIO_CB_PUTS) {
                SV *sv = (SV *) BIO_get_callback_arg(bm);
                l = strlen(ptr);
                sv_catpvn(sv, ptr, l);
        }

        return l;
}

static BIO* sv_bio_create(void) {

        SV *sv = newSVpvn("",0);

	/* create an in-memory BIO abstraction and callbacks */
        BIO *bio = BIO_new(BIO_s_mem());

        BIO_set_callback(bio, bio_write_cb);
        BIO_set_callback_arg(bio, (void *)sv);

        return bio;
}

static SV* sv_bio_final(BIO *bio) {

	SV* sv;

	BIO_flush(bio);
	sv = (SV *)BIO_get_callback_arg(bio);
	BIO_free_all(bio);

	if (!sv) {
		sv = &PL_sv_undef;
	}

	return sv;
}

/*
static void sv_bio_error(BIO *bio) {

	SV* sv = (SV *)BIO_get_callback_arg(bio);
	if (sv) sv_free(sv);

	BIO_free_all (bio);
}
*/

static const char *ssl_error(void) {
	BIO *bio;
	SV *sv;
	STRLEN l;

	bio = sv_bio_create();
	ERR_print_errors(bio);
	sv = sv_bio_final(bio);
	ERR_clear_error();
	return SvPV(sv, l);
}

MODULE = Crypt::OpenSSL::X509		PACKAGE = Crypt::OpenSSL::X509		

PROTOTYPES: DISABLE

BOOT:
{
	OpenSSL_add_all_algorithms();
        OpenSSL_add_all_ciphers();
        OpenSSL_add_all_digests();
	ERR_load_PEM_strings();
        ERR_load_ASN1_strings();
        ERR_load_crypto_strings();
        ERR_load_X509_strings();
        ERR_load_DSA_strings();
        ERR_load_RSA_strings();

	HV *stash = gv_stashpvn("Crypt::OpenSSL::X509", 20, TRUE);

	struct { char *n; I32 v; } Crypt__OpenSSL__X509__const[] = {

	{"FORMAT_UNDEF", FORMAT_UNDEF},
	{"FORMAT_ASN1", FORMAT_ASN1},
	{"FORMAT_TEXT", FORMAT_TEXT},
	{"FORMAT_PEM", FORMAT_PEM},
	{"FORMAT_NETSCAPE", FORMAT_NETSCAPE},
	{"FORMAT_PKCS12", FORMAT_PKCS12},
	{"FORMAT_SMIME", FORMAT_SMIME},
	{"FORMAT_ENGINE", FORMAT_ENGINE},
	{"FORMAT_IISSGC", FORMAT_IISSGC},
	{Nullch,0}};

	char *name;
	int i;

	for (i = 0; (name = Crypt__OpenSSL__X509__const[i].n); i++) {
		newCONSTSUB(stash, name, newSViv(Crypt__OpenSSL__X509__const[i].v));
	}
}

Crypt::OpenSSL::X509
new(class)
	SV	*class

	CODE:

  	if ((RETVAL = X509_new()) == NULL) {
		croak("X509_new");
	}

        if (!X509_set_version(RETVAL, 2)) {
		X509_free(RETVAL);
		croak ("%s - can't X509_set_version()", class);
	}

	ASN1_INTEGER_set(X509_get_serialNumber(RETVAL), 0L);

	OUTPUT:
        RETVAL

Crypt::OpenSSL::X509
new_from_string(class, string, format = FORMAT_PEM)
	SV	*class
        SV	*string
        int	format

	ALIAS:
   	new_from_file = 1     

	PREINIT:
	BIO *bio;
	STRLEN len;
	char *cert;

	CODE:

	cert = SvPV(string, len);

        if (ix == 1) {
		bio = BIO_new_file(cert, "r");
        } else {
		bio = BIO_new_mem_buf(cert, len);
	}

	if (!bio) croak("%s: Failed to create BIO", class);

	/* this can come in any number of ways */
	if (format == FORMAT_ASN1) {

                RETVAL = (X509*)d2i_X509_bio(bio, NULL);

        } else {

        	RETVAL = (X509*)PEM_read_bio_X509(bio, NULL, NULL, NULL);
        }

	if (!RETVAL) croak("%s: failed to read X509 certificate.", class);

        BIO_free(bio);

	OUTPUT:
	RETVAL

void
DESTROY(x509)
	Crypt::OpenSSL::X509 x509;

	PPCODE:

	if (x509) X509_free(x509); x509 = 0;

SV*
accessor(x509)
	Crypt::OpenSSL::X509 x509;

	ALIAS:
	subject = 1
	issuer  = 2
	serial  = 3
	hash    = 4
	notBefore = 5
	notAfter  = 6
	email     = 7

	PREINIT:
	BIO *bio;
	X509_NAME *name;

	CODE:

	bio = sv_bio_create();

	/* this includes both serial and issuer since they are so much alike */
        if (ix == 1 || ix == 2) {

		if (ix == 1) {
			name = X509_get_subject_name(x509);
		} else {
			name = X509_get_issuer_name(x509);
		}

		/* this is prefered over X509_NAME_oneline() */
		X509_NAME_print_ex(bio, name, 0, XN_FLAG_SEP_CPLUS_SPC);

	} else if (ix == 3) {

		i2a_ASN1_INTEGER(bio, x509->cert_info->serialNumber);

	} else if (ix == 4) {

		BIO_printf(bio, "%08lx", X509_subject_name_hash(x509));

	} else if (ix == 5) {

                ASN1_TIME_print(bio, X509_get_notBefore(x509));

	} else if (ix == 6) {

                ASN1_TIME_print(bio, X509_get_notAfter(x509));

	} else if (ix == 7) {

		int j;
		STACK *emlst = X509_get1_email(x509);

		for (j = 0; j < sk_num(emlst); j++) {
			BIO_printf(bio, "%s", sk_value(emlst, j));
		}

		X509_email_free(emlst);
	}

	RETVAL = sv_bio_final(bio);

	OUTPUT:
	RETVAL

SV*
as_string(x509, format = FORMAT_PEM)
	Crypt::OpenSSL::X509 x509;
	int format;

	PREINIT:
	BIO *bio;

	CODE:

	bio = sv_bio_create();

	/* get the certificate back out in a specified format. */

	if (format == FORMAT_PEM) {

		PEM_write_bio_X509(bio, x509);

	} else if (format == FORMAT_ASN1) {

		i2d_X509_bio(bio, x509);

	} else if (format == FORMAT_NETSCAPE) {

		ASN1_HEADER ah;
		ASN1_OCTET_STRING os;

		os.data   = (unsigned char *)NETSCAPE_CERT_HDR;
		os.length = strlen(NETSCAPE_CERT_HDR);
		ah.header = &os;
		ah.data   = (char *)x509;
		ah.meth   = X509_asn1_meth();

		ASN1_i2d_bio(i2d_ASN1_HEADER, bio, (unsigned char *)&ah);
	}

	RETVAL = sv_bio_final(bio);

	OUTPUT:
	RETVAL

SV*
modulus(x509)
	Crypt::OpenSSL::X509 x509;

	PREINIT:
	EVP_PKEY *pkey;
	BIO *bio;

	CODE:

	pkey = X509_get_pubkey(x509);

	bio  = sv_bio_create();

	if (pkey == NULL) {
		croak("Modulus is unavailable\n");
		XSRETURN_UNDEF;
	}

	if (pkey->type == EVP_PKEY_RSA) {

		BN_print(bio, pkey->pkey.rsa->n);

	} else if (pkey->type == EVP_PKEY_DSA) {

		BN_print(bio, pkey->pkey.dsa->pub_key);

	} else {

		croak("Wrong Algorithm type\n");
	}

	RETVAL = sv_bio_final(bio);

	EVP_PKEY_free(pkey);

	OUTPUT:
	RETVAL

SV*
fingerprint_md5(x509)
	Crypt::OpenSSL::X509 x509;

	ALIAS:
	fingerprint_md2  = 1
	fingerprint_sha1 = 2

	PREINIT:

        const EVP_MD *mds[] = { EVP_md5(), EVP_md2(), EVP_sha1() };
	unsigned char md[EVP_MAX_MD_SIZE];
        int i;
	unsigned int n;
	BIO *bio;

	CODE:

	bio  = sv_bio_create();

	if (!X509_digest(x509, mds[ix], md, &n)) {
		croak("Digest error: %s", ssl_error());
	}

	BIO_printf(bio, "%02X", md[0]);
	for (i = 1; i < n; i++) {
		BIO_printf(bio, ":%02X", md[i]);
	}

	RETVAL = sv_bio_final(bio);

	OUTPUT:
	RETVAL

SV*
checkend(x509, checkoffset)
	Crypt::OpenSSL::X509 x509;
	IV checkoffset;

	PREINIT:
	time_t now;

	CODE:

	now = time(NULL);

	/* given an offset in seconds, will the certificate be expired? */
	if (ASN1_UTCTIME_cmp_time_t(X509_get_notAfter(x509), now + (int)checkoffset) == -1) {
		RETVAL = &PL_sv_yes;
	} else {
		RETVAL = &PL_sv_no;
	}

	OUTPUT:
	RETVAL

SV*
pubkey(x509)
	Crypt::OpenSSL::X509 x509;

	PREINIT:
	EVP_PKEY *pkey;
	BIO *bio;

	CODE:

	pkey = X509_get_pubkey(x509);
	bio  = sv_bio_create();

	if (pkey == NULL) {
		croak("Public Key is unavailable\n");
		XSRETURN_UNDEF;
	}

	if (pkey->type == EVP_PKEY_RSA) {

		PEM_write_bio_RSAPublicKey(bio, pkey->pkey.rsa);

	} else if (pkey->type == EVP_PKEY_DSA) {

		PEM_write_bio_DSA_PUBKEY(bio, pkey->pkey.dsa);

	} else {

		croak("Wrong Algorithm type\n");
	}

	RETVAL = sv_bio_final(bio);

	EVP_PKEY_free(pkey);

	OUTPUT:
	RETVAL
