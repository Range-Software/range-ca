#!/bin/bash

myName=$(basename $0 .sh)
myPath=$(dirname $0)

caDir=

caCountry=
caState=
caLocation=
caOrganization=
caOrganizationUnit=
caCommonName=
caEmail=

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

    --ca-dir=[PATH]                   Directory where whole CA directory structure will be created (default=$caDir)

    --country=[STRING]                Country (default=$caCountry)
    --state=[STRING]                  State (default=$caState)
    --location=[STRING]               Location (default=$caLocation)
    --organization=[STRING]           Organization (default=$caOrganization)
    --organization-unit=[STRING]      Organization unit (default=$caOrganizationUnit)
    --common-name=[STRING]            Common name (default=$caCommonName)
    --email=[STRING]                  E-mail address (default=$caEmail)

  optional

    --help, -h, -?                    Print this help and exit

End-of-help
}

while [ $# -gt 0 ]
do
    case $1 in
        --ca-dir=*)
            caDir=$(extract_cmd_parameter_value "$1")
            ;;
        --country=*)
            caCountry=$(extract_cmd_parameter_value "$1")
            ;;
        --state=*)
            caState=$(extract_cmd_parameter_value "$1")
            ;;
        --location=*)
            caLocation=$(extract_cmd_parameter_value "$1")
            ;;
        --organization=*)
            caOrganization=$(extract_cmd_parameter_value "$1")
            ;;
        --organization-unit=*)
            caOrganizationUnit=$(extract_cmd_parameter_value "$1")
            ;;
        --common-name=*)
            caCommonName=$(extract_cmd_parameter_value "$1")
            ;;
        --email=*)
            caEmail=$(extract_cmd_parameter_value "$1")
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

assert_nonempty "$caDir" "CA directory not specified"
assert_nonempty "$caCountry" "Country not specified"
assert_nonempty "$caState" "State not specified"
assert_nonempty "$caLocation" "Location not specified"
assert_nonempty "$caOrganization" "Organization not specified"
assert_nonempty "$caOrganizationUnit" "Organization unit not specified"
assert_nonempty "$caCommonName" "Common name not specified"
assert_nonempty "$caEmail" "E-mail address not specified"

caRootDir="$caDir/rootCA"
caIntermediateDir="$caDir/intermediateCA"
caScriptsDir="$caDir/scripts"

caRootCommonName="${caCommonName} Root CA"
caIntermediateCommonName="${caCommonName} Intermediate CA"

! test -d "$caRootDir"
assert_success $? "CA root directory '$caRootDir' already exists. Cleanup first."

! test -d "$caIntermediateDir"
assert_success $? "CA intermediate directory '$caIntermediateDir' already exists. Cleanup first."

echo
echo "Create OpenSSL CA directory structure"
echo

mkdir -vp "$caRootDir"/{certs,crl,newcerts,private,csr} && \
mkdir -vp "$caIntermediateDir"/{certs,crl,newcerts,private,csr} && \
mkdir -vp "$caScriptsDir" && \
echo 1000 > "$caRootDir/serial" && \
echo 1000 > "$caIntermediateDir/serial" && \
echo 0100 > "$caRootDir/crlnumber" && \
echo 0100 > "$caIntermediateDir/crlnumber" && \
touch "$caRootDir/index.txt" && \
touch "$caIntermediateDir/index.txt"
assert_success $? "Failed to create directory structure"

echo
echo "Configure openssl.cnf for Root CA Certificate"
echo

sedRootRepStr="s%<ca-dir>%$caRootDir%g;"
sedRootRepStr+="s%<country-name>%$caCountry%g;"
sedRootRepStr+="s%<state>%$caState%g;"
sedRootRepStr+="s%<location>%$caLocation%g;"
sedRootRepStr+="s%<organization>%$caOrganization%g;"
sedRootRepStr+="s%<organization-unit>%$caOrganizationUnit%g;"
sedRootRepStr+="s%<common-name>%$caRootCommonName%g;"
sedRootRepStr+="s%<email>%$caEmail%g"

sed "$sedRootRepStr" "$myPath/../conf/openssl_root.cnf" > "$caRootDir/openssl.cnf"
assert_success $? "Failed to replace placeholders in \"$caRootDir/openssl.cnf\""

echo
echo Configure openssl.cnf for Intermediate CA Certificate
echo

sedIntermediateRepStr="s%<ca-dir>%$caIntermediateDir%g;"
sedIntermediateRepStr+="s%<country-name>%$caCountry%g;"
sedIntermediateRepStr+="s%<state>%$caState%g;"
sedIntermediateRepStr+="s%<location>%$caLocation%g;"
sedIntermediateRepStr+="s%<organization>%$caOrganization%g;"
sedIntermediateRepStr+="s%<organization-unit>%$caOrganizationUnit%g;"
sedIntermediateRepStr+="s%<common-name>%$caIntermediateCommonName%g;"
sedIntermediateRepStr+="s%<email>%$caEmail%g"

sed "$sedIntermediateRepStr" "$myPath/../conf/openssl_intermediate.cnf" > "$caIntermediateDir/openssl.cnf"
assert_success $? "Failed to replace placeholders in \"$caIntermediateDir/openssl.cnf\""

if [ $(realpath "$myPath/../scripts") != $(realpath "$caScriptsDir") ]
then
    echo
    echo Copy range-ca scripts
    echo

    cp -v -r "$myPath/../scripts/"*.sh "$caScriptsDir"
    assert_success $? "Failed to copy \"$myPath/../scripts/*.sh\" to \"$caScriptsDir\""
fi

echo
echo Create root CA
echo

"$caScriptsDir"/ca_create_root_ca.sh
assert_success $? "Failed to create root CA"

echo
echo Create intermediate CA
echo

"$caScriptsDir"/ca_create_intermediate_ca.sh
assert_success $? "Failed to create intermediate CA"
