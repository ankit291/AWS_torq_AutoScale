#!/bin/bash

rm -f OFFLINE_NODES DOWN_NODES FREE_RUNNING_NODES CURR_NODES_WIT_CNT nod_det nod_cnt_available null_nodes to_scale_dwn_node aFile_block_Job_tim YES_OR_NOT NOT_RUNNING_MIN_NODE RUNNING_NODES_TYPE sort_nod_det node_types  ###deleting existed files , which will create every time when this script going to execute

. /root/ANKIT/Scale.properties

echo "First we are goint to define variables , which will not required to change in entire process .
		"
### This below query used to get total types of nodes in our environment.
pbsnodes | grep -B 3 "state = " | grep -v "power_state\|\-\-\|mom_" | grep -v '^$' | awk 'NR%2{printf "%s ",$0;next;}1'| awk '{print $1}' | awk -F"-" '{print $1}' > node_types

##Below command get average Gcurrent jobs per node.


AVG_JOBS_PER_NODE=`echo $(($(qstat -q | tail -1 | grep -Eo '[[:digit:]]{1,8}' | head -1)/$(pbsnodes -l free | grep -v torquectrl | wc -l)))`

##Below command is used to get current total jobs on all nodes
CURRENT_TOTAL_JOBS=`/opt/moab/bin/showq | tail -2 | head -1 | awk '{print $3}'`

##Below command will get total type of nodes available in our torque environment(except torquectr1).
INDX_NODE=`echo ${#Node_Type[@]}`

## Below command used to get Total jobs in queue or blocked jobs in torque envorinment.
QUEUE_JOB=`/opt/moab/bin/showq | grep " blocked jobs" | awk '{print $1}'`


Job_Per_Node=`qstat -n -e  | grep torque...- | sort  | uniq -c`   ###############

## This is used to get queue count on our important queues.
for i in `qstat |awk 'length($2) == 16 { print $1"   "$2 }' | grep SC | awk -F"." '{print $1}' |grep -v "\[\|-" | head`; do tracejob $i | grep "exec_host=" | awk -F"=" '{print $10}'| awk '{print $1}' >> SC_jobs; done
if [ -s SC_jobs ];
then
SC_job_cnt=`cat SC_jobs | wc -l`
echo `cat SC_jobs` | sed -e 's/\n//g' | sed 's/ /\|/g' >SC_Jobs_refr
var_SC_job=`cat SC_Jobs_refr`
else
var_SC_job='NOTHING_HERE'
fi
#queue get to compare usermart count

USERMART_Q_cnt=`qstat -q | grep -i USERMARTQ | awk 'BEGIN {sum=0} ; {sum+=$7} END {print sum}'`

CUSTOMQ_Q_cnt=`qstat -q | grep -i CUSTOMQ | awk 'BEGIN {sum=0} ; {sum+=$7} END {print sum}'`

WORKBENCHQ_Q_cnt=`qstat -q | grep -i WORKBENCHQ | awk 'BEGIN {sum=0} ; {sum+=$7} END {print sum}'`

PIPELINEq=`qstat -q | grep -i pipelineQ | awk 'BEGIN {sum=0} ; {sum+=$7} END {print sum}'`

echo "There is total $INDX_NODE types of nodes are available in out Torque environment(except torquectr1).
	"

######### Below commands are getiind details of nodes state , running , down or offline

pbsnodes | grep -B 3 "state = " | grep -v "power_state\|\-\-\|mom_" | grep -v '^$' | awk 'NR%2{printf "%s ",$0;next;}1' |grep -v torquectrl | grep offline | grep -v down | awk '{print $1}' > OFFLINE_NODES
pbsnodes | grep -B 3 "state = " | grep -v "power_state\|\-\-\|mom_" | grep -v '^$' | awk 'NR%2{printf "%s ",$0;next;}1'| grep -v torquectrl |grep -i down | awk '{print $1}' > DOWN_NODES
pbsnodes | grep -B 3 "state = " | grep -v "power_state\|\-\-\|mom_" | grep -v '^$' | awk 'NR%2{printf "%s ",$0;next;}1'| grep -v torquectrl |grep -i free | awk '{print $1}' > FREE_RUNNING_NODES

pbsnodes | grep -B 3 "state = " | grep -v "power_state\|\-\-\|mom_" | grep -v '^$' | awk 'NR%2{printf "%s ",$0;next;}1'| grep -v torquectrl |grep -i free | awk '{print $1}'| sort | uniq -c >CURR_NODES_WIT_CNT

