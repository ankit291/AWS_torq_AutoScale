#!/bin/bash


cd /root/ANKIT

pbsnodes | grep -B 3 "state = " | grep -v "power_state\|\-\-\|mom_" | grep -v '^$' | awk 'NR%2{printf "%s ",$0;next;}1' | grep "state = offline" | awk '{print $1}' > Curr_Off_nods


if [ ! -s Curr_Off_nods ];
then

			echo "There isn't any offline node available in cluster to change their state"

else

qstat -n -e  | grep torque...- | sort  | uniq -c | awk '{print $1"  "$2".cointreau.local"}' | awk '{print$1","$2}' > Nod_wth_Jobs

qstat -n -e  | grep torque...- | sort | awk '{print $1".cointreau.local"}' > new_Nod_wth_Jobs

cat Nod_wth_Jobs
echo "
"
for nod in `cat Curr_Off_nods`

do

echo $nod
nod_detl=`grep -i "$nod" /root/ANKIT/new_Nod_wth_Jobs | sort | uniq -c`
nod_to_dwn=`grep -i "$nod" /root/ANKIT/new_Nod_wth_Jobs | wc -l`

		if [ $nod_to_dwn == "0" ]
		then

		Instance_ID=`grep $nod /root/ANKIT/Node_details | awk '{print $2}'`
		rregion=`grep $nod /root/ANKIT/Node_details | awk '{print $3}'`

		echo "We can change state from offline to Down for Torque node $nod !!"

		aws ec2 stop-instances --instance-ids $Instance_ID --region $rregion
cat > outchk <<EOL
Hi Team,

Now we are going to change state for offline node $nod to down state . Because there isn't any jobs avaialable on this offline node .

$nod_detl

Regards
Ankit Tyagi
3Pillar Global
EOL

                mail -s "Offline to Down state for $nod" user.name@gmail.com < outchk
		else
cat > outchk <<EOL
Hi Team,

$nod have still some jobs are available , below are available job details.

$nod_detl

Regards
Ankit Tyagi
3Pillar Global
EOL

                mail -s "Offline to Down state for $nod" user.name@gmail.com < outchk

		fi
done
fi

rm -rf Curr_Off_nods outchk new_Nod_wth_Jobs Nod_wth_Jobs
