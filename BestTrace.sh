#!/usr/bin/env bash
#
# Copyright (c) 2021 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/BestTrace
# File name: BestTrace.sh
# Description: BestTrace traceroute test script
# System Required: GNU/Linux
# Version: beta1
#

IPv4_list=(
    "北京电信-180.149.128.1"
    "北京联通-123.125.99.1"
    "北京移动-211.136.25.153"
    "上海电信-180.153.28.1"
    "上海联通-58.247.0.49"
    "上海移动-221.183.55.22"
    "广州电信-113.108.209.1"
    "广州联通-210.21.4.1"
    "广州移动-211.139.129.5"
    #"上海联通 CUII(AS9929)-210.13.66.238"
    #"上海电信 CN2-58.32.0.1"
    #"广州电信 CN2-119.121.0.1"
)

IPv6_list=(
    "北京电信-2400:da00:2::29"
    "北京联通-2408:80f0:4100:2005::3"
    "北京移动-2409:8089:1020:50ff:1000::fd01"
    "上海电信-240e:18:10:a01::1"
    "上海联通-2408:8000:9000:20e6::b7"
    "上海移动-2409:801e:5c03:2000::207"
    "广州电信-240e:ff:e02c:1:21::"
    "广州联通-2408:8001:3011:310::3"
    "广州移动-2409:8057:5c00:30::6"
)

set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

FontColor_Red="\033[31m"
FontColor_Green="\033[32m"
FontColor_Suffix="\033[0m"
MSG_info="[${FontColor_Green}INFO${FontColor_Suffix}]"
MSG_error="[${FontColor_Red}ERROR${FontColor_Suffix}]"

if [[ $(uname -s) != Linux ]]; then
    echo -e "${MSG_error} This operating system is not supported."
    exit 1
fi

if [[ $(id -u) != 0 ]]; then
    echo -e "${MSG_error} This script must be run as root."
    exit 1
fi

Project_Name='BestTrace'
Download_URL_Prefix='https://github.com/P3TERX/BestTrace/raw/download'
Bin_Dir='/usr/local/bin'
Bin_Name='besttrace'
BestTrace_Bin="${Bin_Dir}/${Bin_Name}"

Install_BestTrace() {
    echo -e "${MSG_info} Get CPU architecture ..."
    OS_Arch=$(uname -m)
    case ${OS_Arch} in
    *86)
        File_Keyword='besttrace32'
        ;;
    x86_64)
        File_Keyword='besttrace'
        ;;
    aarch64 | arm*)
        File_Keyword='besttracearm'
        ;;
    *)
        echo -e "${MSG_error} Unsupported architecture: ${OS_Arch}"
        exit 1
        ;;
    esac
    echo -e "${MSG_info} Architecture: ${OS_Arch}"

    echo -e "${MSG_info} Get ${Project_Name} download URL ..."
    Download_URL="${Download_URL_Prefix}/${File_Keyword}"
    echo -e "${MSG_info} Download URL: ${Download_URL}"

    echo -e "${MSG_info} Installing ${Project_Name} ..."
    curl -LS "${Download_URL}" -o "${BestTrace_Bin}"
    chmod +x "${BestTrace_Bin}"
    if [[ -s ${BestTrace_Bin} && $(${Bin_Name} --version) ]]; then
        echo -e "${MSG_info} Done."
    else
        echo -e "${MSG_error} ${Project_Name} installation failed !"
        exit 1
    fi
}

Remove_BestTrace() {
    rm -f "${BestTrace_Bin}"
}

Print_Delimiter() {
    printf '=%.0s' $(seq $(tput cols))
}

Run_BestTrace() {
    echo "${1} (IPv${3}, ${4} Mode)"
    if [[ ${4} = TCP ]]; then
        "${BestTrace_Bin}" -q1 -n -T "${2}" -gcn
    elif [[ ${4} = ICMP ]]; then
        "${BestTrace_Bin}" -q1 -n "${2}" -gcn
    fi
}

BestTrace_IPv4_list() {
    for ((i = 0; i < ${#IPv4_list[@]}; i++)); do
        IP_loc="${IPv4_list[$i]%-*}"
        IP_addr="${IPv4_list[$i]#*-}"
        Run_BestTrace "${IP_loc}" "${IP_addr}" "4" "${TraceRoute_Mode:=TCP}"
        Print_Delimiter
    done
}

BestTrace_IPv6_list() {
    for ((i = 0; i < ${#IPv6_list[@]}; i++)); do
        IP_loc="${IPv6_list[$i]%-*}"
        IP_addr="${IPv6_list[$i]#*-}"
        Run_BestTrace "${IP_loc}" "${IP_addr}" "6" "ICMP"
        Print_Delimiter
    done
}

if [ $# -ge 1 ]; then
    case ${1} in
    install)
        Install_BestTrace
        ;;
    uninstall)
        Remove_BestTrace
        ;;
    trace | trace4)
        shift
        if [ $# -ge 1 ] && [ -n ${1} ]; then
            if [[ ${1} = 'icmp' || ${1} = 'ICMP' ]]; then
                TraceRoute_Mode='ICMP'
            else
                TraceRoute_Mode='TCP'
            fi
        fi
        Install_BestTrace
        clear
        Print_Delimiter
        BestTrace_IPv4_list
        ;;
    trace6)
        Install_BestTrace
        clear
        Print_Delimiter
        BestTrace_IPv6_list
        ;;
    *)
        echo -e "${MSG_error} Invalid Parameters: ${1}"
        exit 1
        ;;
    esac
else
    Install_BestTrace
fi
