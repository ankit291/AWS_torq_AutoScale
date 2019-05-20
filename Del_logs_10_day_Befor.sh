#!/bin/bash

Check_date=`date --date '10 day ago' '+%Y_%m_%d'`

rm /root/ANKIT/Logs/*$Check_date*
