#!/usr/bin/env bash

cd `dirname $0`

install_miner() {
        wget https://github.com/mimblewimble/grin-miner/releases/download/v1.0.1/grin-miner-v1.0.1-480578774-linux-amd64.tgz
        tar -zxf grin-miner-v1.0.1-480578774-linux-amd64.tgz
        mv grin-miner-v1.0.1/grin-miner .
        mv grin-miner-v1.0.1/plugins .
        rm grin-miner-v1.0.1-480578774-linux-amd64.tgz
}

[ -t 1 ] && . colors

. h-manifest.conf

[[ -z $CUSTOM_LOG_BASENAME ]] && echo -e "${RED}No CUSTOM_LOG_BASENAME is set${NOCOLOR}" && exit 1
[[ -z $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No CUSTOM_CONFIG_FILENAME is set${NOCOLOR}" && exit 1
[[ ! -f $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}Custom config ${YELLOW}$CUSTOM_CONFIG_FILENAME${RED} is not found${NOCOLOR}" && exit 1
CUSTOM_LOG_BASEDIR=`dirname "$CUSTOM_LOG_BASENAME"`
[[ ! -d $CUSTOM_LOG_BASEDIR ]] && mkdir -p $CUSTOM_LOG_BASEDIR
[[ ! -f ./grin-miner ]] && install_miner
./grin-miner
