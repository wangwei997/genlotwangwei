C_None="\033[0m"
# Regular
C_Black="\033[0;30m"
C_Red="\033[0;31m"
C_Green="\033[0;32m"
C_Yellow="\033[0;33m"
C_Blue="\033[0;34m"
C_Purple="\033[0;35m"
C_Cyan="\033[0;36m"
C_White="\033[0;37m"
#Bold
C_BBlack="\033[1;30m"
C_BRed="\033[1;31m"
C_BGreen="\033[1;32m"
C_BYellow="\033[1;33m"
C_BBlue="\033[1;34m"
C_BPurple="\033[1;35m"
C_BCyan="\033[1;36m"
C_BWhite="\033[1;37m"
# High Intensity
C_IBlack="\033[0;90m"
C_IRed="\033[0;91m"
C_IGreen="\033[0;92m"
C_IYellow="\033[0;93m"
C_IBlue="\033[0;94m"
C_IPurple="\033[0;95m"
C_ICyan="\033[0;96m"
C_IWhite="\033[0;97m"
# Bold High Intensity
C_BIBlack="\033[1;90m"
C_BIRed="\033[1;91m"
C_BIGreen="\033[1;92m"
C_BIYellow="\033[1;93m"
C_BIBlue="\033[1;94m"
C_BIPurple="\033[1;95m"
C_BICyan="\033[1;96m"
C_BIWhite="\033[1;97m"


is_success(){
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

prepare_source_by_wget(){
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "useage: prepare_source_by_wget <file-name> <directory-name> <download-url>"
        exit 1
    fi

    local file=$1
    local path=$2
    local url=$3

    if [ ! -f "$file" ]; then
        wget $url -O $file
    fi
    if [ -d "$path" ]; then
        rm -rf $path
    fi

    local filename=$(basename -- "$file")
    local extension="${filename##*.}"

    if [ "$extension" == "bz2" ]; then
        echo "tar xjf $file"
        tar xjf $file
    elif [ "$extension" == "zip" ]; then
        echo "unzip -q $file"
        unzip -q $file
    elif [ "$extension" == "gz" ]; then
        echo "tar xzf $file"
        tar xzf $file
    else
        echo "do nothing for '.$extension' file!"
    fi

    is_success
}

prepare_source_by_git(){
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "useage: prepare_source_by_git <git-rep-name> <directory-name>"
        exit 1
    fi

    local rep=$1
    local directory=$2

    if [ -d "$directory" ]; then
        rm -rf $directory
    fi

    git clone $rep $directory

    is_success
}

force_cd(){
    if [ -z "$1" ]; then
        echo "useage: enter_path <path>"
    fi

    if [ ! -d "$1" ]; then
        mkdir -p $1
    fi
    cd $1
}

get_inet_ip_decimal(){
    local ip=`ip address | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | grep -v '192\.168\.*'`
    IFS=.
    read -r a b c d <<< "$ip"
    echo "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
}

is_centos_version(){
    if [ -f /etc/redhat-release ]; then
        local code=$1
        local version="$(get_os_version)"
        local main_ver=${version%%.*}
        if [ "$main_ver" == "$code" ]; then
            echo "true"
        else
            echo "false"
        fi
    else
        echo "false"
    fi
}

check_gcc_version(){
    if [ -z "$1" ]; then
        echo "useage: check_gcc_version <minimum version>"
        exit 1
    fi

    GCC_VERSION="$(gcc -dumpversion)"
    GCC_REQUIRED=$1
    if [ "$(printf '%s\n' "$GCC_REQUIRED" "$GCC_VERSION" | sort -V | head -n1)" = "$GCC_REQUIRED" ]; then
        echo "true"
    else
        echo "false"
    fi

}

get_os_version() {
    if [[ -s /etc/redhat-release ]]; then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

join() { 
    local IFS="$1"; 
    shift; 
    echo "$*"; 
}