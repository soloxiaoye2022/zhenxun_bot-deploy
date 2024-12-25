#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

update_shell_url="https://mirror.ghproxy.com/https://raw.githubusercontent.com/soloxiaoye2022/zhenxun_bot-deploy/main/install.sh"
zhenxun_url="https://github.com/HibiKier/zhenxun_bot.git"
proxy_arr=("https://github.moeyy.xyz/" "https://gh-proxy.com/" "https://x.haod.me/" "https://mirror.ghproxy.com/")
check_url="https://raw.githubusercontent.com/NapNeko/NapCatQQ/main/package.json"
napcat_url="https://github.com/NapNeko/NapCatQQ/releases/download/"
zhenxun_bot_plugins_url="https://github.com/zhenxun-org/zhenxun_bot_plugins"
api_url="https://api.github.com/repos/NapNeko/NapCatQQ/releases/latest"
api_url2="https://nclatest.znin.net/"
WORK_DIR="/root"
TMP_DIR="$(mktemp -d)"
napcat_DIR="/opt/QQ/resources/app/app_launcher"
ZX_DIR="${WORK_DIR}/zhenxun_bot/"
sh_ver="2.0.0"
mirror_url='"https://pypi.org/simple"'
musicSignUrl="https://llob.linyuchen.net/sign/music" #备用https://ss.xingzhige.com/music_card/card
ssh_port="8022"
mix="1024"
max="49151"
dns="8.8.8.8"

#检查python
if which python3.12 > /dev/null;then
  which python3.12
elif which python3.11 > /dev/null;then
  which python3.11
elif which python3.10 > /dev/null;then
  which python3.10
elif which python3.9 > /dev/null;then
  which python3.9
elif which python3.8 > /dev/null;then
  which python3.8
