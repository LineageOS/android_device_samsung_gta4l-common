#! /vendor/bin/sh

# Copyright (c) 2012-2013, 2016-2020, The Linux Foundation. All rights reserved.
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

# Core control is temporarily disabled till bring up
echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable
echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
# Core control parameters on big
echo 40 > /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres
echo 60 > /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres
echo 100 > /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms
echo 4 > /sys/devices/system/cpu/cpu4/core_ctl/task_thres

# Setting b.L scheduler parameters
echo 67 > /proc/sys/kernel/sched_downmigrate
echo 77 > /proc/sys/kernel/sched_upmigrate
echo 85 > /proc/sys/kernel/sched_group_downmigrate
echo 100 > /proc/sys/kernel/sched_group_upmigrate

# cpuset settings
echo 0-3 > /dev/cpuset/background/cpus
echo 0-3 > /dev/cpuset/system-background/cpus


# configure governor settings for little cluster
echo "schedutil" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us
echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us
echo 1305600 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_freq
echo 614400 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/rtg_boost_freq

# configure governor settings for big cluster
echo "schedutil" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
echo 0 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/up_rate_limit_us
echo 0 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/down_rate_limit_us
echo 1401600 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/hispeed_freq
echo 1056000 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
echo 0 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/rtg_boost_freq

echo "0:0" > /sys/devices/system/cpu/cpu_boost/input_boost_freq
echo 80 > /sys/devices/system/cpu/cpu_boost/input_boost_ms

echo 1 > /proc/sys/kernel/sched_walt_rotate_big_tasks

# sched_load_boost as -6 is equivalent to target load as 85. It is per cpu tunable.
echo -6 >  /sys/devices/system/cpu/cpu0/sched_load_boost
echo -6 >  /sys/devices/system/cpu/cpu1/sched_load_boost
echo -6 >  /sys/devices/system/cpu/cpu2/sched_load_boost
echo -6 >  /sys/devices/system/cpu/cpu3/sched_load_boost
echo -6 >  /sys/devices/system/cpu/cpu4/sched_load_boost
echo -6 >  /sys/devices/system/cpu/cpu5/sched_load_boost
echo -6 >  /sys/devices/system/cpu/cpu6/sched_load_boost
echo -6 >  /sys/devices/system/cpu/cpu7/sched_load_boost
echo 85 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_load
echo 85 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/hispeed_load

#+bug707458 zhulinqing.wt,add,20211213,touch boost
echo "0:1804800 1:1804800 2:1804800 3:1804800 4:2016000 5:2016000 6:2016000 7:2016000" > /sys/devices/system/cpu/cpu_boost/input_boost_freq
echo 120 > /sys/devices/system/cpu/cpu_boost/input_boost_ms
echo 1 > /sys/devices/system/cpu/cpu_boost/sched_boost_on_input
#-bug707458 zhulinqing.wt,add,20211213,touch boost

# Enable bus-dcvs
ddr_type=`od -An -tx /proc/device-tree/memory/ddr_device_type`
ddr_type4="07"
ddr_type3="05"

for device in /sys/devices/platform/soc
do
    for cpubw in $device/*cpu-cpu-ddr-bw/devfreq/*cpu-cpu-ddr-bw
    do
        echo "bw_hwmon" > $cpubw/governor
        echo 50 > $cpubw/polling_interval
        echo 762 > $cpubw/min_freq
        if [ ${ddr_type:4:2} == $ddr_type4 ]; then
            # LPDDR4
            echo "2288 3440 4173 5195 5859 7759 10322 11863 13763" > $cpubw/bw_hwmon/mbps_zones
            echo 85 > $cpubw/bw_hwmon/io_percent
        fi
        if [ ${ddr_type:4:2} == $ddr_type3 ]; then
            # LPDDR3
            echo "1525 3440 5195 5859 7102" > $cpubw/bw_hwmon/mbps_zones
            echo 34 > $cpubw/bw_hwmon/io_percent
        fi
        echo 4 > $cpubw/bw_hwmon/sample_ms
        echo 90 > $cpubw/bw_hwmon/decay_rate
        echo 190 > $cpubw/bw_hwmon/bw_step
        echo 20 > $cpubw/bw_hwmon/hist_memory
        echo 0 > $cpubw/bw_hwmon/hyst_length
        echo 80 > $cpubw/bw_hwmon/down_thres
        echo 0 > $cpubw/bw_hwmon/guard_band_mbps
        echo 250 > $cpubw/bw_hwmon/up_scale
        echo 1600 > $cpubw/bw_hwmon/idle_mbps
    done

done
# memlat specific settings are moved to seperate file under
# device/target specific folder
setprop vendor.dcvs.prop 1

# colcoation v3 disabled
echo 0 > /proc/sys/kernel/sched_min_task_util_for_boost
echo 0 > /proc/sys/kernel/sched_min_task_util_for_colocation

# Turn off scheduler boost at the end
echo 0 > /proc/sys/kernel/sched_boost

# Turn on sleep modes
echo 0 > /sys/module/lpm_levels/parameters/sleep_disabled

setprop vendor.post_boot.parsed 1

# Let kernel know our image version/variant/crm_version
if [ -f /sys/devices/soc0/select_image ]; then
    image_version="10:"
    image_version+=`getprop ro.build.id`
    image_version+=":"
    image_version+=`getprop ro.build.version.incremental`
    image_variant=`getprop ro.product.name`
    image_variant+="-"
    image_variant+=`getprop ro.build.type`
    oem_version=`getprop ro.build.version.codename`
    echo 10 > /sys/devices/soc0/select_image
    echo $image_version > /sys/devices/soc0/image_version
    echo $image_variant > /sys/devices/soc0/image_variant
    echo $oem_version > /sys/devices/soc0/image_crm_version
fi

# Change console log level as per console config property
console_config=`getprop persist.vendor.console.silent.config`
case "$console_config" in
    "1")
        echo "Enable console config to $console_config"
        echo 0 > /proc/sys/kernel/printk
        ;;
    *)
        echo "Enable console config to $console_config"
        ;;
esac

# Parse misc partition path and set property
misc_link=$(ls -l /dev/block/bootdevice/by-name/misc)
real_path=${misc_link##*>}
setprop persist.vendor.mmi.misc_dev_path $real_path
