#! /usr/bin/env bash


RED="\e[31m"
ENDCOLOR="\e[0m"


# update libs
project_name=$(basename $(pwd))

libs_dir="libs"
if [ ! -d "$libs_dir" ]; then
    echo "Directory $libs_dir not found."
    exit 1
fi

echo -e "${RED}Updating libs:${ENDCOLOR}"
pushd $libs_dir > /dev/null

for lib in ./*; do
    if [ -d "$lib" ]; then
        pushd "$lib" > /dev/null
        echo -e "${RED}Pulling changes for lib/$(basename $lib)${ENDCOLOR}"
        git pull
        popd > /dev/null
    fi
done
popd > /dev/null



rm -rf build/
mkdir build
echo -e "${RED}Building $project_name${ENDCOLOR}"
odin build src/ -out:build/$project_name && \
    ./build/$project_name