fi
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Red_background_prefix="\033[41;37m" && Purple_font_prefix="\033[33m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Purple_font_prefix}[注意]${Font_color_suffix}"

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo -i${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

#检查系统
check_sys() {
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        format="rpm"
    elif grep -q -E -i "debian" /etc/issue; then
        release="debian" 
        format="deb"
    elif grep -q -E -i "ubuntu" /etc/issue; then
        release="ubuntu"
        format="deb"
    elif grep -q -E -i "centos|red hat|redhat" /etc/issue; then
        release="centos"
        format="rpm"
    elif grep -q -E -i "Arch|Manjaro" /etc/issue; then
        release="archlinux"
    elif grep -q -E -i "debian" /proc/version; then
        release="debian"
        format="deb"
    elif grep -q -E -i "ubuntu" /proc/version; then
        release="ubuntu"
        format="deb"
    elif grep -q -E -i "centos|red hat|redhat" /proc/version; then
        release="centos"
        format="rpm"
    else
        echo -e "zhenxun_bot 暂不支持该Linux发行版" && exit 1
    fi
    bit=$(uname -m)
    #if [[ ! -e "~/.zshrc" ]];then
    #  nonomatch=$(cat ~/.zshrc | grep nonomatch)
    #  if [[ -z "${nonomatch}" ]];then
    #    echo "setopt nonomatch" >> ~/.zshrc
    #    source ~/.zshrc
    #  fi
    #fi
}

check_installed_zhenxun_status() {
  [[ ! -e "${WORK_DIR}/zhenxun_bot/bot.py" ]] && echo -e "${Error} zhenxun_bot 没有安装，请检查 !" && exit 1
}

check_installed_napcat_status() {
  [[ ! -e "${napcat_DIR}/napcat" ]] && echo -e "${Error} napcat 没有安装，请检查 !" && exit 1
}

check_pid_zhenxun() {
  #PID=$(ps -ef | grep "sergate" | grep -v grep | grep -v ".sh" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
  PID=$(pgrep -f "bot.py")
}

check_pid_napcat() {
  #PID=$(ps -ef | grep "sergate" | grep -v grep | grep -v ".sh" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
  PID=$(ps -ef | grep xvfb | grep -v grep | grep -v tmp | awk '{print $2}')
}

check_pid_postgres() {
  #PID=$(ps -ef | grep "sergate" | grep -v grep | grep -v ".sh" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
  PID=$(pgrep -f "postgresql")
}

Set_pip_Mirror() {
    echo -e "${Info} 请输入要选择的pip下载源，默认使用北外源
    ${Green_font_prefix} 1.${Font_color_suffix} 清华 
    ${Green_font_prefix} 2.${Font_color_suffix} 腾讯
    ${Green_font_prefix} 3.${Font_color_suffix} 阿里
    ${Green_font_prefix} 4.${Font_color_suffix} 中科大
    ${Green_font_prefix} 5.${Font_color_suffix} 北外 (默认)
    ${Green_font_prefix} 6.${Font_color_suffix} 不修改"
    read -erp "请输入数字 [1-6], 默认为 5:" mirror_num
    [[ -z "${mirror_num}" ]] && mirror_url='"https://mirrors.bfsu.edu.cn/pypi/web/simple/"' && mirror_num='5'
    [[ ${mirror_num} == 1 ]] && mirror_url='"https://pypi.tuna.tsinghua.edu.cn/simple/"'
    [[ ${mirror_num} == 2 ]] && mirror_url='"https://mirrors.cloud.tencent.com/pypi/simple/"'
    [[ ${mirror_num} == 3 ]] && mirror_url='"http://mirrors.aliyun.com/pypi/simple/"'
    [[ ${mirror_num} == 4 ]] && mirror_url='"https://pypi.mirrors.ustc.edu.cn/simple/"'
    [[ ${mirror_num} == 5 ]] && mirror_url='"https://mirrors.bfsu.edu.cn/pypi/web/simple/"'
    if [ "$mirror_num" -ge 1 -a "$mirror_num" -le 5 ];then
      sed -i "s|url.*|url = "${mirror_url}"|g" ${WORK_DIR}/zhenxun_bot/pyproject.toml
      pip_url=$(echo $mirror_url | sed 's/\"//g')
      pip config set global.index-url "${pip_url}"
    elif [ "$mirror_num" -gt 6 ]; then
      echo -e"${Info} 你可能没有输入正确的选项?"
      Set_pip_Mirror
    fi
}

Set_ghproxy() {
  echo -e "${Info} 是否使用 ghproxy 代理git相关的下载？(中国大陆建议使用)"
  read -erp "请选择 [y/n], 默认为 y:" ghproxy_check
  if [[ -z "${ghproxy_check}" ]];then
    network_test
  elif [[ ${ghproxy_check} == 'n' ]];then
    ghproxy=""
    echo -e "${Info} 代理已关闭，将直接连接GitHub..."
  elif [[ ${ghproxy_check} == 'y' ]];then
    network_test
  fi
}

network_test() {
    found=0
    for proxy in "${proxy_arr[@]}"; do
      status=$(curl -o /dev/null -s -w "%{http_code}" "$proxy/$check_url")
      if [ $status -eq 200 ]; then
        found=1
        ghproxy="$proxy"
        echo -e "${Info} 将使用代理：$proxy"
        break
      fi
    done

    if [ $found -eq 0 ]; then
      echo -e "${Error} 无法连接到GitHub，请检查网络。"
      exit 1
    fi
}



Installation_dependency() {
    if [[ ${release} == "centos" ]]; then
        yum -y update
        yum install -y git fontconfig mkfontscale epel-release wget vim zip unzip jq curl xorg-x11-server-Xvfb screen zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make libffi-devel
        if  ! which python3.10; then
            wget https://mirrors.huaweicloud.com/python/3.11.2/Python-3.11.2.tgz -O "${TMP_DIR}"/Python-3.11.2.tgz && \
                tar -zxf "${TMP_DIR}"/Python-3.11.2.tgz -C "${TMP_DIR}"/ &&\
                cd "${TMP_DIR}"/Python-3.11.2 --with-ensurepip=install && \
                ./configure && \
                make -j $(nproc) && \
                make altinstall
        fi
        ${python_v} <(curl -s -L https://bootstrap.pypa.io/get-pip.py) || echo -e "${Tip} pip 安装出错..."
        rpm -v --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
        rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
        yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
        yum install -y postgresql13-server ffmpeg ffmpeg-devel atk at-spi2-atk cups-libs libxkbcommon libXcomposite libXdamage libXrandr mesa-libgbm gtk3
        /usr/psql-13/bin/postgresql-13-setup initdb
        systemctl enable postgresql-13
        systemctl start postgresql-13
        cat > /tmp/sql.sql <<-EOF
CREATE USER zhenxun WITH PASSWORD 'zxpassword';
CREATE DATABASE zhenxun OWNER zhenxun;
EOF
        su postgres -c "psql -f /tmp/sql.sql"
    elif [[ ${release} == "debian" ]]; then
        apt-get update
        apt-get install -y wget ttf-wqy-zenhei jq xfonts-intl-chinese  build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev make
        if  ! which python3.11 && ! which python3.12 && ! which python3.10;then
            wget ${ghproxy}https://github.com/openssl/openssl/releases/download/openssl-3.0.7/openssl-3.0.7.tar.gz 
            tar -zxf openssl-3.0.7.tar.gz && cd openssl-3.0.7
            ./config -fPIC --prefix=/usr/include/openssl enable-shared
            make && make install
msg='_ssl _ssl.c $(OPENSSL_INCLUDES) $(OPENSSL_LDFLAGS) \
    -l:libssl.a -Wl,--exclude-libs,libssl.a \
    -l:libcrypto.a -Wl,--exclude-libs,libcrypto.a
_hashlib _hashopenssl.c $(OPENSSL_INCLUDES) $(OPENSSL_LDFLAGS) \
    -l:libcrypto.a -Wl,--exclude-libs,libcrypto.a'
            wget https://mirrors.huaweicloud.com/python/3.11.2/Python-3.11.2.tgz -O "${TMP_DIR}"/Python-3.11.2.tgz && \
                tar -zxf "${TMP_DIR}"/Python-3.11.2.tgz -C "${TMP_DIR}"/ 
                cd "${TMP_DIR}"/Python-3.11.2
                echo $msg >> Modules/Setup
                chmod +x configure
                mkdir /usr/local/python-3.11.2
                ./configure --prefix=/usr/local/python-3.11.2 --with-zlib=/usr/include/ --with-openssl-rpath=auto  --with-openssl=/usr/include/openssl  OPENSSL_LDFLAGS=-L/usr/include/openssl   OPENSSL_LIBS=-l/usr/include/openssl/ssl OPENSSL_INCLUDES=-I/usr/include/openssl
                make -j $(nproc)
                make altinstall
                ln -s /usr/local/python-3.11.2/bin/python3.11 /usr/bin/python3.11
        fi
        apt-get install -y \
            vim \
            wget \
            git \
            zip \
            unzip \
            jq \
            curl \
            xvfb \
            screen \
            ffmpeg \
            libgl1 \
            libglib2.0-0 \
            libnss3 \
            libatk1.0-0 \
            libatk-bridge2.0-0 \
            libcups2 \
            libxkbcommon0 \
            libxcomposite1 \
            libxrandr2 \
            libgbm1 \
            libgtk-3-0 \
            python3-pip
        apt-get install libasound2t64 -y
        apt-get install -y libasound2
        apt remove libfprint-2-2 -y
        apt --fix-broken install
        #${python_v} <(curl -s -L https://bootstrap.pypa.io/get-pip.py) || echo -e "${Tip} pip 安装出错..."
        Install_postgresql
    elif [[ ${release} == "ubuntu" ]]; then
        apt-get update
        apt-get install -y software-properties-common ttf-wqy-zenhei ttf-wqy-microhei fonts-arphic-ukai fonts-arphic-uming
        fc-cache -f -v
        echo -e "\n" | add-apt-repository ppa:deadsnakes/ppa
        if  ! which python3.12 && ! which python3.11 && ! which python3.10;then
            apt-get install -y python3.10-full
            python_v="python3.10"
        fi
        apt-get install -y \
            vim \
            wget \
            git \
            zip \
            unzip \
            jq \
            curl \
            xvfb \
            screen \
            ffmpeg \
            libgl1 \
            libglib2.0-0 \
            libnss3 \
            libatk1.0-0 \
            libatk-bridge2.0-0 \
            libcups2 \
            libxkbcommon0 \
            libxcomposite1 \
            libxrandr2 \
            libgbm1 \
            libgtk-3-0 \
            python3-pip
        apt-get install libasound2t64 -y
        apt-get install -y libasound2
        apt remove libfprint-2-2 -y
        apt --fix-broken install
        #${python_v} <(curl -s -L https://bootstrap.pypa.io/get-pip.py) || echo -e "${Tip} pip 安装出错..."
        Install_postgresql
    elif [[ ${release} == "archlinux" ]]; then
        pacman -Sy python python-pip unzip --noconfirm
    fi

    if which python3.12; then
      python_v="python3.12"
    elif which python3.11; then
      python_v="python3.11"
    elif which python3.10; then
      python_v="python3.10"
    elif which python3.9; then 
      python_v="python3.9"
    elif which python3.8; then
      python_v="python3.8"
    fi
    
    [[ ! -e /usr/bin/python3 ]] && ln -s /usr/bin/${python_v} /usr/bin/python3
    [[ 'command -v apt-get' ]] && apt install ${python_v}-dev -y || apt install python3-dev -y
}

check_arch() {
    get_arch=$(arch)
    if [[ ${get_arch} == "x86_64" ]]; then 
      arch="amd64"
    elif [[ ${get_arch} == "aarch64" ]]; then
      arch="arm64"
    elif [[ ${get_arch} == "v8l" ]]; then
      arch="arm64"
    else
      echo -e "${Error} napcat 不支持该内核版本(${get_arch})..." && exit 1
    fi
}

check_module() {
    check_pid_zhenxun
    log="/root/zhenxun_bot/zhenxun_bot.log"
    dir="/root/zhenxun_bot"
    echo -e "${Info} 自动检测真寻确实依赖并自动安装"
    if [[ -e "${log}" ]]; then
      [[ ! -z ${PID} ]] && kill -9 "${PID}"
      cd ${dir} || exit
      nohup poetry run ${python_v} bot.py > zhenxun_bot.log 2>&1 & 
      echo -e "${Info} 正在检测 zhenxun_bot 缺失依赖(需要约1分钟)"
      sleep 60
      [[ ! -z ${PID} ]] && kill -9 "${PID}"
      cat ${log} | grep "No module named" | awk -F "'" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g' | sed 's/ /\n/' > /root/zhenxun_bot/requests.txt
      Install_module
    else
      echo -e "${Error} log文件不存在,即将自动启动 zhenxun_bot 并生成log文件"
      cd ${dir} || exit
      nohup poetry run ${python_v} bot.py > zhenxun_bot.log 2>&1 & 
      echo -e "${Info} log文件已生成"
      sleep 5
      check_module
    fi

}

Install_module() {
    module=$(sort -u /root/zhenxun_bot/requests.txt | uniq | sed '/^enchant/d')
    echo "${module}" > /root/zhenxun_bot/requests.txt
    if [[ ! -z "${module}" ]]; then
      cd ${dir} || exit
      echo -e "${Info} 本次检测到以下版本依赖需要安装,如果安装失败请手动进入虚拟环境执行poetry install"
      sleep 1
      poetry run pip install "$module" -i "${pip_url}"
      echo -e "${Info} 本次依赖安装结束"
      check_module
    else
      echo -e "${Info} 没有依赖需要安装"
    fi
}

Set_dns() {
    check_sys
    local_dns=$(cat /etc/resolv.conf | grep "nameserver" | head -n 1 | awk '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
    if [[ $local_dns == $dns ]];then
      echo -e "${Info} 你的dns已经是 ${local_dns}"
    else
      echo -e "${Info} 检测到本机dns [${local_dns}] 不是谷歌dns,是否修改 dns ?(大陆地区不修改可能会有各种蜜汁网络问题)"
      read -erp "请选择 [y/n], 默认为 y:" dns_check 
      [[ -z "${dns_check}" ]] && dns_check='y'
      [[ ${dns_check} == 'n' ]] && dns=""
      if [ "${dns_check}" = 'y' ];then
        sed -i "s|$local_dns|$dns|g" /etc/resolv.conf
        sed -i '$a DNS=8.8.8.8' /etc/systemd/resolved.conf
        echo -e "${Info} 已修改dns为 ${dns}"
      else
        echo -e "${Info} 你选择的是 'n' ,已跳过修改dns"
      fi
    fi
}

Download_zhenxun_bot() {
    check_arch
    echo -e "${Info} 开始下载最新版 zhenxun_bot ..."
    cd "${TMP_DIR}" || exit 1
    for (( i=1; i<=5; i++ )); do
      git clone "${ghproxy}${zhenxun_url}"
      if [ $? = 0 ] ; then
        echo -e "${Info} 开始下载 zhenxun_bot 插件库 ..."
        for (( i=1; i<=5; i++ )); do
          git clone ${ghproxy}${zhenxun_bot_plugins_url}
          if [ $? = 0 ] ; then
            break
          elif [ $i -lt 5 ]; then
            echo -e "${Info} 第${i}次尝试失败，正在重试..."
          else
            echo -e "${Error} 无法下载 zhenxun_bot 插件库，请安装结束后自行安装\n插件库地址：${ghproxy}${zhenxun_bot_plugins_url}。"
          fi
        done
        break
      elif [ $i -lt 5 ]; then
        echo -e "${Info} 第${i}次尝试失败，正在重试..."
      fi
    done

    cd ${WORK_DIR}
    mv ${TMP_DIR}/zhenxun_bot ./
    mv ${TMP_DIR}/zhenxun_bot_plugins/plugins/* ${ZX_DIR}zhenxun/plugins/
    echo -e "${Info} 开始下载抽卡相关资源..."
    if [[ -e "${WORK_DIR}/zhenxun_bot/draw_card" ]]; then
      echo -e "${Info} 抽卡资源文件已存在，跳过下载"
    else
      SOURCE_URL=https://pan.yropo.top/source/zhenxun/
      wget ${SOURCE_URL}data_draw_card.tar.gz -O ~/.cache/data_draw_card.tar.gz \
        && wget ${SOURCE_URL}img_draw_card.tar.gz -O ~/.cache/img_draw_card.tar.gz \
        && tar -zxf ~/.cache/data_draw_card.tar.gz -C ${WORK_DIR}/zhenxun_bot/ \
        && tar -zxf ~/.cache/img_draw_card.tar.gz -C ${WORK_DIR}/zhenxun_bot/ \
        && rm -rf ~/.cache/*.tar.gz
    fi
}   

update_linuxqq_config() {
    echo -e "${Info} 正在更新QQ配置..."
    confs=$(sudo find /home -name "config.json" -path "*/.config/QQ/versions/*" 2>/dev/null)
    if [ -f /root/.config/QQ/versions/config.json ]; then
      confs="/root/.config/QQ/versions/config.json $confs"
    fi
    for conf in $confs; do
      echo -e "${Info}  正在修改 $conf..."
      sudo jq --arg targetVer "$package_targetVer" --arg buildId "$target_build" \
      '.baseVersion = $targetVer | .curVersion = $targetVer | .buildId = $buildId' "$conf" > "$conf.tmp" && \
      sudo mv "$conf.tmp" "$conf" || { echo -e "${Error} QQ配置更新失败！"; exit 1; }
    done
}

update_napcat() {
    get_napcat_version
    echo -e "${Info} 最新NapCatQQ版本：${napcat_version}"
    if [ -d "${napcat_DIR}/napcat" ]; then
      current_version=$(jq -r '.version' "${napcat_DIR}/napcat/package.json")
      echo -e "${Info} NapCatQQ已安装，版本：v${current_version}"
      target_version=${napcat_version#v}
      IFS='.' read -r i1 i2 i3 <<< "$current_version"
      IFS='.' read -r t1 t2 t3 <<< "$target_version"
      if (( i1 < t1 || (i1 == t1 && i2 < t2) || (i1 == t1 && i2 == t2 && i3 < t3) )); then
        Install_napcat
      else
        echo -e "${Info} 已安装最新版本，无需更新。"
      fi
    else
      Install_napcat
    fi
}

Install_linuxqq() {
    check_arch
    check_sys
    echo -e "${Info} 开始安装LinuxQQ..."
    for (( i=1; i<=5; i++ )); do
      qq_download_url="https://dldir1.qq.com/qqfile/qq/QQNT/833d113c/linuxqq_3.2.13-29927_${arch}.${format}"
      sudo wget -O QQ.${format} "${qq_download_url}"
      if [ $? = 0 ] ;
        sudo apt-get install libnotify4 xdg-utils libsecret-1-0 -y
        while true; do
          sudo dpkg -i ./QQ.${format}
          if [ $? = 0 ] ; then
            break
          elif [ $? -ge 0 ]; then
            echo -e "${Info} 安装LinuxQQ失败，正在尝试修复环境..."
            apt --fix-broken install
          else
            echo -e "${Error} 安装LinuxQQ失败，请检查错误。" && exit 1    
          fi
        done
        break
      elif [ $i -lt 5 ]; then
        echo -e "${Info} 第${i}次尝试下载LinuxQQ失败，正在重试..."
      else
        echo -e "${Error} 下载LinuxQQ失败，请检查错误。" && exit 1
      fi
    done
    update_linuxqq_config
}

get_napcat_version() {
    default_file="NapCat.Shell.zip"
    json_data=$(curl -s "$api_url") || json_data=$(curl "$api_url2")
    napcat_version=$(jq -r '.tag_name' <<< "$json_data")
    napcat_download_url=$(jq -r '.assets[] | select(.name == "NapCat.Shell.zip") | .browser_download_url'  <<< "$json_data")

}

Download_napcat() {
    echo -e "${Info} 尝试获取最新NapCatQQ版本..."
    get_napcat_version
    cd "${TMP_DIR}" || exit 1
    for (( i=1; i<=5; i++ )); do
      if [ ! -z "$napcat_version" ]; then
        echo -e "${Info} 最新NapCatQQ版本：${napcat_version}, 开始下载..."
        for (( i=1; i<=5; i++ )); do
          sudo wget -O "${default_file}" "${ghproxy}${napcat_download_url}"
          if [ $? = 0 ] ; then
            break
          elif [ $i -lt 5 ]; then
            echo -e "${Info} 第${i}次尝试下载NapCatQQ失败，正在重试..."
          else
            echo -e "${Error} 下载NapCatQQ失败，请检查错误。" && exit 1
          fi
        done
        break 
      elif [ $i -lt 5 ]; then
        echo -e "${Info} 第${i}次尝试获取最新版本失败，正在重试..."
      else
        echo -e "${Error} 无法获取NapCatQQ版本，请检查错误。" && exit 1
      fi
    done

    echo -e "${Info} 正在解压 ${default_file}..."
    unzip -q -o -d NapCat NapCat.Shell.zip
    if [ $? -ne 0 ]; then
      echo -e "${Error} 文件解压失败，请检查错误。"
      clean
      exit 1
    fi
    
    if [ ! -d "${napcat_DIR}/napcat" ]; then
      sudo mkdir "${napcat_DIR}/napcat/"
      sudo mkdir "${napcat_DIR}/napcat/logs"
    fi

    echo -e "${Info} 正在移动文件..."
    sudo cp -r -f NapCat/* "${napcat_DIR}/napcat/"
    if [ $? -ne 0 -a $? -ne 1 ]; then
      echo -e "${Error} 文件移动失败，请以root身份运行。"
      clean
      exit 1
    fi

    sudo chmod -R 777 "${napcat_DIR}/napcat/"
    echo -e "${Info} 正在修补文件..."
    sudo mv -f "${napcat_DIR}/index.js" "${napcat_DIR}/index.js.bak"
    output_index_js=$(echo -e "const path = require('path');\nconst CurrentPath = path.dirname(__filename)\nconst hasNapcatParam = process.argv.includes('--no-sandbox');\nif (hasNapcatParam) {\n    (async () => {\n        await import(\\\"file://\\\" + path.join(CurrentPath, './napcat/napcat.mjs'));\n    })();\n} else {\n    require('./launcher.node').load('external_index', module);\n}")
    sudo bash -c "echo \"$output_index_js\" > \"${napcat_DIR}/index.js\""

    if [ $? = 0 ]; then
      echo -e "${Info} NapCatQQ安装成功！"
    else
      echo -e "${Error} index.js文件写入失败，请以root身份运行。"
      clean
      exit 1
    fi
    modify_qq_config
    clean
}

modify_qq_config() {
    echo -e "${Info} 正在修改QQ启动配置..."

    if sudo jq '.main = "./loadNapCat.js"' /opt/QQ/resources/app/package.json > ./package.json.tmp; then
        sudo mv ./package.json.tmp /opt/QQ/resources/app/package.json
        echo -e "${Info} 修改QQ启动配置成功..."
    else
        echo -e "${Info} 修改QQ启动配置失败..."
        exit 1
    fi
}

Install_napcat() {
    Install_linuxqq
    Download_napcat
     
}

clean() {
    rm -rf ${TMP_DIR}
    if [ $? -ne 0 ]; then
      echo -e "${Error} 临时文件删除失败，请手动删除 ${TMP_DIR}。"
    fi
}


Set_config_admin() {
    while true; do
      echo -e "${Info} 请输入管理员QQ账号(也就超级用户账号):[QQ]"
      read -erp "管理员QQ:" admin_qq
      if [[ -z "$admin_qq" ]]; then
        echo -e "${Error} 管理员QQ不能为空，请重新输入！"
      elif [[ ! "$admin_qq" =~ ^[0-9]+$ ]]; then
        echo -e "${Error} 管理员QQ必须是数字，请重新输入！"
      else
        break
      fi
    done
    cd ${WORK_DIR}/zhenxun_bot
    sed -i "s/SUPERUSERS=.*/SUPERUSERS=[\"$admin_qq\"]/g" .env.dev || echo -e "${Error} 配置文件不存在！请检查zhenxun_bot是否安装正确!"
    sed -i -e 's/"qq".*/"qq": ["'"$admin_qq"'"],/g' .env.dev || echo -e "${Error} 配置文件不存在！请检查zhenxun_bot是否安装正确!"
    echo -e "${Info} 设置成功!管理员QQ: [""${Green_font_prefix}"${admin_qq}"${Font_color_suffix}""]"
    
}

Set_config_bot() {
    while true; do
      echo -e "${Info} 请输入Bot QQ账号:[QQ]"
      read -erp "Bot QQ:" bot_qq
      if [[ -z "$bot_qq" ]]; then
        echo -e "${Error} Bot QQ不能为空，请重新输入！"
      elif [[ ! "$bot_qq" =~ ^[0-9]+$ ]]; then
        echo -e "${Error} Bot QQ必须是数字，请重新输入！"
      elif [ "$bot_qq" = "$admin_qq" ]; then
        echo -e "${Error} Bot QQ[""${Green_font_prefix}"$bot_qq"${Font_color_suffix}""]不能与管理员QQ账号[""${Green_font_prefix}"$admin_qq"${Font_color_suffix}""]一致"
      else
        break
      fi
    done
    qq_data="{ \"bot_qq\": \"$bot_qq\", \"other_QQ\": [] }"
    cd ${napcat_DIR}/napcat/config && echo $qq_data | jq > qq_data.json
    #fi
    #cd ${napcat_DIR}/napcat/config && \
    #jq --arg key "pathName" --arg value "$bot_qq" '. += {($key): $value}' napcat.json > napcat.json.tmp && mv napcat.json.tmp QQ.json || echo -e "${Error} 配置文件不存在或者缺失！请检查napcat是否安装正确!"
    #jq ".musicSignUrl = \"$musicSignUrl"\" onebot11_$bot_qq.json > temp.json && mv temp.json onebot11_$bot_qq.json || echo -e "${Error} 配置文件不存在或者缺失！请检查napcat是否安装正确!" && \
    #jq '.reverseWs.enable = true' onebot11_$bot_qq.json > temp.json && mv temp.json onebot11_$bot_qq.json || echo -e "${Error} 配置文件不存在或者缺失！请检查napcat是否安装正确!"
    echo -e "${Info} 设置成功!Bot QQ: [""${Green_font_prefix}"${bot_qq}"${Font_color_suffix}""]"
    
}

Set_config() { 
    Set_config_admin
    Set_config_bot
    Set_Port
    Set_postgresql_bind
    cat > ${napcat_DIR}/napcat/config/onebot11_$bot_qq.json <<-EOF
{
  "network": {
    "httpServers": [],
    "httpClients": [],
    "websocketServers": [],
    "websocketClients": [
      {
        "name": "真寻 bot",
        "enable": false,
        "url": "ws://127.0.0.1:${Port}/onebot/v11/ws",
        "messagePostFormat": "array",
        "reportSelfMessage": true,
        "reconnectInterval": 5000,
        "token": "",
        "debug": true,
        "heartInterval": 30000,
        "type": "WebSocket 客户端"
      }
    ]
  },
  "musicSignUrl": "${musicSignUrl}",
  "enableLocalFile2Url": true,
  "parseMultMsg": true
}
EOF
    
}

Set_Port() {
    while true; do
      echo -e "${Info} 请设置zhenxun_bot napcat通信端口:取值范围[""${Green_font_prefix}"${mix}-${max}"${Font_color_suffix}""]"
      read -erp "Port:" Port
      [[ -z "${Port}" ]] && Port=""
        if [ "${Port}" -ge ${mix} -a "${Port}" -le ${max} ]; then
          #cd ${napcat_DIR}/napcat/config  && jq --arg port "$port" '.network.websocketClients [0].url = "ws://127.0.0.1:\($port)/onebot/v11/ws"' onebot11_10253524270.json > temp.json && mv temp.json onebot11_10253524270.json || (echo -e "${Error} 配置文件不存在或者缺失！请检查napcat是否安装正确!" && exit 1)
          cd ${WORK_DIR}/zhenxun_bot && sed -i -e "s/PORT.*/PORT = ${Port}/" .env.dev || echo -e "${Error} 配置文件不存在！请检查zhenxun_bot是否安装正确!"
          echo -e "${Info} 设置成功!端口: [""${Green_font_prefix}"${Port}"${Font_color_suffix}""]"
          break
        else 
          echo -e "${Error} 端口设置错误，取值范围[""${Green_font_prefix}"${mix}-${max}"${Font_color_suffix}""]"
        fi  
    done   
}

Set_postgresql_bind() {
    echo -e "${Info} 开始设置 PostgreSQL 连接语句..."
    cd ${WORK_DIR}/zhenxun_bot && sed -i 's|DB_URL.*|DB_URL = "postgres://zhenxun:zxpassword@localhost:5432/zhenxun"|g' .env.dev
}

Restart_zx_napcat() {
    Set_Port
    Restart_zhenxun_bot
    Restart_napcat
}

Start_zhenxun_bot() {
    check_installed_zhenxun_status
    check_pid_zhenxun
    [[ -n ${PID} ]] && echo -e "${Error} zhenxun_bot 正在运行，请检查 !" && exit 1
    Start_postgresql
    cd ${WORK_DIR}/zhenxun_bot || exit
    nohup poetry run python3 bot.py >> zhenxun_bot.log 2>&1 &
    echo -e "${Info} zhenxun_bot 开始运行..."
}

Stop_zhenxun_bot() {
    check_installed_zhenxun_status
    check_pid_zhenxun
    [[ -z ${PID} ]] && echo -e "${Error} zhenxun_bot 没有运行，请检查 !" && exit 1
    kill -9 "${PID}"
    echo -e "${Info} zhenxun_bot 已停止运行..."
}

Restart_zhenxun_bot() {
    Stop_zhenxun_bot
    Start_zhenxun_bot
}

View_zhenxun_log() {
    tail -f -n 100 ${WORK_DIR}/zhenxun_bot/zhenxun_bot.log
}

Set_config_zhenxun() {
    vim "${ZX_DIR}"/zhenxun/configs/config.yaml
}

Start_napcat() {
    check_installed_napcat_status
    check_pid_napcat
    cd $napcat_DIR/napcat/config/
    pathName=$(jq '.bot_qq' qq_data.json | sed 's/\"//g')
    [[ -n ${PID} ]] && echo -e "${Error} napcat 正在运行，请检查 !" && exit 1
    cd ${napcat_DIR}/napcat/logs
    nohup xvfb-run -a qq --no-sandbox -q ${pathName} >> napcat_${pathName}.log 2>&1 &
    echo -e "${Info} napcat 开始运行..."
    sleep 2
}

Start_postgresql() {
    INODE_NUM=$(ls -ali / | sed '2!d' |awk {'print $1'})
    if [ "$INODE_NUM" == '2' ]; then
      systemctl start postgresql
    else
      su postgres <<-EOF
        pg_createcluster 13 main --start
        chmod -R 700 /etc/ssl/private/ssl-cert-snakeoil.key
        /etc/init.d/postgresql start
EOF

    fi
    echo -e "${Info} postgresql数据库已重启"
}

Stop_postgresql() {
    INODE_NUM=$(ls -ali / | sed '2!d' |awk {'print $1'})
    if [ "$INODE_NUM" == '2' ]; then
      systemctl stop postgresql
    else
      su postgres <<-EOF
        /etc/init.d/postgresql stop
EOF

    fi
    echo -e "${Info} postgresql数据库已停止"
}

Restart_postgresql() {
    Stop_postgresql
    Start_postgresql
}

Stop_napcat() {
    check_installed_napcat_status
    check_pid_napcat
    [[ -z ${PID} ]] && echo -e "${Error} napcat 没有运行，请检查 !" && exit 1
    kill -9 "${PID}"
    echo -e "${Info} napcat 停止运行..."
}

Restart_napcat() {
    Stop_napcat
    Start_napcat
}

View_napcat_log() {
    check_installed_napcat_status
    cd ${napcat_DIR}/napcat/config
    pathName=$(jq '.bot_qq' qq_data.json | sed 's/\"//g')
    tail -f -n 100 ${napcat_DIR}/napcat/logs/napcat_${pathName}.log
}

View_postgresql_info() {
    echo -e "${Info} 查询信息如下..."
    su postgres <<-EOF
          echo -e '\l' | psql
EOF

}

Set_config_napcat() {
    check_installed_napcat_status
    cd ${napcat_DIR}/napcat/config
    pathName=$(jq '.bot_qq' qq_data.json | sed 's/\"//g')
    vim ${napcat_DIR}/napcat/config/onebot_${pathName}.json
}

Set_config_zhenxun() {
    vim ${WORK_DIR}/zhenxun_bot/configs/config.yaml
}

Set_apt_source() {
    echo -e "${Info} 请选择apt源修改方式
    ${Green_font_prefix} 1.${Font_color_suffix} apt源列表
    ${Green_font_prefix} 2.${Font_color_suffix} 手动输入"
    read -erp "请输入数字 [1-2], 默认为 1:" apt_source
    if [[ -z "${apt_source}" ]]; then
      select_apt_source
    elif [[ "${apt_source}" = "1" ]]; then
      select_apt_source
    elif [[ ${apt_source} = "2" ]]; then
      echo -e "${Info} 在写了在写了..."
    fi

}

select_apt_source() {
    echo -e "${Info} 请输入要选择的apt源,默认为北外源
    ${Green_font_prefix} 1.${Font_color_suffix} 北外 (默认)
    ${Green_font_prefix} 2.${Font_color_suffix} 清华
    ${Green_font_prefix} 3.${Font_color_suffix} 阿里
    ${Green_font_prefix} 4.${Font_color_suffix} 华为
    ${Green_font_prefix} 5.${Font_color_suffix} 中科大
    ${Green_font_prefix} 6.${Font_color_suffix} 163 (广东电信：适合电信用户)
    ${Green_font_prefix} 7.${Font_color_suffix} 老子就不改你能咋滴"
    read -erp "请输入数字 [1-7], 默认为 1:" select_source
    if [[ -z "${select_source}" ]]; then
      apt_source_bfsu
    elif [[ ${select_source} == 1 ]]; then
      apt_source_bfsu
    elif [[ ${select_source} == 2 ]]; then
      apt_source_tsinghua
    elif [[ ${select_source} == 3 ]]; then
      apt_source_ali
    elif [[ ${select_source} == 4 ]]; then
      apt_source_huawei
    elif [[ ${select_source} == 5 ]]; then
      apt_source_ustc
    elif [[ ${select_source} == 6 ]]; then
      apt_source_163
    fi

}

apt_source_bfsu() {
    sed -i "s@https://.*.c../\|http://.*.c../\|https://.*.c./\|http://.*.c./\|https://.*.org/\|http://.*.org/\|https://.*.net/\|http://.*.net/@https://mirrors.bfsu.edu.cn/@g" /etc/apt/sources.list && apt update
}

apt_source_tsinghua() {
    sed -i "s@https://.*.c../\|http://.*.c../\|https://.*.c./\|http://.*.c./\|https://.*.org/\|http://.*.org/\|https://.*.net/\|http://.*.net/@https://mirrors.tuna.tsinghua.edu.cn/@g" /etc/apt/sources.list && apt update
}

apt_source_ali() {
    sed -i "s@https://.*.c../\|http://.*.c../\|https://.*.c./\|http://.*.c./\|https://.*.org/\|http://.*.org/\|https://.*.net/\|http://.*.net/@http://mirrors.aliyun.com/@g" /etc/apt/sources.list && apt update
}

apt_source_ustc() {
    sed -i "s@https://.*.c../\|http://.*.c../\|https://.*.c./\|http://.*.c./\|https://.*.org/\|http://.*.org/\|https://.*.net/\|http://.*.net/@https://mirrors.ustc.edu.cn/@g" /etc/apt/sources.list && apt update
}

apt_source_163() {
    sed -i "s@https://.*.c../\|http://.*.c../\|https://.*.c./\|http://.*.c./\|https://.*.org/\|http://.*.org/\|https://.*.net/\|http://.*.net/@http://mirrors.163.com/@g" /etc/apt/sources.list && apt update
}

apt_source_huawei() {
    sed -i "s@https://.*.c../\|http://.*.c../\|https://.*.c./\|http://.*.c./\|https://.*.org/\|http://.*.org/\|https://.*.net/\|http://.*.net/@https://repo.huaweicloud.com/@g" /etc/apt/sources.list && apt update
}

Manual_input_source() {
    read -erp "请输入镜像站地址(示例https://mirrors.bfsu.edu.cn/):" input
    if [[ -z "${input}" ]];then
      echo -e "${Info} 请输入正确的镜像站地址"
      Manual_input_source
    else
      symbol=$(echo ${input: -1})
      character="/"
      if [ "$sybmol" = "character" ];then
        sed -i "s@https://.*.c../\|http://.*.c../\|https://.*.c./\|http://.*.c./\|https://.*.org/\|http://.*.org/\|https://.*.net/\|http://.*.net/@'$input'@g" /etc/apt/sources.list && apt update
      else
        sed -i "s@https://.*.c..\|http://.*.c..\|https://.*.c.\|http://.*.c.\|https://.*.org\|http://.*.org\|https://.*.net|http://.*.net@'$input'@g" /etc/apt/sources.list && apt update
      fi
      echo -e "${Info} apt源已修改为 ${input}"
    fi
}

View_napcat_webui_info() {
    check_installed_napcat_status
    cd ${napcat_DIR}/napcat/config || exit
    pathName=$(jq '.bot_qq' qq_data.json | sed 's/\"//g')
    token=$(jq '.token' webui.json | sed 's/\"//g')
    port=$(jq '.port' webui.json | sed 's/\"//g')
    local_ipv4=$(ip addr show | grep -v docker | grep -v br-.* | grep -v "host lo" | grep 'inet ' | awk '{print $2}' | head -n 1 | cut -d'/' -f1) || local_ipv4=$(ifconfig | grep -v docker | grep -v br-.* | grep -v "host lo" | grep 'inet ' | awk '{print $2}' | head -n 1 | cut -d'/' -f1)
    public_ipv4=$(curl 4.ipw.cn)
    public_ipv6=$(curl 6.ipw.cn)
    echo -e "${Info} 当前bot QQ：${Green_font_prefix}${pathName}${Font_color_suffix}"
    echo -e "${Info} 登录密钥（token）：${Green_font_prefix}${token}${Font_color_suffix}"
    echo -e "${Info} webui地址："
    echo -e "${Info} 内网v4：http://${local_ipv4}:${port}/webui/?token=${token}"
    echo -e "${Info} 公网v4：http://${public_ipv4}:${port}/webui/?token=${token}"
    echo -e "${Info} 公网v6：http://[${public_ipv6}]:${port}/webui/?token=${token}"
    echo -e "${Info} 本机代理地址：https://napcat.152710.xyz/web_login?back=http://127.0.0.1:${port}&token=${token}"
    echo -e "${Info} 内网v4代理地址：https://napcat.152710.xyz/web_login?back=http://${local_ipv4}:${port}&token=${token}"
    echo -e "${Info} 公网v4代理地址：https://napcat.152710.xyz/web_login?back=http://${public_ipv4}:${port}&token=${token}"
    echo -e "${Info} 公网v6代理地址：https://napcat.152710.xyz/web_login?back=http://[${public_ipv6}]:${port}&token=${token}"
    echo "请按任意键返回..."
    read -n 1 -s
    menu_napcat
  
}

Set_dependency() {
    cd ${WORK_DIR}/zhenxun_bot || exit
    Set_pip_Mirror
    pip install poetry || pip install poetry --break-system-packages
    poetry env use ${python_v}
    poetry lock || poetry lock --no-update
    poetry run pip install  nonebot-plugin-uninfo==0.4.1 -i https://pypi.org/simple || poetry run pip install  nonebot-plugin-uninfo==0.4.1 -i https://pypi.org/simple
    poetry install
    #poetry run pip install nonebot-plugin-alconna==0.51.1  arclet-alconna==1.8.23 arclet-alconna-tools==0.7.9 
    poetry run pip install jieba matplotlib wordcloud zhdate
    #env_dir=$(poetry env list --full-path | awk '{print $1}')
    #index_dir="${env_dir}/lib/${python_v}/site-packages/playwright/driver/package/lib/server/registry/index.js"
    #sed -i -e 's/const PLAYWRIGHT_CDN_MIRRORS =.*/const PLAYWRIGHT_CDN_MIRRORS = ["https:\/\/registry.npmmirror.com\/-\/binary\/playwright"];/' $index_dir
    apt remove libfprint-2-2 -y
    apt --fix-broken install
    apt-get install libevent-2.1-7 -y
    poetry run playwright install-deps chromium
    poetry run playwright install chromium

}

Uninstall_postgresql() {
    echo -e "${Tip} 是否卸载 postgresql 数据库 ？(此操作不可逆)"
    read -erp "请选择 [y/n], 默认为 n:" uninstpsql_check
    [[ -z "${uninstpsql_check}" ]] && uninstpsql_check='n'
    if [[ ${uninstpsql_check} == 'y' ]]; then
      check_pid_postgres
      [[ -z ${PID} ]] || kill -9 "${PID}"
      echo -e "${Info} 开始卸载 postgresql 数据库..."
      sudo apt-get --purge remove postgresql\*
      sudo apt-get autoremove
      sudo rm -rf /etc/postgresql/
      sudo rm -rf /etc/postgresql-common/
      sudo rm -rf /var/lib/postgresql/
      sudo userdel -r postgres
      sudo groupdel postgres
      psql_dir=$(which psql)
      [[ -z "$(psql_dir)" ]] && echo -e "${Info} napcat 卸载完成" || echo -e "${Error} napcat 卸载失败！"
    else
      echo -e "${Info} 操作已取消..." && menu_postgresql
    fi

}

Uninstall_napcat() {
    echo -e "${Tip} 是否卸载 napcat ？(此操作不可逆)"
    read -erp "请选择 [y/n], 默认为 n:" uninstnapcat_check
    [[ -z "${uninstnapcat_check}" ]] && uninstnapcat_check='n'
    if [[ ${uninstnapcat_check} == 'y' ]]; then
      check_pid_napcat
      [[ -z ${PID} ]] || kill -9 "${PID}"
      echo -e "${Info} 开始卸载 napcat..."
      rm -rf ${napcat_DIR}/napcat || echo -e "${Error} napcat 卸载失败！"
      echo -e "${Info} napcat 卸载完成"
    else
      echo -e "${Info} 操作已取消..." && menu_napcat
    fi

}

Uninstall_zhenxun() {
    echo -e "${Tip} 是否卸载 zhenxun_bot ？(此操作不可逆)"
    read -erp "请选择 [y/n], 默认为 n:" uninstllzhenxun_check
    [[ -z "${uninstllzhenxun_check}" ]] && uninstllzhenxun_check='n'
    if [[ ${uninstllzhenxun_check} == 'y' ]]; then
      cd ${WORK_DIR} || exit
      check_pid_zhenxun
      [[ -z ${PID} ]] || kill -9 "${PID}"
      echo -e "${Info} 开始卸载 zhenxun_bot..."
      rm -rf zhenxun_bot || echo -e "${Error} zhenxun_bot 卸载失败！"
      echo -e "${Info} zhenxun_bot 卸载完成"
    else
      echo -e "${Info} 操作已取消..." && menu_zhenxun
    fi

}

Uninstall_All() {
    echo -e "${Tip} 是否完全卸载 zhenxun_bot 和 napcat？(此操作不可逆)"
    read -erp "请选择 [y/n], 默认为 n:" uninstall_check
    [[ -z "${uninstall_check}" ]] && uninstall_check='n'
    if [[ ${uninstall_check} == 'y' ]]; then
      cd ${WORK_DIR} || exit
      check_pid_zhenxun
      [[ -z ${PID} ]] || kill -9 "${PID}"
      echo -e "${Info} 开始卸载 zhenxun_bot..."
      rm -rf zhenxun_bot || echo -e "${Error} zhenxun_bot 卸载失败！"
      check_pid_napcat
      [[ -z ${PID} ]] || kill -9 "${PID}"
      echo -e "${Info} 开始卸载 napcat..."
      rm -rf ${napcat_DIR}/napcat || echo -e "${Error} napcat 卸载失败！"
      echo -e "${Info} 感谢使用真寻bot，期待与你的下次相会！"
    else
      echo -e "${Info} 操作已取消..." && menu_zhenxun
    fi
}

Install_zhenxun_bot() {
    check_root
    [[ -e "${WORK_DIR}/zhenxun_bot/bot.py" ]] && echo -e "${Error} 检测到 zhenxun_bot 已安装 !" && exit 1
    startTime=$(date +%s)
    Set_ghproxy
    Set_apt_source
    echo -e "${Info} 开始检查系统..."
    check_arch
    check_sys
    Set_dns
    echo -e "${Info} 开始安装/配置 依赖..."
    Installation_dependency
    echo -e "${Info} 开始下载/安装..."
    Download_zhenxun_bot
    update_napcat
    echo -e "${Info} 开始设置 用户配置..."
    Set_config
    echo -e "${Info} 开始配置 zhenxun_bot 环境..."
    Set_dependency
    if [[ ${release} == "centos" ]]; then
        echo -e "${Info} CentOS 中文字体设置..."
        mkdir -p /usr/share/fonts/chinese
        cp -r ${WORK_DIR}/zhenxun_bot/resources/font /usr/share/fonts/chinese
        cd /usr/share/fonts/chinese && mkfontscale
    fi
    endTime=$(date +%s)
    ((outTime=($endTime-$startTime)))
    echo -e "${Info} 安装用时 ${outTime} s ..."
    Start_zhenxun_bot
    Start_napcat
    echo -e "${Info} 请扫描二维码登录 bot，bot 账号登录完成后，使用Ctrl + C退出 !"
    View_napcat_log
    
}

Install_postgresql() {
    databaseuser="zhenxun"
    databasename="zhenxun"
    password="zxpassword"
    INODE_NUM=$(ls -ali / | sed '2!d' |awk {'print $1'})
    if [ "$INODE_NUM" == '2' ];then
      echo -e "${Info} 开始安装postgresql数据库1"
      apt-get install postgresql postgresql-contrib -y
      echo -e "${Info} 设置postgresql数据库开机自启"
      systemctl enable postgresql
      systemctl restart postgresql
    else
      echo -e "${Info} 开始安装postgresql数据库"
      sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
      wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
      apt-get update
      apt-get -y install postgresql-13
      if stat "/etc/ssl/private/ssl-cert-snakeoil.key" | grep 0700; then
        echo -e "${Info} 检测数据库状态 "
      else
        echo -e "${Info} 检测数据库状态 "
        su postgres <<-EOF
          pg_createcluster 13 main --start
          echo -e "${Info} 检测到postgresql数据库文件权限问题...\n开始修复postgresql数据库"
          chmod -R 700 /etc/ssl/private/ssl-cert-snakeoil.key
          echo -e "${Info} 修复完成，启动postgresql数据库"
EOF
      fi
      Start_postgresql
      create_database
      echo -e "${Info} postgresql数据库安装完成"
    fi
}

create_database() {
su postgres <<-EOF
echo -e "CREATE USER $databaseuser WITH PASSWORD '$password';\n CREATE DATABASE $databasename OWNER $databaseuser;\n" | psql
EOF
    echo -e "${Info} 创建数据库成功\n 连接端口：5432\n 用户名: $databaseuser\n 数据库名: $databasename\n 密码: $password"
    echo -e "数据库连接地址：DB_URL = "postgres://$databaseuser:$password@localhost:5432/$databasename
}

Update_Shell(){
    echo -e "${Info} 开始更新install.sh"
    bak_dir_name="sh_bak/"
    bak_file_name="${bak_dir_name}install.$(date +%Y%m%d%H%M%s).sh"
    if [[ ! -d ${bak_dir_name} ]]; then
      sudo mkdir -p ${bak_dir_name}
      echo -e "${Info} 创建备份文件夹${bak_dir_name}"
    fi
    wget ${update_shell_url} -O install.sh.new
    cp -f install.sh "${bak_file_name}"
    echo -e "${Info} 备份原install.sh为${bak_file_name}"
    mv -f install.sh.new install.sh
    echo -e "${Info} install.sh更新完成，请重新启动"
    exit 0
}

menu_napcat() {
  echo && echo -e "  zhenxun_bot 一键安装管理脚本termux容器版 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Sakura | github.com/AkashiCoin --
 ${Green_font_prefix} 0.${Font_color_suffix} 安装/升级 napcat
 ${Green_font_prefix} 1.${Font_color_suffix} 卸载 napcat
————————————
 ${Green_font_prefix} 2.${Font_color_suffix} 启动 napcat
 ${Green_font_prefix} 3.${Font_color_suffix} 停止 napcat
 ${Green_font_prefix} 4.${Font_color_suffix} 重启 napcat
————————————
 ${Green_font_prefix} 5.${Font_color_suffix} 更换 bot QQ 账号(待实现)
 ${Green_font_prefix} 6.${Font_color_suffix} 修改 napcat 配置文件
 ${Green_font_prefix} 7.${Font_color_suffix} 查看 napcat 日志
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 webui 信息
 ————————————
 ${Green_font_prefix} 9.${Font_color_suffix} 切换为 termux 菜单
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 postgresql 菜单
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 zhenxun_bot 菜单" && echo
if [[ -e "${napcat_DIR}/napcat" ]]; then
    check_pid_napcat
    if [[ -n "${PID}" ]]; then
      echo -e " 当前状态: napcat ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
    else
      echo -e " 当前状态: napcat ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
    fi
    cd ${napcat_DIR}/napcat/config
    pathName=$(jq '.bot_qq' qq_data.json | sed 's/\"//g')
    if [ -z "$pathName" ]; then
      echo -e "${Red_font_prefix}当前未登录bot qq"${Font_color_suffix}
    else
      echo -e " 当前bot qq：${Green_font_prefix}${pathName}"${Font_color_suffix}
    fi
  else
      echo -e " 当前状态: napcat ${Red_font_prefix}未安装${Font_color_suffix}"
  fi
  echo
  read -erp " 请输入数字 [0-10]:" num
  case "$num" in
  0)
    update_napcat
    ;;
  1)
    Uninstall_napcat
    ;;
  2)
    Start_napcat
    ;;
  3)
    Stop_napcat
    ;;
  4)
    Restart_napcat
    ;;
  5)
    menu_napcat
    ;;
  6)
    Set_config_napcat
    ;;
  7)
    View_napcat_log
    ;;  
  8)
    View_napcat_webui_info
    ;;
  9)
    menu_termux
    ;;
  10)
    menu_postgresql
    ;;
  11)
    menu_zhenxun
    ;;
  *)
    echo "请输入正确数字 [0-10]" && menu_napcat
    ;;
  esac
}

