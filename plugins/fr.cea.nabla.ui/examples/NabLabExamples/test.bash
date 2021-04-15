#!/bin/bash
# NOTE: We need bash version > 4.x because of the for loops we use. We will
# check the ENV and force the C++ compiler because we must use llvm for the
# openmp tasks target.

test "x$CXX" = "x" && die "No CXX variable in your environment"

###
# The functions to do the work
###

# Exit with an error message
function die()
{
    echo "$*"
    exit 1
}

# Force the compiler in the CMake file
function ___force_compiler()
{
    local CMAKEFILE="$1"
    test "x$CMAKEFILE" = "x" && die "Invalid argument in function ___force_compiler"

    awk "/set\(CMAKE_CXX_COMPILER/{gsub(/\\/usr\\/bin\\/g\\+\\+/,\"$CXX\")};{print}" < $CMAKEFILE > $CMAKEFILE.tmp
    mv $CMAKEFILE.tmp $CMAKEFILE
    return $?
}

# Set the nonreg option in the JSON config file
function ___set_nonreg_option()
{
    local JSON="$1"
    local OPTION="$2"
    test "x$OPTION" = "x" && die "Invalid argument in function ___set_nonreg_option"

    sed -i "s+\"nonRegression\":\"\"+\"nonRegression\":\"$OPTION\"+g" "$JSON"
    return $?
}

# Bootstrap the skeleton directory
function ___bootstrap_skeleton()
{
    local WHICH="$1"
    test "x$WHICH" = "x" && die "Invalid argument in function ___bootstrap_skeleton"

    rm -rf src-gen-cpp.$WHICH
    cp -r src-gen-cpp src-gen-cpp.$WHICH

    # For all applications: glace2d, iterativeheatequation, etc
    for D in src/* ; do
        local app=$(echo "$D" | sed -e 's+src/++g')
        local APP=$(echo "${app^}")

        # Get the json config file for that application
        for SRC in $D/*.json ; do

            # Get the target folders: openmp, openmptask, kokkos, etc
            for TARGET in src-gen-cpp.$WHICH/* ; do
                # Get variables for the correct target & app & configuration
                local DEST_FOLDER=$TARGET/$app
                local DEST_JSON=$DEST_FOLDER/$APP.json
                local DEST_CMAKE=$DEST_FOLDER/CMakeLists.txt
                local OPTION="CompareToReference"
                if test "x$WHICH" = "xref" ; then
                    OPTION="CreateReference"
                fi

                # The banner
                echo "######"
                echo "### BOOTSTRAP ${APP^^} WITH TARGET ${TARGET^^}"
                echo "######"

                # Bootstrap the application with the target
                cp -f "$SRC" "$DEST_JSON"                   || die "Failed to copy '$SRC' to '$DEST_JSON'"
                mkdir "$DEST_FOLDER/build/"                 || die "Failed to create build folder '$DEST_FOLDER/build/'"
                ___force_compiler "$DEST_CMAKE"             || die "Failed to force compiler to $CXX in '$DEST_CMAKE'"
                ___set_nonreg_option "$DEST_JSON" "$OPTION" || die "Failed to set nonreg option to '$OPTION'"
                ( cd "$DEST_FOLDER/build/" && cmake .. )    || die "Failed to setup ${APP^^} with target ${TARGET^^}"
            done
        done
    done
}

# Build all the applications with all the targets in the folder
function ___build_skeleton()
{
    local WHICH="$1"
    test "x$WHICH" = "x" && die "Invalid argument in function ___build_skeleton"

    for D in src/* ; do
        local app=$(echo "$D" | sed -e 's+src/++g')
        local APP=$(echo "${app^}")

        # Get the target folders: openmp, openmptask, kokkos, etc
        for TARGET in src-gen-cpp.$WHICH/* ; do
            local DEST_FOLDER=$TARGET/$app

            echo "######"
            echo "### BUILD ${APP^^} WITH TARGET ${TARGET^^}"
            echo "######"

            ( cd "$DEST_FOLDER/build/" && make -j$(nproc) ) || die "Failed to build ${APP^^} with target ${TARGET^^}"
        done
    done
}

# Run all the applications with all the targets in the folder
function ___run_skeleton()
{
    local WHICH="$1"
    test "x$WHICH" = "x" && die "Invalid argument in function ___build_skeleton"

    for D in src/* ; do
        local app=$(echo "$D" | sed -e 's+src/++g')
        local APP=$(echo "${app^}")

        # Get the target folders: openmp, openmptask, kokkos, etc
        for TARGET in src-gen-cpp.$WHICH/* ; do
            local DEST_FOLDER=$TARGET/$app
            local DEST_JSON=$DEST_FOLDER/$APP.json
            local DEST_JSON=$(realpath "$DEST_JSON")

            echo "######"
            echo "### BUILD ${APP^^} WITH TARGET ${TARGET^^}"
            echo "######"

            ( cd "$DEST_FOLDER/build/" && ./$app "$DEST_JSON" ) || die "Failed to execute ${APP^^} with target ${TARGET^^} and file ${DEST_JSON}"
        done
    done
}

###
# The script
###

case "$1" in
    bt-compare)     ___bootstrap_skeleton 'current';;
    bt-ref)         ___bootstrap_skeleton 'ref';;

    mk-compare)     ___build_skeleton 'current';;
    mk-ref)         ___build_skeleton 'ref';;

    run-compare)    ___run_skeleton 'current';;
    run-ref)        ___run_skeleton 'ref';;

# Help
*) cat << EOF
Usage: ./test.bash <compare|ref>

bootstrap commands
    bt-compare:  Create the files to compare to the reference
    bt-ref:      Create the ref files

make commands
    mk-compare:  Build the current applications
    mk-ref:      Build the reference applications

run commands
    run-compare: Run the current applications and compare to the db
    run-ref:     Run the reference applications and populate the ref db

misc:
    Using C++ compiler: $CXX
EOF
exit 1;;
esac
exit 0
