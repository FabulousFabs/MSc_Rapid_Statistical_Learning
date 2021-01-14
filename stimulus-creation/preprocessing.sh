#!/bin/sh

: << 'header'
shell script to run preprocessing pipeline in one go
requires one big mastered input wav (as well as relevant
descriptors etc. as required by python scripts)
header

# read all arguments
for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
            help)               help=1 ;;
            path)               path=${VALUE} ;;
            subject)            subject=${VALUE} ;;
            cut_m)              cut_m=${VALUE} ;;
            vod_fs)             vod_fs=${VALUE} ;;
            vod_agg)            vod_agg=${VALUE} ;;
            vod_cmd)            vod_cmd=${VALUE} ;;
            spl)                spl=${VALUE} ;;
            spl_db)             spl_db=${VALUE} ;;
            pcm)                pcm=${VALUE} ;;
            pcm_m)              pcm_m=${VALUE} ;;
            *)
    esac
done

# help function
if [ -n "$help" ]; then
        echo "Usage notes:\n";
        exit 0;
fi

# required parameters
if [ -z ${subject+x} ]; then echo "Failed because 'subject' parameter must be supplied.\nSee './preprocessing.sh help'."; exit 0; fi

# some parameter defaults
if [ -z "${path}" ]; then path="/users/fabianschneider/Documents/REAPER Media/"; fi
if [ -z "${cut_m}" ]; then cut_m=timed; fi
if [ -z "${vod_fs}" ]; then vod_fs=32000; fi
if [ -z "${vod_agg}" ]; then vod_agg=2; fi
if [ -z "${vod_cmd}" ]; then vod_cmd="-resample -nopass -voice -lean"; fi
if [ -z "${spl}" ]; then spl=true; fi
if [ -z "${spl_db}" ]; then spl_db=-25; fi
if [ -z "${pcm}" ]; then pcm=true; fi
if [ -z "${pcm_m}" ]; then pcm_m=PCM_16; fi

# preprocessing step 2: segmentation
echo "Segmentation starting...";
if test -f "$path$subject.wav"; then
        if [ "$cut_m" = timed ]; then
                cp -i "$path$subject.wav" "./preprocessing-timed/ins/$subject.wav";
                python3 ./preprocessing-timed/cut.py "$subject.wav" "$subject.txt";
                mv -v ./preprocessing-timed/outs/*.wav ./preprocessing-vod/logs/;
        else
                cp -i "$path$subject.wav" "./preprocessing-cyclical/ins/$subject.wav";
                python3 ./preprocessing-cyclical/cut.py "$subject.wav";
                mv -v ./preprocessing-cyclical/outs/*.wav ./preprocessing-vod/logs/;
        fi
else
        echo "$path$subject.wav does not exist";
        exit 0;
fi

# preprocessing step 3: vod
echo "Voice onset detection starting...";
python3 ./preprocessing-vod/preprocessing.py "--Fs=$vod_fs" "--a=$vod_agg" $vod_cmd

# preprocessing step 4: finalisation
if [ $spl = true ] || [ $pcm = true ]; then
        echo "Finalisation starting..."
        mv -v ./preprocessing-vod/outputs/*.wav ./preprocessing-finalise/data/
fi

if [ $spl = true ] && [ $pcm = true ]; then
        python3 ./preprocessing-finalise/finalise.py "--db=$spl_db" "--pcm=$pcm_m" -spl -pcm
        rm ./preprocessing-finalise/data/*.wav
        rm ./preprocessing-finalise/spl/*.wav
elif [ $spl = true ]; then
        python3 ./preprocessing-finalise/finalise.py "--db=$spl_db" -spl
        rm ./preprocessing-finalise/data/*.wav
elif [ $pcm = true ]; then
        python3 ./preprocessing-finalise/finalise.py --no-spl "--pcm=$pcm_m" -pcm
        rm ./preprocessing-finalise/data/*.wav
else
        echo "Finalisation skipped.";
fi

# done
echo "Preprocessing completed.";