menu_postgresql() {
  echo && echo -e "  zhenxun_bot 一键安装管理脚本termux容器版 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Sakura | github.com/AkashiCoin --
 ${Green_font_prefix} 0.${Font_color_suffix} 启动 postgresql 数据库
 ${Green_font_prefix} 1.${Font_color_suffix} 重启 postgresql 数据库
 ${Green_font_prefix} 2.${Font_color_suffix} 停止 postgresql 数据库
  ————————————
 ${Green_font_prefix} 3.${Font_color_suffix} 安装 postgresql 数据库
 ${Green_font_prefix} 4.${Font_color_suffix} 卸载 postgresql 数据库
  ————————————
 ${Green_font_prefix} 5.${Font_color_suffix} 创建新数据库(待实现)
 ${Green_font_prefix} 6.${Font_color_suffix} 修改数据库密码(待实现)
 ${Green_font_prefix} 7.${Font_color_suffix} 查看数据库信息
  ————————————
 ${Green_font_prefix} 8.${Font_color_suffix} 导出/导入数据库备份(待实现)
  ————————————
 ${Green_font_prefix} 9.${Font_color_suffix} 切换为 termux 菜单
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 napcat 菜单
 ${Green_font_prefix}11.${Font_color_suffix} 切换为 zhenxun_bot 菜单" && echo
  psql_dir=$(which psql)
  if [[ ! -z "$psql_dir" ]]; then
    check_pid_postgres
    if [[ -n "${PID}" ]]; then
      echo -e " 当前状态: postgres ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
    else
      echo -e " 当前状态: postgres ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
    fi
  else
      echo -e " 当前状态: postgres ${Red_font_prefix}未安装${Font_color_suffix}"
  fi
  echo
  read -erp " 请输入数字 [0-10]:" num
  case "$num" in
  0)
    Start_postgresql 
    ;;
  1)
    Restart_postgresql 
    ;;
  2)
    Stop_postgresql 
    ;;
  3)
    Install_postgresql 
    ;;
  4)
    Uninstall_postgresql
    ;;
  5)
    menu_postgresql 
    ;;
  6)
    Set_dns 
    ;;
  7)
    View_postgresql_info 
    ;;  
  8)
    menu_postgresql 
    ;;
  9)
    menu_napcat
    ;;
  10)
    menu_zhenxun
    ;;
  11)
    menu_zhenxun
    ;;
  *)
    echo "请输入正确数字 [0-10]" && menu_postgresql
    ;;
  esac
}

