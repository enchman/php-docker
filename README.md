# Docker image - PHP apache
## Quick guide to installation
  1. Build docker image file ```docker build -f Dockerfile -t {{YOUR_IMAGE}}```
  2. Run docker ```docker run  --env APACHE_CERTIFICATE=/etc/ssl/cert.crt --env APACHE_CERTIFICATE_PRIVATE=/etc/ssl/private.key --env APACHE_DOCUMENT_ROOT=/var/www/html --env APACHE_DATA_ROOT=/var/www/dat -t {{YOUR_IMAGE}}```
