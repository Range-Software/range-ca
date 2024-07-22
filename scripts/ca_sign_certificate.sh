#!/bin/bash

myName=$(basename $0 .sh)
myPath=$(dirname $0)

caDir="$(dirname $myPath)"

inCsrFile=
outCertFile=
certExtension=
certCommonName=
defaultExtensions=("client_cert" "server_cert")

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

    --csr=[PATH]                      Path to certificate signing request (CSR) file
    --cert=[PATH]                     Path to file in which signed certificate will be stored
    --extension=[STRING]              Extension for certificate type (values=[${defaultExtensions[*]}])

  optional

    --help, -h, -?                    Print this help and exit

End-of-help
}

while [ $# -gt 0 ]
do
    case $1 in
        --csr=*)
            inCsrFile=$(extract_cmd_parameter_value "$1")
            ;;
        --cert=*)
            outCertFile=$(extract_cmd_parameter_value "$1")
            ;;
        --extension=*)
            certExtension=$(extract_cmd_parameter_value "$1")
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

assert_nonempty "$inCsrFile" "CSR file not specified (input)"
assert_nonempty "$outCertFile" "Signed certificate file not specified (output)"
assert_nonempty "$certExtension" "Certificate extension not specified"

caIntermediateDir="$caDir/intermediateCA"

certCommonName=$(openssl req -noout -subject -in "$inCsrFile" | grep -o '\<CN\s*=\s*[a-zA-Z0-9@_.\-]*' | sed -n 's/CN\s*=\s*//p')

dstCsrFile="$caIntermediateDir/csr/$certCommonName.csr.pem"
dstCertFile="$caIntermediateDir/csr/$certCommonName.cert.pem"

cntr=0
while [ -f "$dstCsrFile" ]
do
    cntr=$[cntr+1]
    dstCsrFile="$caIntermediateDir/csr/$certCommonName.csr.pem_$cntr"
    dstCertFile="$caIntermediateDir/certs/$certCommonName.cert.pem_$cntr"
done

if ! [ "$inCsrFile" -ef "$dstCsrFile" ]
then
    cp -v "$inCsrFile" "$dstCsrFile"
    assert_success $? "Failed to copy CSR file"
fi

echo
echo "Sign the CSR with the intermediate CA key"
echo

openssl ca -config "$caIntermediateDir/openssl.cnf" -extensions "$certExtension" -notext -md sha256 -in "$dstCsrFile" -out "$dstCertFile" -batch -verbose
retVal=$?
if [ $retVal -ne 0 ]
then
    rm -v "$dstCsrFile"
    assert_success $? "Failed to remove CSR file"
    assert_success $retVal "Failed to sign the server CSR with the intermediate CA key"
fi

cp -v "$dstCertFile" "$outCertFile"
assert_success $? "Failed to copy certificate file"

echo "NOTE: To verify the server certificate run 'openssl x509 -noout -text -in \"$outCertFile\"'"
