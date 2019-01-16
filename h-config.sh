#!/usr/bin/env bash
# This code is included in /hive/bin/custom function

[[ -z $CUSTOM_TEMPLATE ]] && echo -e "${YELLOW}CUSTOM_TEMPLATE is empty${NOCOLOR}" && return 1
[[ -z $CUSTOM_URL ]] && echo -e "${YELLOW}CUSTOM_URL is empty${NOCOLOR}" && return 1

#replace tpl values in whole file
[[ -z $EWAL && -z $ZWAL && -z $DWAL ]] && echo -e "${RED}No WAL address is set${NOCOLOR}"
[[ ! -z $EWAL ]] && conf=$(sed "s/%EWAL%/$EWAL/g" <<< "$conf") #|| echo "${RED}EWAL not set${NOCOLOR}"
[[ ! -z $DWAL ]] && conf=$(sed "s/%DWAL%/$DWAL/g" <<< "$conf") #|| echo "${RED}DWAL not set${NOCOLOR}"
[[ ! -z $ZWAL ]] && conf=$(sed "s/%ZWAL%/$ZWAL/g" <<< "$conf") #|| echo "${RED}ZWAL not set${NOCOLOR}"
[[ ! -z $EMAIL ]] && conf=$(sed "s/%EMAIL%/$EMAIL/g" <<< "$conf")
[[ ! -z $WORKER_NAME ]] && conf=$(sed "s/%WORKER_NAME%/$WORKER_NAME/g" <<< "$conf") #|| echo "${RED}WORKER_NAME not set${NOCOLOR}"

[[ -z $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No CUSTOM_CONFIG_FILENAME is set${NOCOLOR}" && return 1

if [ -z $CUSTOM_USER_CONFIG ];
then
    gpus=`gpu-detect listjson`
    brand=`echo $gpus | jq -r '.[0].brand'` 
    if [ "$brand" == "nvidia" ];
    then plat_num=1
    else plat_num=0
    fi
    CUSTOM_USER_CONFIG=""	
    AMD_GPU_COUNT=`gpu-detect AMD`	
    NVIDIA_GPU_COUNT=`gpu-detect NVIDIA`	
    amd_tpl=`cat /hive/miners/custom//${CUSTOM_NAME}/ocl.tpl`
    printf -v amd_tpl "%s\n" "$amd_tpl"
    cuda_tpl=`cat /hive/miners/custom//${CUSTOM_NAME}/cuda29.tpl`
    printf -v cuda_tpl "%s\n" "$cuda_tpl"
    for (( i=0; i < ${AMD_GPU_COUNT}; i++ )); do
	amd_tpl=${amd_tpl/"%%PLATFORM%%"/$plat_num}
	CUSTOM_USER_CONFIG+=${amd_tpl/"%%DEVICE%%"/$i} 
    done
    for (( i=0; i < ${NVIDIA_GPU_COUNT}; i++ )); do
	CUSTOM_USER_CONFIG+=${cuda_tpl/"%%DEVICE%%"/$i} 
    done
fi

tpl=`cat /hive/miners/custom/${CUSTOM_NAME}/grin.tpl`
[[ -z $tpl ]] && echo -e "${RED}No template found${NOCOLOR}" && return 1
toml_server=${tpl/"%%SERVER%%"/$CUSTOM_URL}
toml_login=${toml_server/"%%LOGIN%%"/$CUSTOM_TEMPLATE}
toml_pass=${toml_login/"%%PASS%%"/$CUSTOM_PASS}
toml=${toml_pass/"%%PLUGINS%%"/$CUSTOM_USER_CONFIG}
echo "$toml" > $CUSTOM_CONFIG_FILENAME
[[ -z $toml ]] && echo -e "${YELLOW}auto generate config file is empty${NOCOLOR}" && return 1