menu_termux() {
  echo && echo -e "  zhenxun_bot 一键安装管理脚本termux容器版 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Sakura | github.com/AkashiCoin --
 ${Green_font_prefix} 0.${Font_color_suffix} 修改 dns
 ${Green_font_prefix} 1.${Font_color_suffix} 修改 apt 源
 ${Green_font_prefix} 2.${Font_color_suffix} 修改 pip 源
  ————————————
 ${Green_font_prefix} 3.${Font_color_suffix} 设置 zhenxun napcat 端口
 ${Green_font_prefix} 4.${Font_color_suffix} 自动检测 zhenxun_bot 依赖
  ————————————
 ${Green_font_prefix} 5.${Font_color_suffix} 切换为 postgresql 菜单
 ${Green_font_prefix} 6.${Font_color_suffix} 切换为 napcat 菜单
 ${Green_font_prefix} 7.${Font_color_suffix} 切换为 zhenxun_bot 菜单" && echo
  psql_dir=$(which psql)
  if [[ ! -z "$psql_dir" ]]; then
    check_pid_postgres
    if [[ -n "${PID}" ]]; then
      echo -e " 当前状态: postgres ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
    else
      echo -e " 当前状态: postgres ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
    fi
  else
      echo -e " 当前状态: postgres ${Red_font_prefix}未安装${Font_color_suffix}"
  fi
  echo
  read -erp " 请输入数字 [0-10]:" num
  case "$num" in
  0)
    Set_dns
    ;;
  1)
    Set_apt_source
    ;;
  2)
    Set_pip_Mirror
    ;;
  3)
    Set_Port
    ;;
  4)
    check_module
    ;;
  5)
    menu_postgresql
    ;;
  6)
    menu_napcat
    ;;
  7)
    menu_zhenxun
    ;;  
  *)
    echo "请输入正确数字 [0-10]" && menu_termux
    ;;
  esac
}

