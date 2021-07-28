#!/bin/bash

openssl req -x509 -nodes -days 730 -newkey rsa:2048 -keyout /dev/null -out smime.pem -config smime.conf -extensions 'v3_req'
