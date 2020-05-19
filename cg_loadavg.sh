# CGROUP_PATH=$1
CGROUP_PATH="/sys/fs/cgroup/cpu/docker/46d1ae1c098bd625e331852c50fe8e7aa7b2ef91e1b6dbd96c9538f2515d88b3"

# $1: process pid
get_process_state() {
    cat /proc/$1/status | sed -n 's/State:\t\([A-Z]\)/\1/p' | cut -f1 -d ' '
}

# $1: path
get_number_r_and_d_processes() {
    count=0
    PIDS=$(cat ${CGROUP_PATH}/tasks)
    for task_pid in ${PIDS}; do
        if [ -f /proc/${task_pid}/status ]; then
          STATE=$(get_process_state ${task_pid})
          if [ ${STATE} == "R" ] || [ ${STATE} == "D" ]; then
              count=$(($count + 1))
          fi
        fi
    done
    return ${count}
}

FSHIFT=11
FIXED_1=$((1 << $FSHIFT))
HZ=$(getconf CLK_TCK)
LOAD_FREQ=$((5*${HZ}))
EXP_1=1884
difference=$(($FIXED_1 - $EXP_1))
E=2.718281828459045 

calc_load() {
    load=$1
    running_processes=$2
    # load=$(echo "$load*$EXP_1+$running_processes*$difference" | bc)
    # load=$(echo "$load / $E + $running_processes * (1 - 1/$E)" | bc)
    load="$(python -c "from math import exp; print($load / exp(1) + $running_processes * (1 - 1/exp(1)))")"
    echo "l = $load"
    # load=$(($load >> $FSHIFT))
    return ${load}
}

load="0"
while true; do
    get_number_r_and_d_processes ${CGROUP_PATH}
    running_processes=$?
    # calc_load ${load} ${running_processes}
    # load=$?
    load="$(python -c "from math import exp; print($load / exp(1) + $running_processes * (1 - 1/exp(1)))")"
    # echo "${load}"
    echo "${load},$(cat /proc/loadavg | cut -f1 -d ' ')"
    sleep 1
done
