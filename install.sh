#!/bin/sh

if [ "$(whoami)" != "root" ]; then echo 'Please run as root.'; fi
cd "$(dirname $0)"
cp ./bin/* /usr/bin/
mkdir -p /usr/local/lib/lua/5.4/
cp -r lib/* /usr/local/lib/lua/5.4/
echo Done.