offline_cnt=`cat OFFLINE_NODES | wc -l`
free_cnt=`cat FREE_RUNNING_NODES | wc -l`
################# NOw we are going to check scaleup required or not
### Below condition is used to check that SCALE UP is required or not . all variables described in property file.
job_cnt_to_be=$(($free_cnt * $jbpr_nod))
totl_que_on_curr_nod=$(($free_cnt * $CURR_AVG_QUE_PER_NOD))

echo " $AVG_JOBS_PER_NODE -ge $MAX_AVG_JOB_PER_NODE , $CURRENT_TOTAL_JOBS -ge $job_cnt_to_be , $QUEUE_JOB -ge $totl_que_on_curr_nod $USERMART_Q_cnt -lt $Usr_mart_condi ORRR $USERMART_Q_cnt -lt $SUM_OF_QUE , $AVG_JOBS_PER_NODE chk $MAX_AVG_JOB_PER_NODE ORRR $USERMART_Q_cnt chk $USERMARTQ_que_min , $AVG_JOBS_PER_NODE chk $MAX_AVG_JOB_PER_NODE , $WORKBENCHQ_Q_cnt chk $WRKBN_SUM_OF_QUE , $PIPELINEq -ge $PIPELINEQ_Q"


if [[ $AVG_JOBS_PER_NODE -ge $MAX_AVG_JOB_PER_NODE && $CURRENT_TOTAL_JOBS -ge $job_cnt_to_be && $QUEUE_JOB -ge $totl_que_on_curr_nod && $USERMART_Q_cnt -lt $Usr_mart_condi ]] || [[ $USERMART_Q_cnt -ge $SUM_OF_QUE && $AVG_JOBS_PER_NODE -ge $MAX_AVG_JOB_PER_NODE ]] || [[ $USERMART_Q_cnt -ge $USERMARTQ_que_min && $AVG_JOBS_PER_NODE -ge $MAX_AVG_JOB_PER_NODE && $WORKBENCHQ_Q_cnt -ge $WRKBN_SUM_OF_QUE ]] || [[ $PIPELINEq -ge $PIPELINEQ_Q ]]

then

		echo "We required to sclae UP , because as per our conditions our nodes are needs to increase.
		"
		cntt=`pbsnodes | grep -B 3 "state = " | grep -v "power_state\|\-\-\|mom_" | grep -v '^$' | awk 'NR%2{printf "%s ",$0;next;}1'| grep -i free | wc -l`
		if [ $cntt -ge 21 ];

		then

			echo "All nodes are in free running state , no extra nodes available to scale up"

		else

			if [ -s OFFLINE_NODES ];
			then

				echo "below are offline nodes available"

				cat OFFLINE_NODES

				Off_line_to_UP=`cat OFFLINE_NODES | head -1`

				echo "nodes $Off_line_to_UP is available to change from offline state Running."
				echo "We are facing load increased in out torque environment and we have currently some nodes in offline state , So we are going to change their state to online."
				Instance_ID=`grep $Off_line_to_UP /root/ANKIT/Node_details | awk '{print $2}'`
				rregion=`grep $Off_line_to_UP /root/ANKIT/Node_details | awk '{print $3}'`
				pbsnodes -c  $Off_line_to_UP
cat > outchk <<EOL
Hi Team,

We Just change state from offline to online of Torque node $Off_line_to_UP .

Regards
Ankit Tyagi
3Pillar Global
EOL
mail -s "Torque Node State chng to IN" user.name@gmail.com < outchk

#################################	SCALE UP ######################
elif  [ $cntt -lt $node_cnt_for_up ];
then

echo `cat FREE_RUNNING_NODES` | sed -e 's/\n//g' | sed 's/ /|/g' > online_node_in_seperated
echo `cat OFFLINE_NODES` | sed -e 's/\n//g' | sed 's/ /|/g' > offline_node_in_seperated

				in_var_onlin_nod=`cat online_node_in_seperated`
				in_var_offlin_nod=`cat offline_node_in_seperated`


egrep -v `echo $in_var_onlin_nod` ALL_NODES_NAMES > AA_1
egrep -v `echo $in_var_onlin_nod` AA_1 > AA_2

                                node_going_scale=`cat AA_2 | head -1`

				echo "Now we are goint to scale up to node $node_going_scale . "
				instance_ID=`grep $node_going_scale /root/ANKIT/Node_details | awk '{print $2}'`
				Region=`grep $node_going_scale  /root/ANKIT/Node_details | awk '{print $3}'`
				aws ec2 start-instances --instance-ids $instance_ID --region $Region
				sleep 180
				echo "$node_going_scale has been started with instance ID $instance_ID"
				nod_stats=`pbsnodes | grep -B 3 "state = " | grep -v "power_state\|\-\-\|mom_" | grep -v '^$' | awk 'NR%2{printf "%s ",$0;next;}1'| awk '{print $1}' | grep -i offline | grep -v -i down | grep $node_going_scale`
				pbsnodes -c $node_going_scale
				sleep 10
