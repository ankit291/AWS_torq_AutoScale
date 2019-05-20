#!/bin/bash

log_tim=`date --date 'today' '+%Y_%m_%d_%H_%M'`

cd /root/ANKIT

sh /root/ANKIT/TORQUE_Auto_scal.sh > /root/ANKIT/Logs/log_detail_$log_tim 2>&1
