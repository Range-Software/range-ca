#!/bin/bash

myName=$(basename $0 .sh)
myPath=$(dirname $0)

caDir="$(dirname $myPath)"

outCrlFile=

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

    --crl=[PATH]                      Path to file in which CRL will be stored

  optional

    --help, -h, -?                    Print this help and exit

End-of-help
}

while [ $# -gt 0 ]
do
    case $1 in
        --crl=*)
            outCrlFile=$(extract_cmd_parameter_value "$1")
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

assert_nonempty "$outCrlFile" "CRL file not specified (output)"

caIntermediateDir="$caDir/intermediateCA"
dstCrlFile="$caIntermediateDir/crl/crl.pem"

echo
echo "Generate CRL"
echo

openssl ca -config "$caIntermediateDir/openssl.cnf" -gencrl -out "$dstCrlFile" -verbose
assert_success $? "Failed to generate CRL file"

cp -v "$dstCrlFile" "$outCrlFile"
assert_success $? "Failed to copy CRL file"

#echo "NOTE: To verify the server certificate run 'openssl x509 -noout -text -in \"$caIntermediateDir/certs/$certCommonName.cert.pem\"'"
