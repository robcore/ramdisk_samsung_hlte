#!/system/bin/sh

# Modes
echo 4 > /sys/module/lpm_levels/enable_low_power/l2
echo 1 > /sys/module/msm_pm/modes/cpu0/power_collapse/suspend_enabled
echo 1 > /sys/module/msm_pm/modes/cpu1/power_collapse/suspend_enabled
echo 1 > /sys/module/msm_pm/modes/cpu2/power_collapse/suspend_enabled
echo 1 > /sys/module/msm_pm/modes/cpu3/power_collapse/suspend_enabled
echo 1 > /sys/module/msm_pm/modes/cpu0/power_collapse/idle_enabled
echo 1 > /sys/module/msm_pm/modes/cpu1/power_collapse/idle_enabled
echo 1 > /sys/module/msm_pm/modes/cpu2/power_collapse/idle_enabled
echo 1 > /sys/module/msm_pm/modes/cpu3/power_collapse/idle_enabled
echo 1 > /sys/module/msm_pm/modes/cpu0/standalone_power_collapse/suspend_enabled
echo 1 > /sys/module/msm_pm/modes/cpu1/standalone_power_collapse/suspend_enabled
echo 1 > /sys/module/msm_pm/modes/cpu2/standalone_power_collapse/suspend_enabled
echo 1 > /sys/module/msm_pm/modes/cpu3/standalone_power_collapse/suspend_enabled
echo 1 > /sys/module/msm_pm/modes/cpu0/standalone_power_collapse/idle_enabled
echo 1 > /sys/module/msm_pm/modes/cpu1/standalone_power_collapse/idle_enabled
echo 1 > /sys/module/msm_pm/modes/cpu2/standalone_power_collapse/idle_enabled
echo 1 > /sys/module/msm_pm/modes/cpu3/standalone_power_collapse/idle_enabled
echo 1 > /sys/module/msm_pm/modes/cpu0/retention/idle_enabled
echo 1 > /sys/module/msm_pm/modes/cpu1/retention/idle_enabled
echo 1 > /sys/module/msm_pm/modes/cpu2/retention/idle_enabled
echo 1 > /sys/module/msm_pm/modes/cpu3/retention/idle_enabled

# Storage
echo deadline > /sys/block/mmcblk0/queue/scheduler
echo 512 > /sys/block/mmcblk0/queue/read_ahead_kb
echo 0 > /sys/block/mmcblk0/queue/add_random
if [ -d /sys/block/mmcblk1 ]; then
echo deadline > /sys/block/mmcblk1/queue/scheduler
echo 512 > /sys/block/mmcblk1/queue/read_ahead_kb
echo 0 > /sys/block/mmcblk1/queue/add_random; fi

# Init.d
for file in /system/etc/init.d/*; do
if [ -x $file ]; then
sh $file; fi; done

# Misc
setprop net.hostname Note3
