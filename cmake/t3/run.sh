cd build
rm  -rf CMakeCache.txt

cmake -DCMAKE_INSTALL_PREFIX=~/usr ..
make
make install
cd -
