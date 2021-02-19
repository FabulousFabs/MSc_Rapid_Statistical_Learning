#!/bin/sh

: << 'header'
shell script to run multiple passes of cqt_variance.py such
that we can get all relevant CQTs for any particular item
we specify here in the script without having to manually
use the script as often
header

# read all arguments
for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
            help)               help=1 ;;
            item)               item=${VALUE} ;;
            path)               path=${VALUE} ;;
            *)
    esac
done

# help function
if [ -n "$help" ]; then
        echo "";
        echo "Usage notes";
        echo "---------------------------";
        echo "Required parameters:";
        echo "\titem=int";
        echo "---------------------------";
        echo "Optional parameters:";
        echo "\tpath=string";
        echo "---------------------------";
        echo "Example usage:";
        echo "\t./cqt_variance_quick.sh path=\"/users/my/items/\" item=5";
        echo "";
        exit 0;
fi

# required parameters
if [ -z ${item+x} ]; then echo "Failed because 'item' parameter must be supplied.\nSee './cqt_variance_quick.sh help'."; exit 0; fi

# some parameter defaults
if [ -z "${path}" ]; then path="/users/fabianschneider/desktop/university/master/dissertation/project/write-up/graphics_general/"; fi

# main loops
for i in {1..4}; do
        j=$((i + 4));
        k=$((j + 4));

        for n in {1..4}; do
                python3 ./cqt_variance.py --i=$item --n=$n --s1=$i --s2=$j --s3=$k -cqt
        done
done

echo "All done!";
