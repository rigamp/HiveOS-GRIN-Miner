#!/usr/bin/env bash
# This code is included in /hive/bin/custom function

[[ -z $CUSTOM_TEMPLATE ]] && echo -e "${YELLOW}CUSTOM_TEMPLATE is empty${NOCOLOR}" && return 1
[[ -z $CUSTOM_URL ]] && echo -e "${YELLOW}CUSTOM_URL is empty${NOCOLOR}" && return 1

[[ -z $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No CUSTOM_CONFIG_FILENAME is set${NOCOLOR}" && return 1

if [ -z $CUSTOM_USER_CONFIG ];
then
    gpus=`gpu-detect listjson`
#    gpus=`cat /hive/miners/custom//${CUSTOM_NAME}/gpus.json`
    brand=`echo $gpus | jq -r '.[0].brand'` 
    if [ "$brand" == "nvidia" ];
    then plat_num=1
    else plat_num=0
    fi
    CUSTOM_USER_CONFIG=""	
    GPU_COUNT=`echo $gpus | jq ' . | length '`
    amd_tpl=`cat /hive/miners/custom//${CUSTOM_NAME}/ocl.tpl`
    printf -v amd_tpl "%s\n" "$amd_tpl"
    cuda_29_tpl=`cat /hive/miners/custom//${CUSTOM_NAME}/cuda29.tpl`
    printf -v cuda_29_tpl "%s\n" "$cuda_29_tpl"
    gtx_31_tpl=`cat /hive/miners/custom//${CUSTOM_NAME}/gtx31.tpl`
    rtx_31_tpl=`cat /hive/miners/custom//${CUSTOM_NAME}/rtx31.tpl`
    AMD_COUNT=0
    NVIDIA_COUNT=0 	
    for (( i=0; i < ${GPU_COUNT}; i++ )); do
        _NAME=`echo $gpus | jq -r ".[$(echo $i)].name"` 
        _BRAND=`echo $gpus | jq -r ".[$(echo $i)].brand"` 
        _MEM=`echo $gpus | jq -r ".[$(echo $i)].mem" | awk 'match($0, /[0-9]+/) {print substr($0, RSTART, RLENGTH)}'` 
	if [ "$_BRAND" == "amd" ];
	then
		if [ "$_MEM" -gt "5900" ]; 
		then
	        	amd_tpl=${amd_tpl/"%%PLATFORM%%"/$plat_num}
	        	CUSTOM_USER_CONFIG+=${amd_tpl/"%%DEVICE%%"/$AMD_COUNT} 
		fi
		(( AMD_COUNT=AMD_COUNT+1 ))
	else
		if [[ $_NAME == *"RTX"* ]];
		then
			CUDA_31=`echo "$rtx_31_tpl"`
		else
			CUDA_31=`echo "$gtx_31_tpl"`
   	        fi
    		printf -v CUDA_31 "%s\n" "$CUDA_31"
			
		if [ "$_MEM" -gt "10900" ]; 
		then
			CUSTOM_USER_CONFIG+=${CUDA_31/"%%DEVICE%%"/$NVIDIA_COUNT} 
		else
			if [ "$_MEM" -gt "5900" ]; 
			then
			CUSTOM_USER_CONFIG+=${cuda_29_tpl/"%%DEVICE%%"/$NVIDIA_COUNT} 
			fi
   	        fi
		(( NVIDIA_COUNT=NVIDIA_COUNT+1 ))
			
	fi
    done
fi

tpl=`cat /hive/miners/custom/${CUSTOM_NAME}/grin.tpl`
[[ -z $tpl ]] && echo -e "${RED}No template found${NOCOLOR}" && return 1
toml_server=${tpl/"%%SERVER%%"/${CUSTOM_URL%%$'\n'*}}
toml_login=${toml_server/"%%LOGIN%%"/$CUSTOM_TEMPLATE}
toml_pass=${toml_login/"%%PASS%%"/$CUSTOM_PASS}
toml=${toml_pass/"%%PLUGINS%%"/$CUSTOM_USER_CONFIG}
echo "$toml" > $CUSTOM_CONFIG_FILENAME
[[ -z $toml ]] && echo -e "${YELLOW}auto generate config file is empty${NOCOLOR}" && return 1
