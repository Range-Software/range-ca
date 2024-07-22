#!/bin/bash

myName=$(basename $0 .sh)
myPath=$(dirname $0)

caDir="$(dirname $myPath)"
certDays=7300
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

assert_int $certDays "Invalid root certificate validity"
assert_int $keySize "Invalid key size"

caRootDir="$caDir/rootCA"

echo
echo "Generate the root CA key pair"
echo

openssl genrsa -out "$caRootDir/private/ca.key.pem" $keySize && \
chmod -v 400 "$caRootDir/private/ca.key.pem"
assert_success $? "Failed to generate root CA key"

echo "NOTE: To view content of the private root CA key run 'openssl rsa -noout -text -in \"$caRootDir/private/ca.key.pem\"'"

echo
echo "Create the root CA key pair"
echo

openssl req -config "$caRootDir/openssl.cnf" -key "$caRootDir/private/ca.key.pem" -new -x509 -days $certDays -sha256 -extensions v3_ca -out "$caRootDir/certs/ca.cert.pem" -verbose && \
chmod -v 444 "$caRootDir/certs/ca.cert.pem"
assert_success $? "Failed to create root CA certificate"

echo "NOTE: To verify root CA certificate run 'openssl x509 -noout -text -in \"$caRootDir/certs/ca.cert.pem\"'"
