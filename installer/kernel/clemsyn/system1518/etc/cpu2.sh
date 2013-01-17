#!/bin/sh -x
#This is normal mode!
logi ()
{
  /system/bin/log -t $LOG_TAG -p i "$LOG_NAME $@"
}
logi "echo 0 > system_mode"
echo 0 > /sys/module/cpu_tegra/parameters/system_mode
logi "echo 1300 > core_cap_level"
echo 1300 > /sys/kernel/tegra_cap/core_cap_level
logi "echo 0 > core_cap_state"
echo 0 > /sys/kernel/tegra_cap/core_cap_state
logi "echo 0 > enable_3d_scaling"
echo 0 > /sys/devices/platform/tegra_grhost/enable_3d_scaling
logi "echo 10> mp_overhead"
echo 10 > /sys/module/cpu_tegra3/parameters/mp_overhead
logi "echo 9999999> pwr_cap_limit_1"
echo 9999999 > /sys/module/cpu_tegra/parameters/pwr_cap_limit_1
logi "echo 9999999> pwr_cap_limit_2"
echo 9999999 > /sys/module/cpu_tegra/parameters/pwr_cap_limit_2
logi "echo 9999999> pwr_cap_limit_3"
echo 9999999 > /sys/module/cpu_tegra/parameters/pwr_cap_limit_3
logi "echo 9999999> pwr_cap_limit_4"
echo 9999999 > /sys/module/cpu_tegra/parameters/pwr_cap_limit_4
logi "setprop power.saving.mode 1"
setprop power.saving.mode 1
logi "setprop persist.tegra.NV_FPSLIMIT 0"
setprop persist.tegra.NV_FPSLIMIT 0
logi "setprop persist.sys.NV_FPSLIMIT 0"
setprop persist.sys.NV_FPSLIMIT 0
logi "setprop persist.sys.NV_POWERMODE 1"
setprop persist.sys.NV_POWERMODE 1
