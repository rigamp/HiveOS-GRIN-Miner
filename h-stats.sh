#!/usr/bin/env bash

#######################
# Functions
#######################


get_cards_hashes(){
	# hs is global
	hs=''
	local _N_COUNTER=0
	local _A_COUNTER=0
	for (( i=0; i < ${GPU_COUNT}; i++ )); do
		hs[$i]=''
	 	local _BRAND=`echo $gpus | jq -r ".[$(echo $i)].brand"`
	 	local _NAME=`echo $gpus | jq -r ".[$(echo $i)].name"`
		local _GPU=''
		if [ "$_BRAND" == "amd" ]
		then 
			_GPU=`echo $_A_COUNTER`
			 _NAME='Ellesmere'
			(( _A_COUNTER=_A_COUNTER+1))
		else 
			_GPU=`echo $_N_COUNTER`
			(( _N_COUNTER=_N_COUNTER+1))
		fi
								
		local GHS=`tail -n 30 $LOG_NAME | grep -a "Device $(echo $_GPU) ($(echo $_NAME)" | tail -n1 | awk 'match($0, /Graphs per second: \.?[0-9]+.[0-9]+/) {print substr($0, RSTART, RLENGTH)}'|  cut -d " " -f4`
                if [ -z $GHS ] && [ "$_BRAND" == "amd" ]
                then
                        GHS=`tail -n 30 $LOG_NAME | grep -a "Device $(echo $_GPU) (gfx" | tail -n1 | awk 'match($0, /Graphs per second: \.?[0-9]+.[0-9]+/) {print substr($0, RSTART, RLENGTH)}'|  cut -d " " -f4`
                fi
		hs[$i]=`echo $GHS`
	done
}

get_cards_temp(){
	echo $(jq '.temp' <<< $gpu_stats)
}

get_cards_fan(){
	echo $(jq '.fan' <<< $gpu_stats)
}

get_miner_shares_ac(){
        local ac=`cat $CUSTOM_LOG_BASENAME.log | grep -a "stale" | tail -n 1 | awk 'match($0, /accepted":[0-9]+/) {print substr($0, RSTART, RLENGTH)}'| cut -d ":" -f2`
        echo $ac
}

get_miner_shares_rj(){
        local rj=`cat $CUSTOM_LOG_BASENAME.log | grep -a "stale" | tail -n 1 | awk 'match($0, /rejected":[0-9]+/) {print substr($0, RSTART, RLENGTH)}'| cut -d ":" -f2`
        echo $rj
}

get_miner_uptime(){
	local tmp=$(ps -p `pgrep $CUSTOM_NAME` -o lstart=)
	local start=$(date +%s -d "$tmp")
        local now=$(date +%s)
        echo $((now - start))
}

get_total_hashes(){
        # khs is global
        local MHS=`tail -n50 $LOG_NAME | grep -a "Mining: Cuck(at)oo at " | tail -n1`
	echo $MHS | cut -d " " -f8 | awk '{s+=$1} END {print s/1000}'
}



#######################
# MAIN script body
#######################

. /hive/miners/custom/$CUSTOM_MINER/h-manifest.conf
local LOG_NAME="$CUSTOM_LOG_BASENAME.log"

gpus=`gpu-detect listjson`
GPU_COUNT=`echo $gpus | jq 'length'`

# Calc log freshness by logfile timestamp since no time entries in log
lastUpdate="$(stat -c %Y $LOG_NAME)"
now="$(date +%s)"
local diffTime="${now}"
let diffTime="${now}-${lastUpdate}"
local maxDelay=60

# If log is fresh the calc miner stats or set to null if not
if [ "$diffTime" -lt "$maxDelay" ]; then
	local hs=
	get_cards_hashes			# hashes array
	local hs_units='hs'			# hashes units
	local temp=$(get_cards_temp)		# cards temp
	local fan=$(get_cards_fan)		# cards fan
	local uptime=$(get_miner_uptime)	# miner uptime
	local algo="grin cuckoo"		# algo

	# A/R shares by pool
	local ac=$(get_miner_shares_ac)
	local rj=$(get_miner_shares_rj)

	# make JSON
	stats=$(jq -nc \
				--argjson hs "`echo ${hs[@]} | tr " " "\n" | jq -cs '.'`" \
				--arg hs_units "$hs_units" \
				--argjson temp "$temp" \
				--argjson fan "$fan" \
				--arg uptime "$uptime" \
				--arg ac "$ac" --arg rj "$rj" \
				--arg algo "$algo" \
				'{$hs, $hs_units, $temp, $fan, $uptime,ar: [$ac, $rj], $algo}')
	# total hashrate in khs
	khs=$(get_total_hashes)
else
	stats=""
	khs=0
fi

# debug output


#echo temp:  $temp
#echo fan:   $fan
#echo stats: $stats
#echo khs:   $khs
#echo diff: $diffTime
#echo uptime: $uptime
