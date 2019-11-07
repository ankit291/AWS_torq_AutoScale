#!/bin/bash

log_tim=`date --date 'today' '+%Y_%m_%d_%H_%M'`

cd /path/scripts

sh /path/scripts/TORQUE_Auto_scal.sh > /path/of/logs/log_detail_$log_tim 2>&1
