# Password
PASS="abcdefgh"

echo "Current date"
date

# Cert validity, in days
VALIDITY=100000

set -e
# create self signed certs default is 2048 bit RSA
openssl req -new -x509 -keyout client.key -out client.crt -subj "/C=US/ST=Denial/L=Seattle/O=NSA/CN=memsql" -days $VALIDITY -passout "pass:$PASS"
openssl req -new -x509 -keyout server.key -out server.crt -subj "/C=US/ST=Denial/L=Seattle/O=NSA/CN=host.example.com" -days $VALIDITY -passout "pass:$PASS"

# create a pkcs12 bundle of the server cert and private key
openssl pkcs12 -export -in server.crt -inkey server.key -passin "pass:$PASS" -out server.p12 -password "pass:$PASS"

# create keystore of the pkcs12 bundle
keytool -importkeystore -deststorepass "$PASS" -destkeypass "$PASS" -destkeystore broker_host.example.com_server.keystore.jks -srckeystore server.p12 -srcstoretype PKCS12 -srcstorepass "$PASS"

# create truststore with the client cert
keytool -import -file client.crt -alias clientCert -keystore broker_host.example.com_server.truststore.jks -storepass "$PASS" -noprompt

cp server.crt ca-cert
cp client.crt client_memsql_client.pem
cp client.key client_memsql_client.key
