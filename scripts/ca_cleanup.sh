#!/bin/bash

myName=$(basename $0 .sh)
myPath=$(dirname $0)

caDir=

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

    --ca-dir=[PATH]                   Path to CA directory structure (default=$caDir)

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

caRootDir="$caDir/rootCA"
caIntermediateDir="$caDir/intermediateCA"

caRootCommonName="${caCommonName} Root CA"
caIntermediateCommonName="${caCommonName} Intermediate CA"

echo
echo "Remove OpenSSL CA directory structure"
echo

chmod -R u+w "$caRootDir" && \
chmod -R u+w "$caIntermediateDir" && \
rm -rfv "$caRootDir" && \
rm -rfv "$caIntermediateDir"
assert_success $? "Failed to remove CA directory structure"
