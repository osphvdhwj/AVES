#!/bin/bash

# Generate keystore file
keytool -genkeypair -alias my_alias -keyalg RSA -keysize 2048 -validity 10000 -keystore my-release-key.jks -storepass pass1234 -keypass pass1234 -dname "CN=GitHub Actions, OU=DevOps, O=MyCompany, L=City, ST=State, C=Country"

# Base64 encode the file for secret upload
base64 my-release-key.jks > my-release-key.base64

# Output Base64 content
cat my-release-key.base64

# End of script
