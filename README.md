# Range - Certificate Authority

**Range CA** is a set of tools to create own limited Certificate Authority to issue (sign), revoke and verify client or host certificates.

## Setup Certificate Authority

```
./scripts/ca_setup.sh \
    --ca-dir="/path/to/your/range-ca" \
    --country="<iso-country-code>" \
    --state="<state>" \
    --location="<location>" \
    --organization="<organization>" \
    --organization-unit="<organization-unit>" \
    --common-name="your-domain.com" \
    --email=admin@your-domain.com
```
NOTE: Replace above parameter values and placeholders with real values.

## Cleanup Certificate Authority

```
./scripts/ca_cleanup.sh --ca-dir="/path/to/your/range-ca"
```

## Sign certificate

```
./scripts/ca_sign_certificate.sh \
    --csr="/path/to/input_file.csr" \
    --cert="/path/to/output_file.crt" \
    --extension=["client_cert" or "server_cert"]
```

## Verify certificate

```
./scripts/ca_verify_certificate.sh --cert="/path/to/input_file.crt"
```

## Revoke certificate

```
./scripts/ca_revoke_certificate.sh --common-name="certificate common name" --serial="certificate serial number"
```

## Directory and file structure

### Directories
* **certs** - This directory contains the certificates generated and signed by the CA. For the root CA, this includes the root CA certificate itself. For the intermediate CA, this includes the intermediate CA certificate and any server or client certificates signed by the intermediate CA.
* **crl** - The Certificate Revocation List (CRL) directory contains the CRLs generated by the CA. A CRL is a list of certificates that have been revoked by the CA before their expiration date.
* **newcerts** - This directory stores a copy of each certificate signed by the CA, with the certificate's serial number as the file name. It helps maintain a backup of all issued certificates.
* **private** - This directory contains the private keys for the CA, including the root CA and intermediate CA private keys. These keys are used to sign certificates and CRLs. The private keys should be kept secure and not shared.

### Files
* **serial** - Used to keep track of the last serial number that was used to issue a certificate.
* **crlnumber** - Configuration directive specifying the file that contains the current CRL number.
* **index.txt** - Database of sorts that keeps track of the certificates that have been issued by the CA.

```
range-ca/
├── conf
│   ├── openssl_intermediate.cnf
│   └── openssl_root.cnf
├── intermediateCA
│   ├── certs
│   │   ├── ca-chain.cert.pem
│   │   └── intermediate.cert.pem
│   ├── crl
│   ├── crlnumber
│   ├── csr
│   ├── index.txt
│   ├── index.txt.attr
│   ├── newcerts
│   ├── openssl.cnf
│   ├── private
│   │   └── intermediate.key.pem
│   └── serial
├── LICENSE
├── README.md
├── rootCA
│   ├── certs
│   │   └── ca.cert.pem
│   ├── crl
│   ├── crlnumber
│   ├── csr
│   │   └── intermediate.csr.pem
│   ├── index.txt
│   ├── index.txt.attr
│   ├── index.txt.old
│   ├── newcerts
│   │   └── 1000.pem
│   ├── openssl.cnf
│   ├── private
│   │   └── ca.key.pem
│   ├── serial
│   └── serial.old
└── scripts
    ├── ca_cleanup.sh
    ├── ca_create_intermediate_ca.sh
    ├── ca_create_root_ca.sh
    ├── ca_create_signed_certificate.sh
    ├── ca_generate_crl.sh
    ├── ca_revoke_certificate.sh
    ├── ca_setup.sh
    ├── ca_sign_certificate.sh
    └── ca_verify_certificate.sh
```

_Based on instructions from: https://www.golinuxcloud.com/openssl-create-certificate-chain-linux/_