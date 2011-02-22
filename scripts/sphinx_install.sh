#!/bin/bash

cd ../sphinx/src
tar xzvf sphinx-0.9.9.tar.gz
cd sphinx-0.9.9
./configure --prefix `pwd`/../..
make && make install
cd ../..
./indexer.sh full
killall searchd
bin/searchd

echo "you have to insert the search daemon in the rc.local file. Please refer to the manual"

