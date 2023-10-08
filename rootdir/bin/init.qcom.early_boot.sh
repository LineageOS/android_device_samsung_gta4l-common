#! /vendor/bin/sh

# Copyright (c) 2012-2013,2016,2018-2020 The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

export PATH=/vendor/bin

# Set platform variables
if [ -f /sys/devices/soc0/hw_platform ]; then
    soc_hwplatform=`cat /sys/devices/soc0/hw_platform` 2> /dev/null
else
    soc_hwplatform=`cat /sys/devices/system/soc/soc0/hw_platform` 2> /dev/null
fi
if [ -f /sys/devices/soc0/soc_id ]; then
    soc_hwid=`cat /sys/devices/soc0/soc_id` 2> /dev/null
else
    soc_hwid=`cat /sys/devices/system/soc/soc0/id` 2> /dev/null
fi
if [ -f /sys/devices/soc0/platform_version ]; then
    soc_hwver=`cat /sys/devices/soc0/platform_version` 2> /dev/null
else
    soc_hwver=`cat /sys/devices/system/soc/soc0/platform_version` 2> /dev/null
fi

if [ -f /sys/class/drm/card0-DSI-1/modes ]; then
    echo "detect" > /sys/class/drm/card0-DSI-1/status
    mode_file=/sys/class/drm/card0-DSI-1/modes
    while read line; do
        fb_width=${line%%x*};
        break;
    done < $mode_file
elif [ -f /sys/class/graphics/fb0/virtual_size ]; then
    res=`cat /sys/class/graphics/fb0/virtual_size` 2> /dev/null
    fb_width=${res%,*}
fi

log -t BOOT -p i "MSM target '$1', SoC '$soc_hwplatform', HwID '$soc_hwid', SoC ver '$soc_hwver'"

#For drm based display driver
vbfile=/sys/module/drm/parameters/vblankoffdelay
if [ -w $vbfile ]; then
    echo -1 >  $vbfile
else
    log -t DRM_BOOT -p w "file: '$vbfile' or perms doesn't exist"
fi

function set_density_by_fb() {
    #put default density based on width
    if [ -z $fb_width ]; then
        setprop vendor.display.lcd_density 320
    else
        if [ $fb_width -ge 1600 ]; then
           setprop vendor.display.lcd_density 640
        elif [ $fb_width -ge 1440 ]; then
           setprop vendor.display.lcd_density 560
        elif [ $fb_width -ge 1080 ]; then
           setprop vendor.display.lcd_density 480
        elif [ $fb_width -ge 720 ]; then
           setprop vendor.display.lcd_density 320 #for 720X1280 resolution
        elif [ $fb_width -ge 480 ]; then
            setprop vendor.display.lcd_density 240 #for 480X854 QRD resolution
        else
            setprop vendor.display.lcd_density 160
        fi
    fi
}

target=`getprop ro.board.platform`
case "$target" in
    "bengal")
        case "$soc_hwid" in
            441|473)
                # 441 is for scuba and 473 for scuba iot qcm
                setprop vendor.fastrpc.disable.cdsprpcd.daemon 1
                setprop vendor.media.target.version 2
                setprop vendor.gralloc.disable_ubwc 1
                setprop vendor.display.enhance_idle_time 1
                setprop vendor.netflix.bsp_rev ""
                # 196609 is decimal for 0x30001 to report version 3.1
                setprop vendor.opengles.version 196609
                sku_ver=`cat /sys/devices/platform/soc/5a00000.qcom,vidc1/sku_version` 2> /dev/null
                if [ $sku_ver -eq 1 ]; then
                   setprop vendor.media.target.version 3
                fi
                ;;
            471|474)
                # 471 is for scuba APQ and 474 for scuba iot qcs
                setprop vendor.fastrpc.disable.cdsprpcd.daemon 1
                setprop vendor.gralloc.disable_ubwc 1
                setprop vendor.display.enhance_idle_time 1
                setprop vendor.netflix.bsp_rev ""
                ;;
            *)
                # default case is for bengal
                setprop vendor.netflix.bsp_rev "Q6115-31409-1"
                ;;
        esac
        ;;
esac

#set default lcd density
#Since lcd density has read only
#property, it will not overwrite previous set
#property if any target is setting forcefully.
set_density_by_fb

# Setup display nodes & permissions
# HDMI can be fb1 or fb2
# Loop through the sysfs nodes and determine
# the HDMI(dtv panel)

function set_perms() {
    #Usage set_perms <filename> <ownership> <permission>
    chown -h $2 $1
    chmod $3 $1
}

# allow system_graphics group to access pmic secure_mode node
set_perms /sys/class/lcd_bias/secure_mode system.graphics 0660

boot_reason=`cat /proc/sys/kernel/boot_reason`
reboot_reason=`getprop ro.boot.alarmboot`
if [ "$boot_reason" = "3" ] || [ "$reboot_reason" = "true" ]; then
    setprop ro.vendor.alarm_boot true
else
    setprop ro.vendor.alarm_boot false
fi

# copy GPU frequencies to vendor property
if [ -f /sys/class/kgsl/kgsl-3d0/gpu_available_frequencies ]; then
    gpu_freq=`cat /sys/class/kgsl/kgsl-3d0/gpu_available_frequencies` 2> /dev/null
    setprop vendor.gpu.available_frequencies "$gpu_freq"
fi
