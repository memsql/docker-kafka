# Password
PASS="abcdefgh"

echo "Current date"
date

# Cert validity, in days
VALIDITY=100000

set -e

# Create client key and CSR
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -aes-256-cbc -pass pass:"$PASS" -out client.key
openssl req -new -key client.key -passin pass:"$PASS" -subj "/C=US/ST=Denial/L=Seattle/O=NSA/CN=memsql" -out client.csr

# Client cert extensions: CA:FALSE
cat > client_ext.cnf <<'EOF'
[ v3_client ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
basicConstraints = CA:FALSE
EOF

# Self-sign client CSR with its key, applying v3_client
openssl x509 -req -in client.csr -days "$VALIDITY" -sha256 -signkey client.key -passin pass:"$PASS" -out client.crt -extfile client_ext.cnf -extensions v3_client
rm -f client.csr client_ext.cn

# create self signed certs default is 2048 bit RSA
openssl req -new -x509 -keyout server.key -out server.crt -subj "/C=US/ST=Denial/L=Seattle/O=NSA/CN=host.example.com" -days $VALIDITY -passout "pass:$PASS"

# create schema cert
openssl req -new -x509 -keyout schema.key -out schema.crt -subj "/C=US/ST=Denial/L=Seattle/O=NSA/CN=host2.example.com" -days $VALIDITY -passout "pass:$PASS"

# create a pkcs12 bundle of the server cert and private key
openssl pkcs12 -export -in server.crt -inkey server.key -passin "pass:$PASS" -out server.p12 -password "pass:$PASS"

# create a pkcs12 bundle of the schema cert and private key
openssl pkcs12 -export -in schema.crt -inkey schema.key -passin "pass:$PASS" -out schema.p12 -password "pass:$PASS"

# create keystore of the pkcs12 bundle
keytool -importkeystore -deststorepass "$PASS" -destkeypass "$PASS" -destkeystore broker_host.example.com_server.keystore.jks -srckeystore server.p12 -srcstoretype PKCS12 -srcstorepass "$PASS"

# create keystore of the pkcs12 bundle
keytool -importkeystore -deststorepass "$PASS" -destkeypass "$PASS" -destkeystore schema.keystore.jks -srckeystore schema.p12 -srcstoretype PKCS12 -srcstorepass "$PASS"

# create truststore with the client cert
keytool -import -file client.crt -alias clientCert -keystore broker_host.example.com_server.truststore.jks -storepass "$PASS" -noprompt

cp server.crt ca-cert
cp client.crt client_memsql_client.pem
cp client.key client_memsql_client.key
