#!/bin/sh

source script_parser.sh

# insmod touchscreen driver
tp_module_path=`script_fetch "tp" "module_path"`
if [ -n "$tp_module_path" ]; then
    insmod "$tp_module_path"

    # calibrate touchscreen if need
    tp_type=`script_fetch "tp" "type"`
    if [ $tp_type -eq 0 ]; then
        while true; do
            ts_calibrate
            if [ $? -eq 0 ]; then
                break
            fi
        done
    fi

    #ts_test
else
    echo "NO!!! touchscreen driver to be insmod"
fi

# insmod ir driver
ir_activated=`script_fetch "ir" "activated"`
if [ $ir_activated -eq 1 ]; then
    ir_module_path=`script_fetch "ir" "module_path"`
    if [ -n "$ir_module_path" ]; then
        insmod "$ir_module_path"
    fi
fi

# start camera test firstly
while true; do
    camera_activated=`script_fetch "camera" "activated"`
    echo "camera activated #$camera_activated"
    if [ $camera_activated -eq 1 ]; then
        echo "camera activated"
        module_count=`script_fetch "camera" "module_count"`
        if [ $module_count -gt 0 ]; then
            for i in $(seq $module_count); do
                key_name="module"$i"_path"
                module_path=`script_fetch "camera" "$key_name"`
                if [ -n "$module_path" ]; then
                    insmod "$module_path"
                    if [ $? -ne 0 ]; then
                        echo "insmod $module_path failed"
                        break 2
                    fi
                fi
            done
        fi
    else
        echo "camera not activated"
        break
    fi

    echo "camera module insmod done"
    touch /tmp/camera_insmod_done
done

# fix some driver download firmware from /system/vendor/modules.
# android style
if [ ! -d /system/vendor/ ]; then
    mkdir -p /system/vendor/
    ln -s /lib/modules/3.0.8+/ /system/vendor/modules
fi

# run dragonboard core process
core &
