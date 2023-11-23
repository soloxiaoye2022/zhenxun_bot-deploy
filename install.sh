#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

update_shell_url="https://mirror.ghproxy.com/https://raw.githubusercontent.com/soloxiaoye2022/zhenxun_bot-deploy/main/install.sh"
zhenxun_url="https://github.com/HibiKier/zhenxun_bot.git"
WORK_DIR="/root"
TMP_DIR="$(mktemp -d)"
GOCQ_DIR="/root/go-cqhttp"
ZX_DIR="/root/zhenxun_bot/"
python_v="python3.8"
which python3.9 && python_v="python3.9"
sh_ver="1.0.4.1"
ghproxy="https://mirror.ghproxy.com/"
mirror_url='"https://pypi.org/simple"'
ssh_port="8022"
mix="1024"
max="49151"
dns="8.8.8.8"

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
    elif grep -q -E -i "debian" /etc/issue; then
        release="debian" 
    elif grep -q -E -i "ubuntu" /etc/issue; then
        release="ubuntu"
    elif grep -q -E -i "centos|red hat|redhat" /etc/issue; then
        release="centos"
    elif grep -q -E -i "Arch|Manjaro" /etc/issue; then
        release="archlinux"
    elif grep -q -E -i "debian" /proc/version; then
        release="debian"
    elif grep -q -E -i "ubuntu" /proc/version; then
        release="ubuntu"
    elif grep -q -E -i "centos|red hat|redhat" /proc/version; then
        release="centos"
    else
        echo -e "zhenxun_bot 暂不支持该Linux发行版" && exit 1
    fi
    bit=$(uname -m)
    
}

check_installed_zhenxun_status() {
  [[ ! -e "${WORK_DIR}/zhenxun_bot/bot.py" ]] && echo -e "${Error} zhenxun_bot 没有安装，请检查 !" && exit 1
}

check_installed_cqhttp_status() {
  [[ ! -e "${WORK_DIR}/go-cqhttp/go-cqhttp" ]] && echo -e "${Error} go-cqhttp 没有安装，请检查 !" && exit 1
}

check_pid_zhenxun() {
  #PID=$(ps -ef | grep "sergate" | grep -v grep | grep -v ".sh" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
  PID=$(pgrep -f "bot.py")
}

check_pid_cqhttp() {
  #PID=$(ps -ef | grep "sergate" | grep -v grep | grep -v ".sh" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
  PID=$(pgrep -f "go-cqhttp")
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
  if [ $mirror_num -ge 1 -a $mirror_num -le 5 ];then
     sed -i "s|url.*|url = "${mirror_url}"|g" ${WORK_DIR}/zhenxun_bot/pyproject.toml
     pip_url=$(echo $mirror_url | sed 's/\"//g')
     pip config set global.index-url "${pip_url}"
  elif [ $mirror_num -gt 6 ]; then
     echo -e"${Info} 你可能没有输入正确的选项?"
     Set_pip_Mirror
  fi
}

Set_ghproxy() {
  echo -e "${Info} 是否使用 ghproxy 代理git相关的下载？(中国大陆建议使用)"
  read -erp "请选择 [y/n], 默认为 y:" ghproxy_check
  [[ -z "${ghproxy_check}" ]] && ghproxy_check='y'
  [[ ${ghproxy_check} == 'n' ]] && ghproxy=""
}

