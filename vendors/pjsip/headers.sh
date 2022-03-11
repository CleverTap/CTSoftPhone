#!/bin/sh
export BASE_DIR=`pwd -P`
export SRC_DIR="${BASE_DIR}/build/pjproject/src"
export INCLUDES_DIR="${BASE_DIR}/include"

export SRC_DIR
export INCLUDES_DIR

function copy_to_lib_dir () {
    old_path=$1
    new_path=()

    path_parts=(`echo $1 | tr '/' '\n'`)
    for x in "${path_parts[@]}"; do
        if [ "$x" = "include" ] || [ "${#new_path[@]}" -ne "0" ]; then
            new_path+=("$x")
        fi
    done

    new_path="${new_path[@]:1}"
    new_path="${new_path// //}"

    d="$INCLUDES_DIR/$(dirname $new_path)"
    echo "$d"
    echo "$old_path"
    mkdir -p $d
    cp $old_path $d
}

export -f copy_to_lib_dir

function copy_headers () {
    echo "Copying header files"
    cd "$SRC_DIR"

    find . -path "./third_party" -prune -o -path "./pjsip-apps" -prune -o -path "./include" -prune -o -type f -wholename "*include/*.h*" -exec bash -c 'copy_to_lib_dir "{}"' ';' 2>&1
    cd "$BASE_DIR"
    echo "Done copying header files"
    echo "============================="
}

copy_headers