menu_zhenxun() {
  echo && echo -e "  zhenxun_bot 一键安装管理脚本termux容器版 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Sakura | github.com/AkashiCoin --
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 zhenxun_bot + napcat
————————————
 ${Green_font_prefix} 2.${Font_color_suffix} 启动 zhenxun_bot
 ${Green_font_prefix} 3.${Font_color_suffix} 停止 zhenxun_bot
 ${Green_font_prefix} 4.${Font_color_suffix} 重启 zhenxun_bot
————————————
 ${Green_font_prefix} 5.${Font_color_suffix} 设置 管理员账号
 ${Green_font_prefix} 6.${Font_color_suffix} 修改 zhenxun_bot 配置文件
 ${Green_font_prefix} 7.${Font_color_suffix} 查看 zhenxun_bot 日志
————————————
 ${Green_font_prefix} 8.${Font_color_suffix} 卸载 zhenxun_bot + napcat
 ${Green_font_prefix} 9.${Font_color_suffix} 切换为 termux 菜单
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 napcat 菜单
 ${Green_font_prefix}11.${Font_color_suffix} 切换为 postgresql 菜单" && echo
  if [[ -e "${WORK_DIR}/zhenxun_bot/bot.py" ]]; then
    check_pid_zhenxun
    if [[ -n "${PID}" ]]; then
      echo -e " 当前状态: zhenxun_bot ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
    else
      echo -e " 当前状态: zhenxun_bot ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
    fi
  else
      echo -e " 当前状态: zhenxun_bot ${Red_font_prefix}未安装${Font_color_suffix}"
  fi
  echo
  read -erp " 请输入数字 [0-10]:" num
  case "$num" in
  0)
    Update_Shell
    ;;
  1)
    Install_zhenxun_bot
    ;;
  2)
    Start_zhenxun_bot
    ;;
  3)
    Stop_zhenxun_bot
    ;;
  4)
    Restart_zhenxun_bot
    ;;
  5)
    Set_config_admin
    ;;
  6)
    Set_config_zhenxun
    ;;
  7)
    View_zhenxun_log
    ;;
  8)
    Uninstall_All
    ;;
  9)
    menu_termux
    ;;
  10)
    menu_napcat
    ;;
  11)
    menu_postgresql
    ;;
  *)
    echo "请输入正确数字 [0-10]" && menu_zhenxun
    ;;
  esac
}
menu_zhenxun
