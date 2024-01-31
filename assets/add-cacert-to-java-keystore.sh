#!/usr/bin/env bash
set -eo pipefail

USAGE="call the script with the path to the cert file: 'ca-alias' '/etc/ssl/ca/ca.pem' '/path/to/keystore'"

PEM_FILE=$1
KEYSTORE=$2
[ ! -f "$PEM_FILE" ] && echo $USAGE && exit 1
[ ! -f "$KEYSTORE" ] && echo $USAGE && exit 1

echo
echo adding "$PEM_FILE" to java keystore

# number of certs in the PEM file
CERTS=$(grep 'END CERTIFICATE' $PEM_FILE| wc -l)

# For every cert in the PEM file, extract it and import into the JKS keystore
# awk command: step 1, if line is in the desired cert, print the line
#              step 2, increment counter when last line of cert is found
#
# NOTE: default cacert password is `changeit`, we evaluated the necessity of
# updating it and didn't find a viable, more secure solution.
for N in $(seq 0 $(($CERTS - 1))); do
  ALIAS="${PEM_FILE%.*}-$N"
  cat $PEM_FILE |
    awk "n==$N { print }; /END CERTIFICATE/ { n++ }" |
    keytool -import -trustcacerts \
        -alias "$ALIAS" \
        -keystore $KEYSTORE \
        -storepass changeit \
        -noprompt
done
