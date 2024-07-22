#!/bin/bash

myName=$(basename $0 .sh)
myPath=$(dirname $0)

caDir="$(dirname $myPath)"

outKeyFile=
outCertFile=

keyPassword=

certCountry=
certState=
certLocation=
certOrganization=
certOrganizationUnit=
certCommonName=
certEmail=
certExtension=
defaultExtensions=("client_cert" "server_cert")

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

    --key=[PATH]                      Path to file in which key will be stored
    --cert=[PATH]                     Path to file in which signed certificate will be stored
    --extension=[STRING]              Extension for certificate type (values=[${defaultExtensions[*]}])

    --country=[STRING]                Country (default=$certCountry)
    --state=[STRING]                  State (default=$certState)
    --location=[STRING]               Location (default=$certLocation)
    --organization=[STRING]           Organization (default=$certOrganization)
    --organization-unit=[STRING]      Organization unit (default=$certOrganizationUnit)
    --common-name=[STRING]            Common name (default=$certCommonName)
    --email=[STRING]                  E-mail address (default=$certEmail)

  optional

    --password=[STRING]               Key password (default=$keyPassword)

    --help, -h, -?                    Print this help and exit

End-of-help
}

while [ $# -gt 0 ]
do
    case $1 in
        --extension=*)
            certExtension=$(extract_cmd_parameter_value "$1")
            ;;
        --key=*)
            outKeyFile=$(extract_cmd_parameter_value "$1")
            ;;
        --cert=*)
            outCertFile=$(extract_cmd_parameter_value "$1")
            ;;
        --password=*)
            keyPassword=$(extract_cmd_parameter_value "$1")
            ;;
        --country=*)
            certCountry=$(extract_cmd_parameter_value "$1")
            ;;
        --state=*)
            certState=$(extract_cmd_parameter_value "$1")
            ;;
        --location=*)
            certLocation=$(extract_cmd_parameter_value "$1")
            ;;
        --organization=*)
            certOrganization=$(extract_cmd_parameter_value "$1")
            ;;
        --organization-unit=*)
            certOrganizationUnit=$(extract_cmd_parameter_value "$1")
            ;;
        --common-name=*)
            certCommonName=$(extract_cmd_parameter_value "$1")
            ;;
        --email=*)
            certEmail=$(extract_cmd_parameter_value "$1")
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

assert_nonempty "$outKeyFile" "Key file not specified (output)"
assert_nonempty "$outCertFile" "Signed certificate file not specified (output)"
assert_nonempty "$certExtension" "Certificate extension not specified"
assert_nonempty "$certCountry" "Country not specified"
assert_nonempty "$certState" "State not specified"
assert_nonempty "$certLocation" "Location not specified"
assert_nonempty "$certOrganization" "Organization not specified"
assert_nonempty "$certOrganizationUnit" "Organization unit not specified"
assert_nonempty "$certCommonName" "Common name not specified"
assert_nonempty "$certEmail" "E-mail address not specified"

caRootDir="$caDir/rootCA"
caIntermediateDir="$caDir/intermediateCA"

subject="/C=${certCountry}/ST=${certState}/L=${certLocation}/O=${certOrganization}/OU=${certOrganizationUnit}/CN=${certCommonName}"
dstKeyFile="$caIntermediateDir/private/$certCommonName.key.pem"
dstCsrFile="$caIntermediateDir/csr/$certCommonName.csr.pem"

echo
echo "Generate key"
echo

openssl genpkey -algorithm RSA -out "$dstKeyFile" -pass "pass:$keyPassword" && \
chmod -v 400 "$dstKeyFile"
assert_success $? "Failed to generate server key"

cp -v "$dstKeyFile" "$outKeyFile"
assert_success $? "Failed to copy certificate file"

echo
echo "Create certificate signing request (CSR)"
echo

openssl req -key "$dstKeyFile" -passin "pass:$keyPassword" -new -sha256 -out "$dstCsrFile" -subj "$subject" -batch -verbose
assert_success $? "Failed to create server certificate signing request (CSR)"

echo
echo "Sign the CSR with the intermediate CA key"
echo

$myPath/ca_sign_certificate.sh --extension="$certExtension" --csr="$dstCsrFile" --cert="$outCertFile"
assert_success $? "Failed to sign the server CSR with the intermediate CA key"

echo "NOTE: To view content of the certificate run 'openssl x509 -noout -text -in \"$outCertFile\"'"