Installation_dependency() {
    if [[ ${release} == "centos" ]]; then
        yum -y update
        yum install -y git fontconfig mkfontscale epel-release wget vim curl zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make libffi-devel
        if  ! which python3.8 && ! which python3.9; then
            wget https://mirrors.huaweicloud.com/python/3.9.10/Python-3.9.10.tgz -O ${TMP_DIR}/Python-3.9.10.tgz && \
                tar -zxf ${TMP_DIR}/Python-3.9.10.tgz -C ${TMP_DIR}/ &&\
                cd ${TMP_DIR}/Python-3.9.10 --with-ensurepip=install && \
                ./configure && \
                make -j $(cat /proc/cpuinfo |grep "processor"|wc -l) && \
                make altinstall
            python_v="python3.9"
        fi
        ${python_v} <(curl -s -L https://bootstrap.pypa.io/get-pip.py) || echo -e "${Tip} pip 安装出错..."
        rpm -v --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
        rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
        yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
        yum install -y postgresql13-server ffmpeg ffmpeg-devel atk at-spi2-atk cups-libs libxkbcommon libXcomposite libXdamage libXrandr mesa-libgbm gtk3
        /usr/pgsql-13/bin/postgresql-13-setup initdb
        systemctl enable postgresql-13
        systemctl start postgresql-13
        cat > /tmp/sql.sql <<-EOF
CREATE USER zhenxun WITH PASSWORD 'zxpassword';
CREATE DATABASE zhenxun OWNER zhenxun;
EOF
        su postgres -c "psql -f /tmp/sql.sql"
    elif [[ ${release} == "debian" ]]; then
        apt-get update
        apt-get install -y wget ttf-wqy-zenhei xfonts-intl-chinese wqy* build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev
        if  ! which python3.8 && ! which python3.9;then
            wget https://mirrors.huaweicloud.com/python/3.9.10/Python-3.9.10.tgz -O ${TMP_DIR}/Python-3.9.10.tgz && \
                tar -zxf ${TMP_DIR}/Python-3.9.10.tgz -C ${TMP_DIR}/ &&\
                cd ${TMP_DIR}/Python-3.9.10 && \
                ./configure --with-ensurepip=install && \
                make -j $(cat /proc/cpuinfo |grep "processor"|wc -l) && \
                make altinstall
            python_v="python3.9"
        fi
        apt-get install -y \
            vim \
            wget \
            git \
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
            libasound2 \
            python3-pip
        #${python_v} <(curl -s -L https://bootstrap.pypa.io/get-pip.py) || echo -e "${Tip} pip 安装出错..."
        Install_postgresql
    elif [[ ${release} == "ubuntu" ]]; then
        apt-get update
        apt-get install -y software-properties-common ttf-wqy-zenhei ttf-wqy-microhei fonts-arphic-ukai fonts-arphic-uming
        fc-cache -f -v
        echo -e "\n" | add-apt-repository ppa:deadsnakes/ppa
        if  ! which python3.8 && ! which python3.9;then
            apt-get install -y python3.9-full
            python_v="python3.9"
        fi
        apt-get install -y \
            vim \
            wget \
            git \
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
            libasound2 \
            python3-pip
        #${python_v} <(curl -s -L https://bootstrap.pypa.io/get-pip.py) || echo -e "${Tip} pip 安装出错..."
        Install_postgresql
    elif [[ ${release} == "archlinux" ]]; then
        pacman -Sy python python-pip unzip --noconfirm
    fi
    which python3.10  && python_v="python3.10"
    which python3.9  && python_v="python3.9"
    which python3.8 && python_v="python3.8"
    [[ ! -e /usr/bin/python3 ]] && ln -s /usr/bin/${python_v} /usr/bin/python3
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
    echo -e "${Error} go-cqhttp 不支持该内核版本(${get_arch})..." && exit 1
  fi
}

check_module() {
check_pid_zhenxun
log="/root/zhenxun_bot/zhenxun_bot.log"
dir="/root/zhenxun_bot"
echo -e "${Info} 自动检测真寻确实依赖并自动安装"
if [[ -e "${log}" ]]; then
[[ ! -z ${PID} ]] && kill -9 ${PID}
cd ${dir}
nohup poetry run ${python_v} bot.py > zhenxun_bot.log 2>&1 & 
echo -e "${Info} 正在检测 zhenxun_bot 缺失依赖(需要约1分钟)"
sleep 60
[[ ! -z ${PID} ]] && kill -9 ${PID}
cat ${log} | grep "No module named" | awk -F "'" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g' | sed 's/ /\n/' > /root/zhenxun_bot/requests.txt
Install_module
else
echo -e "${Error} log文件不存在,即将自动启动 zhenxun_bot 并生成log文件"
cd ${dir}
nohup poetry run ${python_v} bot.py > zhenxun_bot.log 2>&1 & 
echo -e "${Info} log文件已生成"
sleep 5
check_module
fi

}

Install_module() {
module=$(sort -u /root/zhenxun_bot/requests.txt | uniq | sed '/^enchant/d')
echo ${module} > /root/zhenxun_bot/requests.txt
if [[ ! -z "${module}" ]]; then
cd ${dir}
echo -e "${Info} 本次检测到以下版本依赖需要安装,如果安装失败请手动进入虚拟环境执行poetry install"
sleep 1
poetry run pip install $module -i ${pip_url}
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
 while true; do
    cd "${TMP_DIR}" || exit 1
    echo -e "${Info} 开始下载最新版 zhenxun_bot ..."
    git clone "${ghproxy}${zhenxun_url}" -b main
    if [ $? = 0 ] ; then
     break
  else
     echo -e "${Error} zhenxun_bot下载失败！3秒后重试下载..."
  fi
  sleep 3
 done
    echo -e "${Info} 开始下载最新版 go-cqhttp ..."
    Download_gocq
    cd "${WORK_DIR}" || exit 1
    mv "${TMP_DIR}/zhenxun_bot" ./
    mkdir -p "go-cqhttp"
    tar -zxf "${TMP_DIR}/go-cqhttp.tar.gz" -C ./go-cqhttp/
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

Download_gocq() {
 while true; do
  gocq_version=$(wget -O- -t1 -T2 "https://api.github.com/repos/Mrs4s/go-cqhttp/releases/latest" --no-check-certificate | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
     wget -O- "${ghproxy}https://github.com/Mrs4s/go-cqhttp/releases/download/${gocq_version}/go-cqhttp_$(uname -s)_${arch}.tar.gz" --no-check-certificate -O go-cqhttp.tar.gz
   if [ $? = 0 ] ; then
      break
   else
      echo -e "${Error} go-cqhttp 下载失败！3秒后重试下载..."
      sleep 3
   fi
 done
}

Set_config_admin() {
    echo -e "${Info} 请输入管理员QQ账号(也就超级用户账号):[QQ]"
    read -erp "管理员QQ:" admin_qq
    [[ -z "$admin_qq" ]] && admin_qq=""
    cd ${WORK_DIR}/zhenxun_bot && sed -i "s/SUPERUSERS.*/SUPERUSERS=[\"$admin_qq\"]/g" .env.dev || echo -e "${Error} 配置文件不存在！请检查zhenxun_bot是否安装正确!"
    echo -e "${Info} 设置成功!管理员QQ: ["${Green_font_prefix}${admin_qq}${Font_color_suffix}"]"
    
}

Set_config_bot() {
    echo -e "${Info} 请输入Bot QQ账号:[QQ]"
    read -erp "Bot QQ:" bot_qq
    [[ -z "$bot_qq" ]] && bot_qq=""
    if [ $bot_qq = $admin_qq ]; then
      echo -e "${Error} Bot QQ["${Green_font_prefix}$bot_qq${Font_color_suffix}"]不能与管理员QQ账号["${Green_font_prefix}$admin_qq${Font_color_suffix}"]一致"
      Set_config_bot
    else
      cd ${WORK_DIR}/go-cqhttp && sed -i "s/uin:.*/uin: $bot_qq # QQ账号/g" config.yml || echo -e "${Error} 配置文件不存在！请检查go-cqhttp是否安装正确!"
      echo -e "${Info} 设置成功!Bot QQ: ["${Green_font_prefix}${bot_qq}${Font_color_suffix}"]"
    fi
    echo -e "${Info} 请选择Bot 登陆方式(默认为扫码登陆)"
    read -erp "请选择 [1-2], 默认为 1:" login_mode
    if [[ ${login_mode} == '2' ]]; then
        echo -e "${Info} 请下载滑动验证助手进行滑条验证https://github.com/KasukuSakura/mirai-login-solver-sakura/releases"
        echo -e "${Info} 请输入Bot QQ密码:[Password]"
        while true; do
            read -erp "Bot Password:" bot_password
            read -erp "${Info} 请再次输入密码:" again_password
            if [ $again_password != $bot_password ]; then
                echo -e "${Error} 两次输入的密码不一致，请重新输入!"
            else
                break
            fi
        done
        cd ${WORK_DIR}/go-cqhttp && sed -i "s/password:.*/password: '$bot_password' # 密码为空时使用扫码登录/g" config.yml || echo -e "${Error} 配置文件不存在！请检查go-cqhttp是否安装正确!"
        echo -e "${Info} 设置成功!Bot Password: ["${Green_font_prefix}${bot_password}${Font_color_suffix}"]"
    fi
}

Set_config() {
     if [[ -e "${WORK_DIR}/go-cqhttp/config.yml" ]]; then
        echo -e "${Info} go-cqhttp 配置文件已存在，跳过生成"
    else
        cd ${WORK_DIR}/go-cqhttp && echo -e "3\n" | ./go-cqhttp > /dev/null 2>&1
    Set_Port 
    Set_config_admin
    Set_config_bot 
    echo -e "${Info} 开始设置 PostgreSQL 连接语句..."
    cd ${WORK_DIR}/zhenxun_bot && sed -i 's|bind.*|bind: str = "postgres://zhenxun:zxpassword@localhost:5432/zhenxun"|g' configs/config.py
  fi
}

Set_Port() {
echo -e "${Info} 请设置zhenxun_bot gocq通信端口:取值范围["${Green_font_prefix}${mix}-${max}${Font_color_suffix}"]"
    read -erp "Port:" Port
    [[ -z "${Port}" ]] && Port=""
      if [ ${Port} -ge ${mix} -a ${Port} -le ${max} ]; then
        cd ${WORK_DIR}/zhenxun_bot  && sed -i "s|PORT.*|PORT = ${Port}|g" .env.dev && cd ${WORK_DIR}/go-cqhttp && sudo sed -i "s|universal:.*|universal: ws://127.0.0.1:${Port}/onebot/v11/ws|g" config.yml || (echo -e "${Error} 配置文件不存在！请检查 zhenxun_bot 或 gocq是否安装正确!" && exit 1)
    echo -e "${Info} 设置成功!端口: ["${Green_font_prefix}${Port}${Font_color_suffix}"]"
      else 
      echo -e "${Error} 端口设置错误，取值范围["${Green_font_prefix}${mix}-${max}${Font_color_suffix}"]"
      Set_Port
     fi     
}
Restart_zx_gocq() {
     Set_Port
     Restart_zhenxun_bot
     Restart_cqhttp
}
Start_zhenxun_bot() {
    check_installed_zhenxun_status
    check_pid_zhenxun
    [[ -n ${PID} ]] && echo -e "${Error} zhenxun_bot 正在运行，请检查 !" && exit 1
    Start_postgresql
    cd ${WORK_DIR}/zhenxun_bot
    nohup poetry run python3 bot.py >> zhenxun_bot.log 2>&1 &
    echo -e "${Info} zhenxun_bot 开始运行..."
}

Stop_zhenxun_bot() {
    check_installed_zhenxun_status
    check_pid_zhenxun
    [[ -z ${PID} ]] && echo -e "${Error} zhenxun_bot 没有运行，请检查 !" && exit 1
    kill -9 ${PID}
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
    vim ${WORK_DIR}/zhenxun_bot/configs/config.yaml
}

Start_cqhttp() {
    check_installed_cqhttp_status
    check_pid_cqhttp
    [[ -n ${PID} ]] && echo -e "${Error} go-cqhttp 正在运行，请检查 !" && exit 1
    cd ${WORK_DIR}/go-cqhttp
    nohup ./go-cqhttp -faststart >> go-cqhttp.log 2>&1 &
    echo -e "${Info} go-cqhttp 开始运行..."
    sleep 2
}

Start_postgresql() {
INODE_NUM=`ls -ali / | sed '2!d' |awk {'print $1'}`
if [ $INODE_NUM == '2' ]; then
systemctl start postgresql
else
su postgres <<-EOF
     pg_createcluster 13 main --start
     chmod -R 700 /etc/ssl/private/ssl-cert-snakeoil.key
     chmod -R 700 /etc/ssl/private/ssl-cert-snakeoil.key
     /etc/init.d/postgresql start
EOF

fi
echo -e "${Info} pgsql数据库已重启"
}

Stop_postgresql() {
INODE_NUM=`ls -ali / | sed '2!d' |awk {'print $1'}`
if [ $INODE_NUM == '2' ]; then
systemctl stop postgresql
else
su postgres <<-EOF
     /etc/init.d/postgresql stop
EOF

fi
echo -e "${Info} pgsql数据库已停止"
}

Restart_postgresql() {
Stop_postgresql
Start_postgresql
}

Stop_cqhttp() {
    check_installed_cqhttp_status
    check_pid_cqhttp
    [[ -z ${PID} ]] && echo -e "${Error} cqhttp 没有运行，请检查 !" && exit 1
    kill -9 ${PID}
    echo -e "${Info} go-cqhttp 停止运行..."
}

Restart_cqhttp() {
    Stop_cqhttp
    Start_cqhttp
}

View_cqhttp_log() {
    tail -f -n 100 ${WORK_DIR}/go-cqhttp/go-cqhttp.log
}

Set_config_cqhttp() {
    vim ${WORK_DIR}/go-cqhttp/config.yml
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
     symbol=`echo ${input: -1}`
     character="/"
    if [ "$sybmol" = "character"  ];
     then
      sed -i "s@https://.*.c../\|http://.*.c../\|https://.*.c./\|http://.*.c./\|https://.*.org/\|http://.*.org/\|https://.*.net/\|http://.*.net/@'$input'@g" /etc/apt/sources.list && apt update
     else
      sed -i "s@https://.*.c..\|http://.*.c..\|https://.*.c.\|http://.*.c.\|https://.*.org\|http://.*.org\|https://.*.net|http://.*.net@'$input'@g" /etc/apt/sources.list && apt update
   fi
   echo -e "${Info} apt源已修改为 ${input}"
fi
}

Exit_cqhttp() {
    cd ${WORK_DIR}/go-cqhttp
    rm -f session.token
    echo -e "${Info} go-cqhttp 账号已退出..."
    Stop_cqhttp
    sleep 3
    menu_cqhttp
}

Set_dependency() {
    cd ${WORK_DIR}/zhenxun_bot
    Set_pip_Mirror
    ${python_v} -m pip install poetry
    poetry env use ${python_v}
    poetry install
    poetry run playwright install-deps chromium
    poetry run playwright install chromium

}

Install_sshd() {
INODE_NUM=`ls -ali / | sed '2!d' |awk {'print $1'}`
if [ ! $INODE_NUM == '2' ]; then
    echo -e "${Info} 开始安装ssh服务"
        apt install ssh -y
        echo -e "${Info} 安装完成,检查ssh配置文件"
        wget https://gitee.com/soloxiaoye/zhenxun_bot_tool/attach_files/1095259/download/sshd_config -qO /etc/ssh/sshd_config
        echo -e "${Info} 请设置ssh端口，取值范围["${Green_font_prefix}${mix}-${max}${Font_color_suffix}"]"
   Set_hhd_port
fi
}


Set_hhd_port() {
read -erp "Port:" num
    [[ -z "$num" ]] && num="${ssh_port}"
    if [ ${num} -ge ${mix} -a ${num} -le ${max} ]; then
    cd /etc/ssh/ && sed -i "s|Port.*|Port ${num}|g" sshd_config || echo -e "${Error} 配置文件不存在！请检查ssh是否安装正确!"
    echo -e "${Info} 设置成功!端口: ["${Green_font_prefix}${num}${Font_color_suffix}"]"
        echo -e "${Info} 启动ssh远程连接服务"
        /etc/init.d/ssh restart
    else 
      echo -e "${Error} 端口设置错误，取值范围["${Green_font_prefix}${mix}-${max}${Font_color_suffix}"]"
      Set_hhd_port
    fi

}

Uninstall_All() {
  echo -e "${Tip} 是否完全卸载 zhenxun_bot 和 go-cqhttp？(此操作不可逆)"
  read -erp "请选择 [y/n], 默认为 n:" uninstall_check
  [[ -z "${uninstall_check}" ]] && uninstall_check='n'
  if [[ ${uninstall_check} == 'y' ]]; then
    cd ${WORK_DIR}
    check_pid_zhenxun
    [[ -z ${PID} ]] || kill -9 ${PID}
    echo -e "${Info} 开始卸载 zhenxun_bot..."
    rm -rf zhenxun_bot || echo -e "${Error} zhenxun_bot 卸载失败！"
    check_pid_cqhttp
    [[ -z ${PID} ]] || kill -9 ${PID}
    echo -e "${Info} 开始卸载 go-cqhttp..."
    rm -rf go-cqhttp || echo -e "${Error} go-cqhttp 卸载失败！"
    echo -e "${Info} 感谢使用真寻bot，期待于你的下次相会！"
  fi
  echo -e "${Info} 操作已取消..." && menu_zhenxun
}

Install_zhenxun_bot() {
    check_root
    [[ -e "${WORK_DIR}/zhenxun_bot/bot.py" ]] && echo -e "${Error} 检测到 zhenxun_bot 已安装 !" && exit 1
    startTime=`date +%s`
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
    endTime=`date +%s`
    ((outTime=($endTime-$startTime)))
    echo -e "${Info} 安装用时 ${outTime} s ..."
    Start_zhenxun_bot
    Start_cqhttp
    echo -e "${Info} 请扫描二维码登录 bot，bot 账号登录完成后，使用Ctrl + C退出 !"
    View_cqhttp_log
    
}

Install_postgresql() {
INODE_NUM=`ls -ali / | sed '2!d' |awk {'print $1'}`
if [ $INODE_NUM == '2' ];
then
      echo -e "${Info} 开始安装pgsql数据库"
      apt-get install postgresql postgresql-contrib -y
      echo -e "${Info} 设置pgsql数据库开机自启"
      systemctl enable postgresql
      systemctl restart postgresql
else
      echo -e "${Info} 开始安装pgsql数据库"
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
     echo -e "${Info} 检测到pgsql数据库文件权限问题...\n开始修复pgsql数据库"
     chmod -R 700 /etc/ssl/private/ssl-cert-snakeoil.key
     chmod -R 700 /etc/ssl/private/ssl-cert-snakeoil.key
     echo -e "${Info} 修复完成，启动pgsql数据库"
EOF
fi
Start_postgresql
check_pgsql
fi
}

check_pgsql(){
databaseuser="zhenxun"
result=`su postgres << EOF
echo -e "SELECT u.usename FROM pg_catalog.pg_user u  where u.usename='${databaseuser}';\n" | psql 
EOF`
usename=`echo $result | rev | awk -F' ' '{print $2}' | cut -b 1`
dbname=`su postgres << EOF
psql -l | grep $databaseuser | wc -l
EOF`
  if [ "$usename" -eq "0" -a "$dbname" -eq "0" ]; then
  su postgres <<-EOF
echo -e "CREATE USER zhenxun WITH PASSWORD 'zxpassword';\n CREATE DATABASE zhenxun OWNER zhenxun;\n" | psql
EOF
   echo -e "${Info} 创建数据库成功。用户名 $databaseuser\n数据库名 $databaseuser\n密码zxpassword"
 else
  echo -e "${Tip} 用户名 ${databaseuser} 或者 数据库 ${databaseuser}已存在"
fi
echo -e "${Info} pgsql数据库安装完成"
}


Update_Shell(){
    echo -e "${Info} 开始更新install.sh"
    bak_dir_name="sh_bak/"
    bak_file_name="${bak_dir_name}install.`date +%Y%m%d%H%M%s`.sh"
    if [[ ! -d ${bak_dir_name} ]]; then
        sudo mkdir -p ${bak_dir_name}
        echo -e "${Info} 创建备份文件夹${bak_dir_name}"
    fi
    wget ${update_shell_url} -O install.sh.new
    cp -f install.sh ${bak_file_name}
    echo -e "${Info} 备份原install.sh为${bak_file_name}"
    mv -f install.sh.new install.sh
    echo -e "${Info} install.sh更新完成，请重新启动"
    exit 0
}

menu_cqhttp() {
  echo && echo -e "  go-cqhttp 一键安装管理脚本修改版 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Sakura | github.com/AkashiCoin --
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 zhenxun_bot + go-cqhttp
————————————
 ${Green_font_prefix} 2.${Font_color_suffix} 启动 go-cqhttp
 ${Green_font_prefix} 3.${Font_color_suffix} 停止 go-cqhttp
 ${Green_font_prefix} 4.${Font_color_suffix} 重启 go-cqhttp
————————————
 ${Green_font_prefix} 5.${Font_color_suffix} 设置 bot QQ账号/密码
 ${Green_font_prefix} 6.${Font_color_suffix} 修改 go-cqhttp 配置文件
 ${Green_font_prefix} 7.${Font_color_suffix} 查看 go-cqhttp 日志
————————————
 ${Green_font_prefix} 8.${Font_color_suffix} 退出 go-cqhttp 账号
 ${Green_font_prefix} 9.${Font_color_suffix} 切换为 termux 菜单
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 zhenxun_bot 菜单" && echo
if [[ -e "${WORK_DIR}/go-cqhttp/go-cqhttp" ]]; then
    check_pid_cqhttp
    if [[ -n "${PID}" ]]; then
      echo -e " 当前状态: go-cqhttp ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
    else
      echo -e " 当前状态: go-cqhttp ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
    fi
  else
    if [[ -e "${file}/go-cqhttp/go-cqhttp" ]]; then
      check_pid_cqhttp
      if [[ -n "${PID}" ]]; then
        echo -e " 当前状态: go-cqhttp ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
      else
        echo -e " 当前状态: go-cqhttp ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
      fi
    else
      echo -e " 当前状态: go-cqhttp ${Red_font_prefix}未安装${Font_color_suffix}"
    fi
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
    Start_cqhttp
    ;;
  3)
    Stop_cqhttp
    ;;
  4)
    Restart_cqhttp
    ;;
  5)
    Set_config_bot
    ;;
  6)
    Set_config_cqhttp
    ;;
  7)
    View_cqhttp_log
    ;;  
  8)
    Exit_cqhttp
    ;;
  9)
    menu_termux
    ;;
  10)
    menu_zhenxun
    ;;
  *)
    echo "请输入正确数字 [0-10]"
    ;;
  esac
}

