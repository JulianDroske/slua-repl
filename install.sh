#!/bin/sh

if [ "$(whoami)" != "root" ]; then echo 'Please run as root.'; fi
cd "$(dirname $0)"
INSTALLDIR=/usr/local/share/lua/5.4/

echo Installing...
cp ./bin/* /usr/bin/
mkdir -p "$INSTALLDIR"
cp -r lib/* "$INSTALLDIR"

echo Generating unist.sh...
UNISTDIR="$(echo $INSTALLDIR |sed 's/\//\\\//g')"
echo '#!/bin/sh' >unist.sh
cd lib/
find . -mindepth 1 -maxdepth 1 -type f,d |sed 's/^\.\//rm -rf '"$UNISTDIR"'/g' >> ../unist.sh
cd ..
echo >>unist.sh
chmod 0755 unist.sh
echo Done.
