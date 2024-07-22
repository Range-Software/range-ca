#!/bin/bash

myName=$(basename $0 .sh)
myPath=$(dirname $0)

caDir="$(dirname $myPath)"
certDays=3650
keySize=4096

assert_success()
{
    if [ $1 -ne 0 ]
    then
        echo "$2" >&2
        exit 1
    fi
}

assert_int()
{
    local _value=$1
    if ! [[ $_value =~ ^[-]?[0-9]+$ ]]; then
        echo "Value is not an integer. $2" >&2
        exit 1
    fi
}

assert_nonempty()
{
    if [ -z "$1" ]
    then
        echo "Value is empty. $2" >&2
        exit 1
    fi
}

extract_cmd_parameter_value()
{
    echo "${1#*=}"
}

print_help()
{
cat <<End-of-help
Usage: $myName.sh [OPTION]...

  mandatory

  optional

    --key-size=[NUMBER]               Size of key in bits (default=$keySize)
    --cert-days=[NUMBER]              Certificate validity in days (default=$certDays)

    --help, -h, -?                    Print this help and exit

End-of-help
}

while [ $# -gt 0 ]
do
    case $1 in
        --key-size=*)
            keySize=$(extract_cmd_parameter_value "$1")
            ;;
        --cert-days=*)
            certDays=$(extract_cmd_parameter_value "$1")
            ;;
        --help | -h | -?)
            print_help
            exit 0
            ;;
        *)
            echo "Unknown parameter '$1'" >&2
            exit 1
            ;;
    esac
    shift
done

assert_int $certDays "Invalid intermediate certificate validity"
assert_int $keySize "Invalid key size"

caRootDir="$caDir/rootCA"
caIntermediateDir="$caDir/intermediateCA"

echo
echo "Generate the intermediate CA key pair"
echo

openssl genrsa -out "$caIntermediateDir/private/intermediate.key.pem" $keySize && \
chmod -v 400 "$caIntermediateDir/private/intermediate.key.pem"
assert_success $? "Failed to generate intermediate CA key"

echo "NOTE: To view content of the private intermediate CA key run 'openssl rsa -noout -text -in \"$caIntermediateDir/private/intermediate.key.pem\"'"

echo
echo "Create the intermediate CA certificate signing request (CSR)"
echo

openssl req -config "$caIntermediateDir/openssl.cnf" -key "$caIntermediateDir/private/intermediate.key.pem" -new -sha256 -out "$caRootDir/csr/intermediate.csr.pem" -batch -verbose
assert_success $? "Failed to create intermediate CA certificate signing request (CSR)"

echo
echo "Sign the intermediate CSR with the root CA key"
echo

openssl ca -config "$caRootDir/openssl.cnf" -extensions v3_intermediate_ca -days $certDays -notext -md sha256 -in "$caRootDir/csr/intermediate.csr.pem" -out "$caIntermediateDir/certs/intermediate.cert.pem" -batch -verbose && \
chmod -v 444 "$caIntermediateDir/certs/intermediate.cert.pem"
assert_success $? "Failed to sign the intermediate CSR with the root CA key"

echo "NOTE: To check the index file run 'cat \"$caRootDir/index.txt\"'"
#>> V 330503082700Z 1000 unknown /C=US/ST=California/O=Example Corp/OU=IT Department/CN=Intermediate CA

echo "NOTE: To verify the Intermediate CA Certificate content run 'openssl x509 -noout -text -in \"$caIntermediateDir/certs/intermediate.cert.pem\"'"
echo "NOTE: To verify the Intermediate CA Certificate against the root certificate run 'openssl verify -CAfile \"$caRootDir/certs/ca.cert.pem\" \"$caIntermediateDir/certs/intermediate.cert.pem\"'"
#>> /root/myCA/intermediateCA/certs/intermediate.cert.pem: OK

echo
echo "Generate OpenSSL Create Certificate Chain (Certificate Bundle)"
echo

cat "$caIntermediateDir/certs/intermediate.cert.pem" "$caRootDir/certs/ca.cert.pem" > "$caIntermediateDir/certs/ca-chain.cert.pem"

echo "NOTE: To verify the certificate chain run 'openssl verify -CAfile \"$caIntermediateDir/certs/ca-chain.cert.pem\" \"$caIntermediateDir/certs/intermediate.cert.pem\"'"
#>> /root/myCA/intermediateCA/certs/intermediate.cert.pem: OK