menu_termux() {
  echo && echo -e "  go-cqhttp 一键安装管理脚本修改版 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Sakura | github.com/AkashiCoin --
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 postgresql 数据库
 ${Green_font_prefix} 2.${Font_color_suffix} 重启 postgresql 数据库
 ${Green_font_prefix} 3.${Font_color_suffix} 停止 postgresql 数据库
 ————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 自动检测 zhenxun_bot 依赖
 ${Green_font_prefix} 5.${Font_color_suffix} 设置 zhenxun gocq 端口
 ${Green_font_prefix} 6.${Font_color_suffix} 修改 dns
 ————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 修改 pip 源
 ${Green_font_prefix} 8.${Font_color_suffix} 修改 apt 源
————————————
 ${Green_font_prefix} 9.${Font_color_suffix} 切换为 go-cqhttp 菜单
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 zhenxun_bot 菜单" && echo
  if [[ -e "${WORK_DIR}/go-cqhttp/go-cqhttp" ]]; then
    check_pid_cqhttp
    if [[ -n "${PID}" ]]; then
      echo -e " 当前状态: go-cqhttp ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
    else
      echo -e " 当前状态: go-cqhttp ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
    fi
  else
    if [[ -e "${file}/go-cqhttp/go-cqhttp" ]]; then
      check_pid_cqhttp
      if [[ -n "${PID}" ]]; then
        echo -e " 当前状态: go-cqhttp ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
      else
        echo -e " 当前状态: go-cqhttp ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
      fi
    else
      echo -e " 当前状态: go-cqhttp ${Red_font_prefix}未安装${Font_color_suffix}"
    fi
  fi
  echo
  read -erp " 请输入数字 [0-10]:" num
  case "$num" in
  0)
    Update_Shell
    ;;
  1)
    Install_postgresql
    ;;
  2)
    Restart_postgresql
    ;;
  3)
    Stop_postgresql
    ;;
  4)
    check_module
    ;;
  5)
    Set_Port
    ;;
  6)
    Set_dns
    ;;
  7)
    Set_pip_Mirror
    ;;  
  8)
    Set_apt_source
    ;;
  9)
    menu_cqhttp
    ;;
  10)
    menu_zhenxun
    ;;
  *)
    echo "请输入正确数字 [0-10]"
    ;;
  esac
}

