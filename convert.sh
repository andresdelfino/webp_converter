#!/bin/bash
set -eo pipefail

MAX_FILE_SIZE=26214400
MOUNTED_PATH=/channel

echo Ready

while true; do
    if ! compgen -G "$MOUNTED_PATH/*.webp" > /dev/null; then
        sleep 5
        continue
    fi

    for input_file in $MOUNTED_PATH/*.webp; do
        TEMP_FILE=$(mktemp)
        webpmux -info $input_file > $TEMP_FILE

        if grep animation $TEMP_FILE > /dev/null; then
            output_filename=${input_file##*/}
            output_filename=${output_filename/%webp/gif}

            frame_count=$(awk 'NR == 4 { print $NF }' $TEMP_FILE)

            CONVERT_ARGS=()

            for frame in $(seq -w $frame_count); do
                frame_digit=$(echo $frame | sed 's/^0*//')
                frame_line=$(grep -E "^ *$frame_digit:" $TEMP_FILE)
                x_offset=$(echo "$frame_line" | awk '{ print $5 }')
                y_offset=$(echo "$frame_line" | awk '{ print $6 }')
                duration=$(echo "$frame_line" | awk '{ print $7 }')
                delay=$(($duration / 10))
                page=+$x_offset+$y_offset
                webpmux -get frame $frame $input_file -o - | dwebp -mt -o $WORK_PATH/$frame.png -- -
                CONVERT_ARGS+=(-page $page -delay $delay $WORK_PATH/$frame.png)
            done

            convert -loop 0 "${CONVERT_ARGS[@]}" $MOUNTED_PATH/$output_filename
            rm -f $WORK_PATH/*.png
        else
            output_filename=${input_file##*/}
            output_filename=${output_filename/%webp/png}
            dwebp -mt -o $MOUNTED_PATH/$output_filename $input_file
        fi

        rm $input_file

        chmod o+w $MOUNTED_PATH/$output_filename

        echo ✅ $output_filename

        if [[ $(stat --printf='%s' $MOUNTED_PATH/$output_filename) -gt $MAX_FILE_SIZE ]]; then
            echo ⚠️ File size greater than $(($MAX_FILE_SIZE / 1024 / 1024)) MB
            mv $MOUNTED_PATH/$output_filename $MOUNTED_PATH/heavy_$output_filename
        fi
    done
done