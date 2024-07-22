#!/bin/bash

myName=$(basename $0 .sh)
myPath=$(dirname $0)

caDir="$(dirname $myPath)"

certFile=

assert_success()
{
    if [ $1 -ne 0 ]
    then
        echo "$2" >&2
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

    --cert=[PATH]                     Path to certificate file

  optional

    --help, -h, -?                    Print this help and exit

End-of-help
}

while [ $# -gt 0 ]
do
    case $1 in
        --cert=*)
            certFile=$(extract_cmd_parameter_value "$1")
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

assert_nonempty "$certFile" "Certificate file not specified"

caIntermediateDir="$caDir/intermediateCA"

echo
echo "Verify certificate"
echo

openssl verify -extended_crl -verbose -CAfile "$caIntermediateDir/certs/ca-chain.cert.pem" -CRLfile "$caIntermediateDir/crl/crl.pem" -crl_check "$certFile"
assert_success $? "Failed to verify certificate file"