menu_zhenxun() {
  echo && echo -e "  zhenxun_bot 一键安装管理脚本修改版 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Sakura | github.com/AkashiCoin --
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 zhenxun_bot + go-cqhttp
————————————
 ${Green_font_prefix} 2.${Font_color_suffix} 启动 zhenxun_bot
 ${Green_font_prefix} 3.${Font_color_suffix} 停止 zhenxun_bot
 ${Green_font_prefix} 4.${Font_color_suffix} 重启 zhenxun_bot
————————————
 ${Green_font_prefix} 5.${Font_color_suffix} 设置 管理员账号
 ${Green_font_prefix} 6.${Font_color_suffix} 修改 zhenxun_bot 配置文件
 ${Green_font_prefix} 7.${Font_color_suffix} 查看 zhenxun_bot 日志
————————————
 ${Green_font_prefix} 8.${Font_color_suffix} 卸载 zhenxun_bot + go-cqhttp
 ${Green_font_prefix} 9.${Font_color_suffix} 切换为 termux 菜单
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 go-cqhttp 菜单" && echo
  if [[ -e "${WORK_DIR}/zhenxun_bot/bot.py" ]]; then
    check_pid_zhenxun
    if [[ -n "${PID}" ]]; then
      echo -e " 当前状态: zhenxun_bot ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
    else
      echo -e " 当前状态: zhenxun_bot ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
    fi
  else
    if [[ -e "${file}/zhenxun_bot/bot.py" ]]; then
      check_pid_zhenxun
      if [[ -n "${PID}" ]]; then
        echo -e " 当前状态: zhenxun_bot ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
      else
        echo -e " 当前状态: zhenxun_bot ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
      fi
    else
      echo -e " 当前状态: zhenxun_bot ${Red_font_prefix}未安装${Font_color_suffix}"
    fi
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
    menu_cqhttp
    ;;
  *)
    echo "请输入正确数字 [0-10]"
    ;;
  esac
}
menu_zhenxun