cat > outchk <<EOL
Hi Team,

We Just Scale up the Torque node $node_going_scale .

Regards
Ankit Tyagi
3Pillar Global
EOL

mail -s "Torque Node Scale UP detail" user.name@gmail.com < outchk

			fi
		fi
####################################		ALL DOWN PROCESS		##########################
		>val_1_least
		for i in ${Node_Type[*]}
		do
			grep $i CURR_NODES_WIT_CNT >value_least1
			echo 1 >>val_1_least
		done
		ALL_MIN_NODE_CNT=`cat val_1_least | awk 'BEGIN {sum=0} ; {sum+=$1} END {print sum}'`     #####check

elif [[ $AVG_JOBS_PER_NODE -le $MINIMUM_AVG_JOBS_PER_NODE && $CURRENT_TOTAL_JOBS -le $MIN_CURR_TOTL_JOB && $QUEUE_JOB -le $MIN_QUE_JOB && $free_cnt -gt 1 && $offline_cnt -le 2 && $SC_job_cnt -lt $free_cnt ]]

		then
		egrep -v `echo $var_SC_job` FREE_RUNNING_NODES > LEFT_TO_DWN
		echo "current Offline node counts ="$offline_cnt
		echo "number of nodes available="$free_cnt
		#####
		echo "conditions value for scale down"
		echo "min avg jobs on nodes = $AVG_JOBS_PER_NODE (here wa take 25 jobs per node to scale down)"
		echo "As per our conditional parameters conditions matched to scale down our nodes ,No need of many nodes in online state."
		NODE_TO_DOWN=`cat LEFT_TO_DWN | grep -v -i $IGNORE_NODES | awk -F"-" '{print $1}' | sort | uniq -c | awk '{if($1> $MAX_NOD_CNT_TO_SCAL_DWN) print $2}' | head -1`
		NODE_NAME=`grep $NODE_TO_DOWN FREE_RUNNING_NODES | head -1`
		echo "We are going to scale down node name \"$NODE_NAME\""
		Instance_ID=`grep $NODE_NAME /root/ANKIT/Node_details | awk '{print $2}'`
		rregion=`grep $NODE_NAME /root/ANKIT/Node_details | awk '{print $3}'`
		pbsnodes -o $NODE_NAME
cat > outchk <<EOL
Hi Team,

We Just Scale down the Torque node $NODE_NAME , and change state from online to offline  !!

Regards
Ankit Tyagi
3Pillar Global
EOL

		mail -s "Torque Node State Chng Online to Offline" user.name@gmail.com < outchk
else

		echo "System is running OK ... There isn't any need to scale up or down"
fi


############## Here we delete blocked jobs, Which are pending from last 100 hours  ########################

/opt/moab/bin/showq | sed -n '/blocked jobs\-\-/,/blocked jobs/p' | grep -v -i "blocked jobs\|JOBID\|^$" | awk '{print $1" "$7" "$8" "$9}' > aFile_block_Job_tim

BEFOR=`date | awk '{print $2" "$3" "$4}' | date --date "${MAX_HOURS_TO_KIL_BLOK_JOB} hour ago" "+%Y%m%d%H%M"`

if [ -s aFile_block_Job_tim ]; then

	cat aFile_block_Job_tim | while read line
	do

        DatF=`echo $line | awk '{print $2" "$3" "$4}'`
        Format_date=`date --date "$DatF" "+%Y%m%d%H%M"`

                if [ $BEFOR -ge $Format_date ]
                then
                        JobId=`echo $line | awk '{print $1}'`
                        echo "

	Please give here commands to remove job of jobId $JobId . Because this is in queue from more than ${MAX_HOURS_TO_KIL_BLOK_JOB} hours"
                        echo $BEFOR " > " $Format_date
                fi
	done
else
	echo "There isn't any job in queue from more than $MAX_HOURS_TO_KIL_BLOK_JOB hours"
fi

###################### REMOVING ALL FILES CREATED
rm -f SC_Jobs_refr SC_jobs AA_1 AA_2 LEFT_TO_DWN online_node_in_seperated All_nodes_with_job_details chk_job_cnt_On_offline_node outchk OFFLINE_NODES DOWN_NODES FREE_RUNNING_NODES CURR_NODES_WIT_CNT nod_det nod_cnt_available null_nodes to_scale_dwn_node aFile_block_Job_tim YES_OR_NOT NOT_RUNNING_MIN_NODE RUNNING_NODES_TYPE sort_nod_det node_types running_node_cnt_details sort_running_node_cnt_details min_avail_nodes to_scale_UP_node value_least1 val_1_least loggg offline_node_in_seperated

qstat -q
