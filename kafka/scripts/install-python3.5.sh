#!/bin/bash
# This script installs python 3.5 from source because on the debian image
# used the pip3 and python are incompatible.
#
wget https://www.python.org/ftp/python/3.5.0/Python-3.5.0.tgz
tar xzf Python-3.5.0.tgz
cd Python-3.5.0
./configure
make install
cd ..
rm -rf Python-3.5.0
