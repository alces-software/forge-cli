#!/bin/bash
tarball_name=${1:-forge}

sudo yum install -y gcc-c++ gmp-devel

mkdir /tmp/forge-cli-tar
pushd /tmp/forge-cli-tar >/dev/null

mkdir -p opt/forge
echo "Copying files..."
cp -r /media/host/forge-cli/* opt/forge

pushd opt/forge >/dev/null
rm -rf vendor
/opt/clusterware/opt/ruby/bin/bundle install --without="development test" --path=vendor
popd >/dev/null

echo "Cleaning extraneous files..."
rm -rf opt/forge/.idea/ opt/forge/.git opt/forge/*.tar.gz opt/forge/vendor/cache/ opt/forge/build-tarball.sh
echo "Tarring..."
tar -cf "${tarball_name}.tar" opt/forge/
echo "gzipping..."
gzip "${tarball_name}.tar"
mv "${tarball_name}.tar.gz" /media/host/forge-cli/
echo "Tarball /media/host/forge-cli/${tarball_name}.tar.gz created. Have fun!"
popd >/dev/null
rm -rf /tmp/forge-cli-tar
