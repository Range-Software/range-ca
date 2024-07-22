#!/bin/bash

myName=$(basename $0 .sh)
myPath=$(dirname $0)

caDir="$(dirname $myPath)"

certCommonName=
certSerial=

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

    --common-name=[STRING]            Common name
    --serial=[STRING]                 Serial number

  optional

    --help, -h, -?                    Print this help and exit

End-of-help
}

while [ $# -gt 0 ]
do
    case $1 in
        --common-name=*)
            certCommonName=$(extract_cmd_parameter_value "$1")
            ;;
        --serial=*)
            certSerial=$(extract_cmd_parameter_value "$1")
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

assert_nonempty "$certCommonName" "Common name not specified"
assert_nonempty "$certSerial" "Serial not specified"

caIntermediateDir="$caDir/intermediateCA"

dstCertFile=
for certFile in $(ls "$caIntermediateDir/certs/"*)
do
    echo $certFile
    foundCommonName=$(openssl x509 -noout -subject -in "$certFile" | grep -o '\<CN\s*=\s*[a-zA-Z0-9@_.\-]*' | sed -n 's/CN\s*=\s*//p')
    foundSerial=$(openssl x509 -noout -serial -in "$certFile" | sed -n 's/serial\s*=\s*//p')
    if [ "$foundCommonName" = "$certCommonName" ] && [ "$foundSerial" = "$certSerial" ]
    then
        dstCertFile="$certFile"
    fi
done

assert_nonempty "$dstCertFile" "Could not find certificate file for given common name and serial number"

echo "Revoking certificate \"$dstCertFile\""

openssl ca -config "$caIntermediateDir/openssl.cnf" -revoke "$dstCertFile" -verbose
assert_success $? "Failed to revoke certificate"
