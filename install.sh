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
musicSignUrl="http://napcat-sign.wumiao.wang:2052/music_sign"
ssh_port="8022"
mix="1024"
max="49151"
dns="8.8.8.8"

# 检查Python版本（真寻bot要求最低Python 3.10）
check_python_version() {
    local min_version="3.10"
    local python_cmd=""
    
    # 检查已安装的Python版本
    for version in 3.12 3.11 3.10; do
        if command -v python${version} &> /dev/null; then
            python_cmd="python${version}"
            break
        fi
    done
    
    if [[ -n "$python_cmd" ]]; then
        # 验证版本号
        local actual_version=$($python_cmd -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        if [[ "$(printf '%s\n' "$min_version" "$actual_version" | sort -V | head -n1)" == "$min_version" ]]; then
            echo "$python_cmd"
            return 0
        fi
    fi
    
    return 1
}

# 自动安装Python 3.10+（使用包管理器而非编译）
install_python_minimal() {
    echo -e "${Info} 未检测到Python 3.10+，正在安装..."
    
    if [[ ${release} == "centos" ]]; then
        # CentOS 8+ 使用模块安装
        if [[ "$(rpm -E %{rhel})" -ge 8 ]]; then
            dnf module -y reset python36
            dnf module -y install python310
        else
            # CentOS 7 使用SCL
            yum -y install centos-release-scl
            yum -y install rh-python38
            echo "source /opt/rh/rh-python38/enable" >> /etc/profile
            source /opt/rh/rh-python38/enable
        fi
    elif [[ ${release} == "ubuntu" ]]; then
        apt-get update
        apt-get install -y python3.10 python3.10-venv python3.10-distutils
    elif [[ ${release} == "debian" ]]; then
        apt-get update
        apt-get install -y python3.10 python3.10-venv python3.10-distutils
    fi
    
    # 创建默认python3链接
    if command -v python3.10 &> /dev/null; then
        ln -sf /usr/bin/python3.10 /usr/local/bin/python3
        echo "python3.10"
        return 0
    fi
    
    return 1
}

# 主Python检查函数
setup_python() {
    python_v=$(check_python_version)
    
    if [[ -z "$python_v" ]]; then
        # 尝试安装
        if install_python_minimal; then
            python_v=$(check_python_version)
            if [[ -z "$python_v" ]]; then
                echo -e "${Error} Python 3.10+安装失败，请手动安装"
                exit 1
            fi
        else
            echo -e "${Error} 无法自动安装Python 3.10+，请手动安装"
            exit 1
        fi
    fi
    
    echo -e "${Info} 使用Python版本: $python_v"
    
    # 确保pip可用
    if ! command -v pip3 &> /dev/null; then
        apt-get install -y python3-pip || yum install -y python3-pip
    fi
}
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
    # 首先设置Python
    setup_python
    
    # 通用依赖包列表
    local common_packages="vim wget git zip unzip jq curl xvfb screen sqlite3 ffmpeg"
    local gui_packages="libgl1 libglib2.0-0 libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libxkbcommon0 libxcomposite1 libxrandr2 libgbm1 libgtk-3-0"
    
    if [[ ${release} == "centos" ]]; then
        yum -y update
        # CentOS特定包
        yum install -y epel-release xorg-x11-server-Xvfb fontconfig mkfontscale
        yum install -y ${common_packages}
        
        # 字体支持
        yum install -y cjkuni-ukai-fonts cjkuni-uming-fonts
        fc-cache -f -v
        
        # PostgreSQL (可选)
        if [[ "${install_postgresql}" == "y" ]]; then
            yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
            yum install -y postgresql13-server postgresql13-contrib
            /usr/pgsql-13/bin/postgresql-13-setup initdb
            systemctl enable postgresql-13
            systemctl start postgresql-13
            
            # 创建数据库用户
            su postgres -c "psql -c \"CREATE USER zhenxun WITH PASSWORD 'zxpassword';\""
            su postgres -c "psql -c \"CREATE DATABASE zhenxun OWNER zhenxun;\""
        fi
        
    elif [[ ${release} == "ubuntu" ]] || [[ ${release} == "debian" ]]; then
        apt-get update
        
        # Ubuntu/Debian通用包
        apt-get install -y software-properties-common ${common_packages}
        
        # 中文字体支持
        apt-get install -y fonts-noto-cjk fonts-noto-cjk-extra ttf-wqy-zenhei ttf-wqy-microhei
        fc-cache -f -v
        
        # 修复音频库冲突
        apt-get install -y libasound2 || apt-get install -y libasound2t64
        apt-get remove -y libfprint-2-2 2>/dev/null || true
        apt --fix-broken install -y
        
        # GUI相关包 (Ubuntu/Debian)
        apt-get install -y ${gui_packages}
        
        # PostgreSQL (可选)
        if [[ "${install_postgresql}" == "y" ]]; then
            if [[ ${release} == "ubuntu" ]]; then
                apt-get install -y postgresql postgresql-contrib
            else
                apt-get install -y postgresql-13 postgresql-contrib
            fi
            systemctl enable postgresql
            systemctl start postgresql
            
            # 创建数据库用户
            su postgres -c "psql -c \"CREATE USER zhenxun WITH PASSWORD 'zxpassword';\"" 2>/dev/null || true
            su postgres -c "psql -c \"CREATE DATABASE zhenxun OWNER zhenxun;\"" 2>/dev/null || true
        fi
        
    elif [[ ${release} == "archlinux" ]]; then
        pacman -Sy --noconfirm python python-pip ${common_packages} ${gui_packages}
    fi
    
    # 确保pip可用并设置国内源
    if ! command -v pip3 &> /dev/null; then
        if [[ ${release} == "centos" ]]; then
            yum install -y python3-pip
        else
            apt-get install -y python3-pip
        fi
    fi
    
    # 设置pip国内源
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/ 2>/dev/null || true
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

cleanup_test_processes() {
    # 清理可能的测试进程
    local pids=$(pgrep -f "poetry run.*bot.py" 2>/dev/null || true)
    if [[ -n "${pids}" ]]; then
        echo -e "${Info} 清理测试进程..."
        kill -9 ${pids} 2>/dev/null || true
        sleep 1
    fi
}

check_module() {
    local max_attempts=3
    local attempt=1
    local log_file="${WORK_DIR}/zhenxun_bot/zhenxun_bot.log"
    local requests_file="${WORK_DIR}/zhenxun_bot/requests.txt"
    local project_dir="${WORK_DIR}/zhenxun_bot"
    
    # 清理可能存在的测试进程
    cleanup_test_processes
    
    echo -e "${Info} 自动检测真寻缺失依赖并自动安装"
    
    # 确保项目目录存在
    if [[ ! -d "${project_dir}" ]]; then
        echo -e "${Error} 真寻BOT项目目录不存在: ${project_dir}"
        return 1
    fi
    
    cd "${project_dir}" || return 1
    
    # 如果日志文件不存在，先启动一次生成日志
    if [[ ! -f "${log_file}" ]]; then
        echo -e "${Info} 日志文件不存在，启动真寻BOT生成日志文件..."
        check_pid_zhenxun
        [[ -n "${PID}" ]] && kill -9 "${PID}" 2>/dev/null
        
        nohup poetry run ${python_v} bot.py > zhenxun_bot.log 2>&1 & 
        local temp_pid=$!
        
        # 等待日志生成，最多30秒
        for i in {1..30}; do
            if [[ -f "${log_file}" ]] && [[ -s "${log_file}" ]]; then
                break
            fi
            sleep 1
        done
        
        # 停止测试进程
        kill -9 "${temp_pid}" 2>/dev/null
        wait "${temp_pid}" 2>/dev/null
    fi
    
    # 循环检测和安装缺失依赖
    while [[ ${attempt} -le ${max_attempts} ]]; do
        echo -e "${Info} 第${attempt}次检测缺失依赖..."
        
        # 清理之前的请求文件
        > "${requests_file}"
        
        # 启动真寻BOT进行依赖检测
        check_pid_zhenxun
        [[ -n "${PID}" ]] && kill -9 "${PID}" 2>/dev/null
        
        # 清空日志文件，只保留新错误
        > "${log_file}"
        
        nohup poetry run ${python_v} bot.py > zhenxun_bot.log 2>&1 & 
        local bot_pid=$!
        
        # 等待依赖错误出现，最多20秒
        local detected_modules=""
        for i in {1..20}; do
            if [[ -f "${log_file}" ]]; then
                detected_modules=$(grep "No module named" "${log_file}" 2>/dev/null | awk -F "'" '{print $2}' | tr '\n' ' ')
                if [[ -n "${detected_modules}" ]]; then
                    break
                fi
            fi
            sleep 1
        done
        
        # 停止检测进程
        kill -9 "${bot_pid}" 2>/dev/null
        wait "${bot_pid}" 2>/dev/null
        
        # 如果没有检测到缺失模块，检查是否成功启动
        if [[ -z "${detected_modules}" ]]; then
            # 检查日志中是否有成功启动的标志
            if grep -q "真寻BOT启动成功\|Bot startup completed\|Running on" "${log_file}" 2>/dev/null; then
                echo -e "${Info} 真寻BOT依赖检测完成，所有依赖都已满足！"
                return 0
            fi
        fi
        
        # 处理检测到的缺失模块
        if [[ -n "${detected_modules}" ]]; then
            echo "${detected_modules}" | tr ' ' '\n' | sort -u | grep -v "^enchant$" > "${requests_file}"
            
            if [[ -s "${requests_file}" ]]; then
                echo -e "${Info} 检测到以下缺失依赖:"
                cat "${requests_file}"
                Install_module
            else
                echo -e "${Info} 没有新的依赖需要安装"
            fi
        else
            echo -e "${Info} 第${attempt}次检测未发现缺失依赖"
        fi
        
        ((attempt++))
        
        # 如果还有缺失依赖，继续下一轮
        if [[ ! -s "${requests_file}" ]] || [[ ${attempt} -gt ${max_attempts} ]]; then
            break
        fi
        
        sleep 2
    done
    
    echo -e "${Info} 依赖检测完成！"
    return 0
}

Install_module() {
    local requests_file="${WORK_DIR}/zhenxun_bot/requests.txt"
    local project_dir="${WORK_DIR}/zhenxun_bot"
    
    # 确保请求文件存在
    if [[ ! -f "${requests_file}" ]]; then
        echo -e "${Info} 没有依赖需要安装"
        return 0
    fi
    
    # 读取并处理模块列表
    local modules=$(sort -u "${requests_file}" | uniq | sed '/^enchant/d' | tr '\n' ' ')
    
    # 如果没有模块需要安装
    if [[ -z "${modules}" ]] || [[ "${modules}" == " " ]]; then
        echo -e "${Info} 没有依赖需要安装"
        return 0
    fi
    
    echo -e "${Info} 本次检测到以下依赖需要安装:"
    echo "${modules}"
    
    # 确保在项目目录中
    cd "${project_dir}" || {
        echo -e "${Error} 无法进入项目目录: ${project_dir}"
        return 1
    }
    
    # 逐个安装模块，提高成功率
    local failed_modules=""
    for module in ${modules}; do
        if [[ -n "${module}" ]]; then
            echo -e "${Info} 正在安装: ${module}"
            if poetry run pip install "${module}" -i "${pip_url}"; then
                echo -e "${Info} 成功安装: ${module}"
            else
                echo -e "${Error} 安装失败: ${module}"
                failed_modules="${failed_modules} ${module}"
            fi
            sleep 1
        fi
    done
    
    # 报告安装结果
    if [[ -n "${failed_modules}" ]]; then
        echo -e "${Error} 以下模块安装失败:${failed_modules}"
        echo -e "${Info} 建议手动进入虚拟环境执行: poetry install"
        return 1
    else
        echo -e "${Info} 本次依赖安装完成"
        return 0
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
    local installed_version="${1:-}"
    echo -e "${Info} 正在更新QQ配置..."
    
    # 获取目标版本
    get_qq_target_version
    local target_ver="${linuxqq_target_version}"
    local target_build="${linuxqq_target_version##*-}"
    
    confs=$(sudo find /home -name "config.json" -path "*/.config/QQ/versions/*" 2>/dev/null)
    if [ -f /root/.config/QQ/versions/config.json ]; then
      confs="/root/.config/QQ/versions/config.json $confs"
    fi
    
    if [ -z "$confs" ]; then
      echo -e "${Info} 未找到QQ配置文件，跳过配置更新。"
      return 0
    fi
    
    for conf in $confs; do
      if [ -f "$conf" ]; then
        echo -e "${Info}  正在修改 $conf..."
        sudo jq --arg targetVer "$target_ver" --arg buildId "$target_build" \
        '.baseVersion = $targetVer | .curVersion = $targetVer | .buildId = $buildId' "$conf" > "$conf.tmp" && \
        sudo mv "$conf.tmp" "$conf" || { echo -e "${Error} QQ配置更新失败！"; exit 1; }
      fi
    done
    
    echo -e "${Info} QQ配置更新完成。"
}

update_napcat() {
    get_napcat_version
    echo -e "${Info} 最新NapCatQQ版本：${napcat_version}"
    
    # 配置备份路径
    local napcat_config_path="${napcat_DIR}/napcat/config"
    local backup_path="/tmp/napcat_config_backup_$(date +%s)"
    local backup_created=false
    
    if [ -d "${napcat_DIR}/napcat" ]; then
      current_version=$(jq -r '.version' "${napcat_DIR}/napcat/package.json")
      echo -e "${Info} NapCatQQ已安装，版本：v${current_version}"
      target_version=${napcat_version#v}
      IFS='.' read -r i1 i2 i3 <<< "$current_version"
      IFS='.' read -r t1 t2 t3 <<< "$target_version"
      
      # 如果QQ已安装且存在Napcat配置，则备份
      if [ -d "${napcat_config_path}" ]; then
        echo -e "${Info} 检测到现有 Napcat 配置 (${napcat_config_path}), 准备备份..."
        if mkdir -p "${backup_path}"; then
          echo -e "${Info} 创建备份目录: ${backup_path}"
          if cp -a "${napcat_config_path}/." "${backup_path}/"; then
            echo -e "${Info} Napcat 配置备份成功到 ${backup_path}"
            backup_created=true
          else
            echo -e "${Error} 警告: Napcat 配置备份失败。"
          fi
        else
          echo -e "${Error} 严重警告: 无法创建备份目录 ${backup_path}。"
        fi
      fi
      
      if (( i1 < t1 || (i1 == t1 && i2 < t2) || (i1 == t1 && i2 == t2 && i3 < t3) )); then
        Install_napcat
      else
        echo -e "${Info} 已安装最新版本，无需更新。"
      fi
    else
      Install_napcat
    fi
    
    # 如果创建了备份，则恢复配置
    if [ "${backup_created}" = true ]; then
      echo -e "${Info} 准备恢复 Napcat 配置从 ${backup_path}..."
      if ! mkdir -p "${napcat_config_path}"; then
        echo -e "${Error} 严重警告: 无法创建目标配置目录 (${napcat_config_path}) 进行恢复。"
      else
        if cp -a "${backup_path}/." "${napcat_config_path}/"; then
          echo -e "${Info} Napcat 配置恢复成功到 ${napcat_config_path}"
        else
          echo -e "${Error} 警告: Napcat 配置恢复失败。"
        fi
      fi
      echo -e "${Info} 清理备份目录 ${backup_path}..."
      rm -rf "${backup_path}"
    fi
}

Install_linuxqq() {
    check_arch
    check_sys
    
    # 获取目标QQ版本
    get_qq_target_version
    
    echo -e "${Info} 目标LinuxQQ版本: ${linuxqq_target_version}"
    
    # 检查是否已安装QQ
    local qq_installed=false
    if [ -f "/opt/QQ/resources/app/package.json" ]; then
      qq_installed=true
      linuxqq_installed_version=$(jq -r '.version' "/opt/QQ/resources/app/package.json")
      echo -e "${Info} 检测到已安装的QQ, 版本: ${linuxqq_installed_version}"
      compare_linuxqq_versions "${linuxqq_installed_version}" "${linuxqq_target_version}"
    else
      echo -e "${Info} 未在 /opt/QQ 检测到已安装的QQ。"
      force="y" # 未安装，强制执行安装
    fi
    
    if [ "${force}" = "y" ]; then
      echo -e "${Info} 将执行全新安装或强制重装..."
      
      echo -e "${Info} 开始安装LinuxQQ..."
      for (( i=1; i<=5; i++ )); do
        qq_download_url="https://dldir1.qq.com/qqfile/qq/QQNT/c773cdf7/linuxqq_${linuxqq_target_version}_${arch}.${format}"
        sudo wget -O QQ.${format} "${qq_download_url}"
        if [ $? = 0 ] ; then
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
    else
      echo -e "${Info} 版本已满足要求, 无需更新。"
      update_linuxqq_config "${linuxqq_installed_version}"
    fi
}

get_qq_target_version() {
    #固定 3.2.19-39038
    linuxqq_target_version="3.2.19-39038"
}

compare_linuxqq_versions() {
    local ver1="${1}" #当前版本
    local ver2="${2}" #目标版本

    IFS='.-' read -r -a ver1_parts <<<"${ver1}"
    IFS='.-' read -r -a ver2_parts <<<"${ver2}"

    local length=${#ver1_parts[@]}
    if [ ${#ver2_parts[@]} -lt $length ]; then
        length=${#ver2_parts[@]}
    fi

    for ((i = 0; i < length; i++)); do
        if ((ver1_parts[i] > ver2_parts[i])); then
            force="n"
            return
        elif ((ver1_parts[i] < ver2_parts[i])); then
            force="y"
            return
        fi
    done

    if [ ${#ver1_parts[@]} -gt ${#ver2_parts[@]} ]; then
        force="n"
    elif [ ${#ver1_parts[@]} -lt ${#ver2_parts[@]} ]; then
        force="y"
    else
        force="n"
    fi
}

get_napcat_version() {
    default_file="NapCat.Shell.zip"
    json_data=$(curl -s "$api_url") || json_data=$(curl "$api_url2")
    napcat_version=$(jq -r '.tag_name' <<< "$json_data")
    napcat_download_url=$(jq -r '.assets[] | select(.name == "NapCat.Shell.zip") | .browser_download_url'  <<< "$json_data")
}

install_napcat_cli() {
    local cli_script_url_base="https://raw.githubusercontent.com/NapNeko/NapCat-TUI-CLI/main/script"
    local cli_script_name="install-cli.sh"
    local cli_script_local_path="./${cli_script_name}.download"
    local cli_script_url="${ghproxy}${cli_script_url_base}/${cli_script_name}"
    
    echo -e "${Info} 下载外部 TUI-CLI 安装脚本从 ${cli_script_url}..."
    sudo curl -k -L -# "${cli_script_url}" -o "${cli_script_local_path}"
    
    if [ $? -ne 0 ]; then
        echo -e "${Error} TUI-CLI 安装脚本 ${cli_script_name} 下载失败。"
        sudo rm -f "${cli_script_local_path}"
        return 1
    fi
    
    echo -e "${Info} 设置 TUI-CLI 安装脚本权限..."
    sudo chmod +x "${cli_script_local_path}"
    if [ $? -ne 0 ]; then
        echo -e "${Error} 设置 TUI-CLI 安装脚本执行权限失败。"
        sudo rm -f "${cli_script_local_path}"
        return 1
    fi
    
    echo -e "${Info} 执行外部 TUI-CLI 安装脚本..."
    sudo "${cli_script_local_path}"
    
    local exit_status=$?
    if [ ${exit_status} -ne 0 ]; then
        echo -e "${Error} 外部 TUI-CLI 安装脚本执行失败 (退出码: ${exit_status})。"
    else
        echo -e "${Info} 外部 TUI-CLI 安装脚本执行成功。"
    fi
    
    echo -e "${Info} 清理 TUI-CLI 安装脚本..."
    sudo rm -f "${cli_script_local_path}"
    
    return ${exit_status}
}

install_napcat_docker() {
    local qq="${1:-}"
    local mode="${2:-reverse_ws}"
    
    if [[ -z "${qq}" ]]; then
        echo -e "${Error} QQ号不能为空。"
        return 1
    fi
    
    if [[ "${mode}" != "ws" && "${mode}" != "reverse_ws" && "${mode}" != "reverse_http" ]]; then
        echo -e "${Error} 无效的运行模式 '${mode}', 请选择 ws, reverse_ws 或 reverse_http"
        return 1
    fi
    
    echo -e "${Info} 检查Docker环境..."
    if ! command -v docker &>/dev/null; then
        echo -e "${Error} Docker未安装，请先安装Docker。"
        return 1
    fi
    
    echo -e "${Info} 生成Docker命令..."
    local docker_cmd="sudo docker run -d -e ACCOUNT=${qq}"
    local docker_image="--name napcat --restart=always ${ghproxy}mlikiowa/napcat-docker:latest"
    
    case "${mode}" in
        "ws")
            docker_cmd="${docker_cmd} -e WS_ENABLE=true -e NAPCAT_GID=\$(id -g) -e NAPCAT_UID=\$(id -u) -p 3001:3001 -p 6099:6099 ${docker_image}"
            ;;
        "reverse_ws")
            docker_cmd="${docker_cmd} -e WSR_ENABLE=true -e NAPCAT_GID=\$(id -g) -e NAPCAT_UID=\$(id -u) -p 6099:6099 ${docker_image}"
            ;;
        "reverse_http")
            docker_cmd="${docker_cmd} -e HTTP_ENABLE=true -e NAPCAT_GID=\$(id -g) -e NAPCAT_UID=\$(id -u) -p 3000:3000 -p 6099:6099 ${docker_image}"
            ;;
    esac
    
    echo -e "${Info} 执行Docker安装命令..."
    echo -e "${Info} 命令: ${docker_cmd}"
    eval "${docker_cmd}"
    
    if [ $? -eq 0 ]; then
        echo -e "${Info} NapCatQQ Docker容器安装成功！"
        echo -e "${Info} 容器名称: napcat"
        echo -e "${Info} 运行模式: ${mode}"
        echo -e "${Info} QQ号: ${qq}"
        echo -e "${Info} 使用 'docker logs napcat' 查看日志"
    else
        echo -e "${Error} NapCatQQ Docker容器安装失败！"
        return 1
    fi
}

Download_napcat() {
    echo -e "${Info} 尝试获取最新NapCatQQ版本..."
    get_napcat_version
    cd "${TMP_DIR}" || exit 1
    
    # 检查是否已下载文件
    if [ -f "${default_file}" ]; then
      echo -e "${Info} 检测到已下载NapCat安装包,跳过下载..."
    else
      for (( i=1; i<=5; i++ )); do
        if [ ! -z "$napcat_version" ]; then
          echo -e "${Info} 最新NapCatQQ版本：${napcat_version}, 开始下载..."
          for (( j=1; j<=5; j++ )); do
            sudo wget -O "${default_file}" "${ghproxy}${napcat_download_url}"
            if [ $? = 0 ] ; then
              break
            elif [ $j -lt 5 ]; then
              echo -e "${Info} 第${j}次尝试下载NapCatQQ失败，正在重试..."
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
    fi

    echo -e "${Info} 正在验证 ${default_file}..."
    unzip -t "${default_file}" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo -e "${Error} 文件验证失败, 请检查错误。"
      clean
      exit 1
    fi

    echo -e "${Info} 正在解压 ${default_file}..."
    unzip -q -o -d NapCat NapCat.Shell.zip
    if [ $? -ne 0 ]; then
      echo -e "${Error} 文件解压失败，请检查错误。"
      clean
      exit 1
    fi
    
    # 创建目录结构
    if [ ! -d "${napcat_DIR}/napcat" ]; then
      echo -e "${Info} 创建NapCat目录结构..."
      sudo mkdir -p "${napcat_DIR}/napcat/"
      sudo mkdir -p "${napcat_DIR}/napcat/logs"
      sudo mkdir -p "${napcat_DIR}/napcat/config"
    fi

    echo -e "${Info} 正在移动文件..."
    sudo cp -r -f NapCat/* "${napcat_DIR}/napcat/"
    if [ $? -ne 0 ] && [ $? -ne 1 ]; then
      echo -e "${Error} 文件移动失败，请以root身份运行。"
      clean
      exit 1
    fi

    echo -e "${Info} 正在设置文件权限..."
    sudo chmod -R 755 "${napcat_DIR}/napcat/"
    
    echo -e "${Info} 正在修补文件..."
    
    # 使用新的修补方法，创建loadNapCat.js文件
    local load_napcat_content="(async () => {await import('file://${napcat_DIR}/napcat/napcat.mjs');})();"
    
    # 检查napcat_DIR是否存在
    if [ ! -d "${napcat_DIR}" ]; then
      echo -e "${Info} 创建NapCat目录: ${napcat_DIR}"
      sudo mkdir -p "${napcat_DIR}"
    fi
    
    sudo bash -c "echo \"${load_napcat_content}\" > \"${napcat_DIR}/loadNapCat.js\""
    
    if [ $? -ne 0 ]; then
      echo -e "${Error} loadNapCat.js文件写入失败，请以root身份运行。"
      clean
      exit 1
    fi
    
    # 修改QQ启动配置
    echo -e "${Info} 正在修改QQ启动配置..."
    local qq_package_json="${napcat_DIR}/package.json"
    local qq_main_package_json="/opt/QQ/resources/app/package.json"
    
    # 检查NapCat目录下的package.json
    if [ -f "${qq_package_json}" ]; then
      sudo jq '.main = "./loadNapCat.js"' "${qq_package_json}" > "${qq_package_json}.tmp" && \
      sudo mv "${qq_package_json}.tmp" "${qq_package_json}" || {
        echo -e "${Error} QQ启动配置修改失败..."
        clean
        exit 1
      }
      echo -e "${Info} 修改QQ启动配置成功..."
    # 检查QQ主目录下的package.json
    elif [ -f "${qq_main_package_json}" ]; then
      sudo jq '.main = "./app_launcher/loadNapCat.js"' "${qq_main_package_json}" > "${qq_main_package_json}.tmp" && \
      sudo mv "${qq_main_package_json}.tmp" "${qq_main_package_json}" || {
        echo -e "${Error} QQ主配置文件修改失败..."
        clean
        exit 1
      }
      echo -e "${Info} 修改QQ主配置文件成功..."
    else
      echo -e "${Error} 未找到QQ package.json文件，配置修改失败..."
      echo -e "${Info} 已安装的QQ文件结构:"
      find /opt/QQ -name "package.json" -type f 2>/dev/null | head -10
      clean
      exit 1
    fi
    
    echo -e "${Info} NapCatQQ安装成功！"
    clean
}

Install_napcat() {
    echo -e "${Info} 开始安装 NapCatQQ..."
    
    # 安装LinuxQQ
    Install_linuxqq
    
    # 下载并安装NapCat
    Download_napcat
    
    # 检查安装结果
    if [ -d "${napcat_DIR}/napcat" ]; then
        echo -e "${Info} NapCatQQ 安装完成！"
        
        # 显示版本信息
        if [ -f "${napcat_DIR}/napcat/package.json" ]; then
            local installed_version=$(jq -r '.version' "${napcat_DIR}/napcat/package.json")
            echo -e "${Info} 已安装版本: v${installed_version}"
        fi
        
        # 显示配置信息
        echo -e "${Info} 配置文件路径: ${napcat_DIR}/napcat/config/"
        echo -e "${Info} 日志文件路径: ${napcat_DIR}/napcat/logs/"
        
        # 询问是否安装TUI-CLI
        echo -e "${Info} 是否安装 TUI-CLI 管理工具？(y/n，默认: n)"
        read -erp "请选择:" install_cli
        [[ -z "${install_cli}" ]] && install_cli="n"
        
        if [[ "${install_cli}" == "y" ]]; then
            install_napcat_cli
        else
            echo -e "${Info} 跳过安装 TUI-CLI 管理工具。"
        fi
        
    else
        echo -e "${Error} NapCatQQ 安装失败！"
        exit 1
    fi
}

clean() {
    rm -rf ${TMP_DIR}
    if [ $? -ne 0 ]; then
      echo -e "${Error} 临时文件删除失败，请手动删除 ${TMP_DIR}。"
    fi
}


Set_config_admin() {
    local env_file="${WORK_DIR}/zhenxun_bot/.env.dev"
    local max_retries=3
    local retry_count=0
    
    # 检查配置文件是否存在
    if [[ ! -f "$env_file" ]]; then
        echo -e "${Warning} 配置文件不存在: $env_file"
        echo -e "${Info} 尝试创建配置文件..."
        
        # 检查 zhenxun_bot 目录是否存在
        if [[ ! -d "${WORK_DIR}/zhenxun_bot" ]]; then
            echo -e "${Error} zhenxun_bot 目录不存在，请先安装 zhenxun_bot"
            return 1
        fi
        
        # 创建基础配置文件
        cat > "$env_file" << 'EOF'
# 真寻机器人配置
HOST=0.0.0.0
PORT=8080
SUPERUSERS=[]
NICKNAME=["真寻"]
COMMAND_START=[""]
DB_URL=sqlite:data/db/zhenxun.db

# NapCat 配置
NAPCAT_HOST=127.0.0.1
NAPCAT_PORT=3000

# 其他配置
LOG_LEVEL=INFO
EOF
        
        if [[ $? -ne 0 ]]; then
            echo -e "${Error} 无法创建配置文件"
            return 1
        fi
        
        echo -e "${Info} 配置文件已创建: $env_file"
    fi
    
    # 备份原始配置文件
    cp "$env_file" "${env_file}.bak" 2>/dev/null || {
        echo -e "${Error} 无法备份配置文件，请检查权限"
        return 1
    }
    
    while [[ $retry_count -lt $max_retries ]]; do
        echo -e "${Info} 请输入管理员QQ账号 (纯数字，5-12位):"
        read -erp "管理员QQ:" admin_qq
        
        # 输入验证
        if [[ -z "$admin_qq" ]]; then
            echo -e "${Error} 管理员QQ不能为空！"
        elif [[ ! "$admin_qq" =~ ^[0-9]{5,12}$ ]]; then
            echo -e "${Error} 管理员QQ必须是5-12位的纯数字！"
        else
            # 尝试更新配置
            cd "${WORK_DIR}/zhenxun_bot" || return 1
            
            # 使用更精确的sed替换，避免误替换
            local sed_success=true
            
            # 替换SUPERUSERS配置
            if ! sed -i "s/^SUPERUSERS=.*/SUPERUSERS=[\"$admin_qq\"]/" "$env_file" 2>/dev/null; then
                sed_success=false
            fi
            
            # 替换qq配置
            if ! sed -i -e 's/"qq".*/"qq": [\"'"$admin_qq"'\"],/' "$env_file" 2>/dev/null; then
                sed_success=false
            fi
            
            if [[ "$sed_success" == true ]]; then
                echo -e "${Info} 设置成功! 管理员QQ: [""${Green_font_prefix}"${admin_qq}"${Font_color_suffix}""]"
                
                # 验证设置是否生效
                if grep -q "SUPERUSERS=\[\"$admin_qq\"\]" "$env_file" && grep -q "\"qq\": \[\"$admin_qq\"\]," "$env_file"; then
                    echo -e "${Info} 配置已验证生效"
                    return 0
                else
                    echo -e "${Error} 配置验证失败，正在重试..."
                    ((retry_count++))
                fi
            else
                echo -e "${Error} 配置文件写入失败，请检查权限"
                ((retry_count++))
            fi
        fi
        
        [[ $retry_count -lt $max_retries ]] && echo -e "${Info} 还有 $((max_retries - retry_count)) 次尝试机会"
    done
    
    # 恢复备份
    mv "${env_file}.bak" "$env_file" 2>/dev/null
    echo -e "${Error} 设置管理员QQ失败，已恢复原始配置"
    return 1
    
}

# 辅助函数：安全更新JSON配置文件
update_json_config() {
    local json_file="$1"
    local jq_expression="$2"
    local temp_file="${json_file}.tmp"
    local backup_file="${json_file}.bak"
    
    # 检查文件是否存在
    if [[ ! -f "$json_file" ]]; then
        echo -e "${Error} JSON文件不存在: $json_file"
        return 1
    fi
    
    # 备份原始文件
    cp "$json_file" "$backup_file" 2>/dev/null || {
        echo -e "${Error} 无法备份JSON文件: $json_file"
        return 1
    }
    
    # 应用jq表达式
    if jq "$jq_expression" "$json_file" > "$temp_file" 2>/dev/null; then
        # 验证生成的临时文件是否有效
        if jq empty "$temp_file" >/dev/null 2>&1; then
            # 原子替换
            if mv "$temp_file" "$json_file" 2>/dev/null; then
                return 0
            else
                echo -e "${Error} 无法更新JSON文件: $json_file"
                mv "$backup_file" "$json_file" 2>/dev/null  # 恢复备份
                return 1
            fi
        else
            echo -e "${Error} 生成的JSON文件格式无效"
            rm -f "$temp_file" 2>/dev/null
            mv "$backup_file" "$json_file" 2>/dev/null  # 恢复备份
            return 1
        fi
    else
        echo -e "${Error} jq表达式执行失败: $jq_expression"
        rm -f "$temp_file" 2>/dev/null
        mv "$backup_file" "$json_file" 2>/dev/null  # 恢复备份
        return 1
    fi
}

Set_config_bot() {
    local config_dir="${napcat_DIR}/napcat/config"
    local max_retries=3
    local retry_count=0
    
    # 检查napcat配置目录是否存在
    if [[ ! -d "$config_dir" ]]; then
        echo -e "${Error} NapCat配置目录不存在: $config_dir"
        echo -e "${Info} 请确保NapCat已正确安装"
        return 1
    fi
    
    while [[ $retry_count -lt $max_retries ]]; do
        echo -e "${Info} 请输入Bot QQ账号 (纯数字，5-12位，不能与管理员QQ相同):"
        read -erp "Bot QQ:" bot_qq
        
        # 输入验证
        if [[ -z "$bot_qq" ]]; then
            echo -e "${Error} Bot QQ不能为空！"
        elif [[ ! "$bot_qq" =~ ^[0-9]{5,12}$ ]]; then
            echo -e "${Error} Bot QQ必须是5-12位的纯数字！"
        elif [[ "$bot_qq" = "$admin_qq" ]]; then
            echo -e "${Error} Bot QQ [""${Green_font_prefix}"$bot_qq"${Font_color_suffix}""] 不能与管理员QQ账号 [""${Green_font_prefix}"$admin_qq"${Font_color_suffix}""] 一致！"
        else
            break
        fi
        
        ((retry_count++))
        [[ $retry_count -lt $max_retries ]] && echo -e "${Info} 还有 $((max_retries - retry_count)) 次尝试机会"
    done
    
    # 如果达到最大重试次数仍未成功
    if [[ $retry_count -ge $max_retries ]]; then
        echo -e "${Error} 设置Bot QQ失败，已达到最大重试次数"
        return 1
    fi
    
    # 配置文件操作
    cd "$config_dir" || return 1
    
    # 备份原始配置文件
    [[ -f "napcat.json" ]] && cp "napcat.json" "napcat.json.bak" 2>/dev/null
    [[ -f "onebot11_$bot_qq.json" ]] && cp "onebot11_$bot_qq.json" "onebot11_$bot_qq.json.bak" 2>/dev/null
    
    # 如果配置文件不存在，创建它们
    if [[ ! -f "onebot11_$bot_qq.json" ]]; then
        echo -e "${Info} 创建NapCat配置文件..."
        
        # 创建基础配置文件
        cat > "onebot11_$bot_qq.json" << EOF
{
  "http": {
    "enable": false,
    "host": "",
    "port": 3000,
    "secret": "",
    "enableHeart": false,
    "enablePostUrl": false
  },
  "ws": {
    "enable": false,
    "host": "",
    "port": 3000
  },
  "reverseWs": {
    "enable": true,
    "urls": ["ws://127.0.0.1:8080/onebot/v11/ws"]
  },
  "GroupLocalTime": {
    "Record": false,
    "RecordList": []
  },
  "musicSignUrl": "",
  "msg": {
    "ffmpeg": "/usr/bin/ffmpeg",
    "ffprobe": "/usr/bin/ffprobe"
  },
  "httpPort": [
    443,
    80,
    8080,
    3000
  ],
  "httpHosts": [],
  "enableLocalFile2Url": true,
  "heartTime": 30000,
  "token": ""
}
EOF
        
        if [[ $? -ne 0 ]]; then
            echo -e "${Error} 无法创建配置文件，请检查napcat是否安装正确！"
            return 1
        fi
        
        echo -e "${Info} 配置文件已创建: onebot11_$bot_qq.json"
    fi
    
    # 使用原子操作更新配置
    local config_success=true
    
    # 更新napcat.json
    if ! update_json_config "napcat.json" "--arg key \"pathName\" --arg value \"$bot_qq\" '. += {(\$key): \$value}'"; then
        config_success=false
    fi
    
    # 更新onebot11_$bot_qq.json
    if [[ "$config_success" == true ]]; then
        if ! update_json_config "onebot11_$bot_qq.json" ".musicSignUrl = \"$musicSignUrl\""; then
            config_success=false
        fi
        
        if [[ "$config_success" == true ]]; then
            if ! update_json_config "onebot11_$bot_qq.json" '.reverseWs.enable = true'; then
                config_success=false
            fi
        fi
    fi
    
    if [[ "$config_success" == true ]]; then
        echo -e "${Info} 设置成功! Bot QQ: [""${Green_font_prefix}"${bot_qq}"${Font_color_suffix}""]"
        
        # 验证配置
        if [[ -f "napcat.json" ]] && [[ -f "onebot11_$bot_qq.json" ]]; then
            echo -e "${Info} 配置文件已创建/更新"
            return 0
        else
            echo -e "${Error} 配置文件验证失败"
            return 1
        fi
    else
        echo -e "${Error} 设置Bot QQ失败，配置更新过程中出现错误"
        return 1
    fi
    
}

Set_config() { 
    Set_config_admin
    Set_config_bot
    Set_Port
    Set_sql_bind
    
}

Set_Port() {
    local min_port=1024
    local max_port=65535
    local max_attempts=3
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        echo -e "${Info} 请设置 zhenxun_bot napcat 通信端口 (范围: ${Green_font_prefix}${min_port}-${max_port}${Font_color_suffix})"
        echo -e "${Info} 推荐使用端口: 8080, 3000, 9145, 9999 等"
        read -erp "Port:" Port
        
        # 输入验证
        if [[ -z "${Port}" ]]; then
            echo -e "${Error} 端口不能为空"
            ((attempt++))
            echo -e "${Info} 剩余尝试次数: $((max_attempts - attempt))"
            continue
        fi
        
        # 数字验证
        if ! [[ "${Port}" =~ ^[0-9]+$ ]]; then
            echo -e "${Error} 端口必须是数字"
            ((attempt++))
            echo -e "${Info} 剩余尝试次数: $((max_attempts - attempt))"
            continue
        fi
        
        # 端口范围验证
        if [ "${Port}" -lt ${min_port} ] || [ "${Port}" -gt ${max_port} ]; then
            echo -e "${Error} 端口设置错误，取值范围 [${Green_font_prefix}${min_port}-${max_port}${Font_color_suffix}]"
            echo -e "${Info} 请输入 ${min_port}-${max_port} 范围内的数字（如：8080, 3000, 9145）"
            ((attempt++))
            echo -e "${Info} 剩余尝试次数: $((max_attempts - attempt))"
            continue
        fi
        
        # 检查端口是否被占用（简化检查，避免权限问题）
    if command -v netstat >/dev/null 2>&1; then
        if netstat -tuln 2>/dev/null | grep -q ":${Port} "; then
            echo -e "${Error} 端口 ${Port} 已被占用"
            ((attempt++))
            echo -e "${Info} 剩余尝试次数: $((max_attempts - attempt))"
            continue
        fi
    elif command -v ss >/dev/null 2>&1; then
        if ss -tuln 2>/dev/null | grep -q ":${Port} "; then
            echo -e "${Error} 端口 ${Port} 已被占用"
            ((attempt++))
            echo -e "${Info} 剩余尝试次数: $((max_attempts - attempt))"
            continue
        fi
    fi
        
        # 获取本地IP地址（修复权限问题）
        local local_ipv4="127.0.0.1"
        local local_ipv6=""
        
        # 尝试获取IP地址，如果失败则使用默认值
        if command -v hostname >/dev/null 2>&1; then
            local ip_output=$(hostname -I 2>/dev/null | awk '{print $1}' | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || echo "")
            if [[ -n "$ip_output" ]]; then
                local_ipv4="$ip_output"
            fi
        fi
        
        if command -v ip >/dev/null 2>&1; then
            local_ipv6=$(ip -6 addr show scope global 2>/dev/null | grep -oE 'inet6 [0-9a-fA-F:]+' | awk '{print $2}' | head -n1 | cut -d'/' -f1 || echo "")
        fi
        
        # 更新 napcat 配置
        local napcat_config="${napcat_DIR}/napcat/config/onebot11_${bot_qq}.json"
        if [[ -f "${napcat_config}" ]]; then
            # 备份原始配置
            cp "${napcat_config}" "${napcat_config}.bak" 2>/dev/null || true
            
            # 使用 update_json_config 函数更新配置
            if ! update_json_config "${napcat_config}" ".urls[0]" "\"ws://${local_ipv4}:${Port}/onebot/v11/ws\""; then
                echo -e "${Error} napcat 配置文件更新失败"
                # 恢复备份
                if [[ -f "${napcat_config}.bak" ]]; then
                    mv "${napcat_config}.bak" "${napcat_config}" 2>/dev/null || true
                fi
                ((attempt++))
                echo -e "${Info} 剩余尝试次数: $((max_attempts - attempt))"
                continue
            fi
            
            # 清理备份
            rm -f "${napcat_config}.bak"
        else
            echo -e "${Error} napcat 配置文件不存在: ${napcat_config}"
            ((attempt++))
            echo -e "${Info} 剩余尝试次数: $((max_attempts - attempt))"
            continue
        fi
        
        # 更新 zhenxun_bot 配置
        local zhenxun_env="${WORK_DIR}/zhenxun_bot/.env.dev"
        
        # 如果配置文件不存在，创建基础配置
        if [[ ! -f "${zhenxun_env}" ]]; then
            echo -e "${Warning} zhenxun_bot 配置文件不存在，创建基础配置..."
            cat > "${zhenxun_env}" << EOF
# 真寻机器人配置
HOST=0.0.0.0
PORT=${Port}
SUPERUSERS=[]
NICKNAME=["真寻"]
COMMAND_START=[""]
DB_URL=sqlite:data/db/zhenxun.db

# NapCat 配置
NAPCAT_HOST=127.0.0.1
NAPCAT_PORT=3000

# 其他配置
LOG_LEVEL=INFO
EOF
            if [[ $? -ne 0 ]]; then
                echo -e "${Error} 无法创建 zhenxun_bot 配置文件"
                ((attempt++))
                echo -e "${Info} 剩余尝试次数: $((max_attempts - attempt))"
                continue
            fi
        else
            # 备份原始配置
            cp "${zhenxun_env}" "${zhenxun_env}.bak" 2>/dev/null || true
            
            # 更新端口配置
            if ! sed -i -e "s/^PORT.*/PORT = ${Port}/" "${zhenxun_env}"; then
                echo -e "${Error} zhenxun_bot 配置文件更新失败"
                # 恢复备份
                if [[ -f "${zhenxun_env}.bak" ]]; then
                    mv "${zhenxun_env}.bak" "${zhenxun_env}" 2>/dev/null || true
                fi
                ((attempt++))
                echo -e "${Info} 剩余尝试次数: $((max_attempts - attempt))"
                continue
            fi
            
            # 清理备份
            rm -f "${zhenxun_env}.bak"
        fi
        
        # 配置验证
        if [[ -f "${napcat_config}" ]] && grep -q "${Port}" "${napcat_config}" && [[ -f "${zhenxun_env}" ]] && grep -q "PORT = ${Port}" "${zhenxun_env}"; then
            echo -e "${Info} 设置成功! 端口: [${Green_font_prefix}${Port}${Font_color_suffix}]"
            echo -e "${Info} 通信地址: ws://${local_ipv4}:${Port}/onebot/v11/ws"
            if [[ -n "${local_ipv6}" ]]; then
                echo -e "${Info} IPv6 地址: ws://[${local_ipv6}]:${Port}/onebot/v11/ws"
            fi
            return 0
        else
            echo -e "${Error} 配置验证失败"
            ((attempt++))
            echo -e "${Info} 剩余尝试次数: $((max_attempts - attempt))"
            continue
        fi
    done
    
    echo -e "${Error} 端口设置失败，已达到最大尝试次数"
    return 1
}

Set_sql_bind() {
    local max_attempts=3
    local attempt=0
    
    echo -e "${Info} 开始设置 SQL 连接语句..."
    
    # 检查并创建数据库目录
    local db_dir="${WORK_DIR}/zhenxun_bot/data/db"
    if [[ ! -d "${db_dir}" ]]; then
        if ! mkdir -p "${db_dir}"; then
            echo -e "${Error} 无法创建数据库目录: ${db_dir}"
            # 尝试使用sudo
            if ! sudo mkdir -p "${db_dir}"; then
                echo -e "${Error} 无法创建数据库目录，请检查权限"
                return 1
            fi
        fi
        echo -e "${Info} 已创建数据库目录: ${db_dir}"
    fi
    
    # 检查目录权限
    if [[ ! -w "${db_dir}" ]]; then
        echo -e "${Error} 数据库目录没有写入权限: ${db_dir}"
        return 1
    fi
    
    # 设置数据库文件路径
    local db_path="sqlite:data/db/zhenxun.db"
    local env_file="${WORK_DIR}/zhenxun_bot/.env.dev"
    
    # 检查环境文件是否存在
    if [[ ! -f "${env_file}" ]]; then
        echo -e "${Warning} 环境配置文件不存在: ${env_file}"
        echo -e "${Info} 尝试创建基础环境配置文件..."
        
        # 创建基础配置
        cat > "${env_file}" << EOF
# 真寻机器人配置
HOST=0.0.0.0
PORT=8080
SUPERUSERS=[]
NICKNAME=["真寻"]
COMMAND_START=[""]
DB_URL=sqlite:data/db/zhenxun.db

# NapCat 配置
NAPCAT_HOST=127.0.0.1
NAPCAT_PORT=3000

# 其他配置
LOG_LEVEL=INFO
EOF
        
        if [[ $? -ne 0 ]]; then
            echo -e "${Error} 无法创建环境配置文件"
            return 1
        fi
        
        echo -e "${Info} 环境配置文件已创建: ${env_file}"
    fi
    
    # 备份原始配置
    cp "${env_file}" "${env_file}.bak" 2>/dev/null || true
    
    while [ $attempt -lt $max_attempts ]; do
        # 更新数据库配置
        if sed -i -e "s|^DB_URL.*|DB_URL = \"${db_path}\"|g" "${env_file}" 2>/dev/null; then
            # 验证配置是否更新成功
            if grep -q "DB_URL = \"${db_path}\"" "${env_file}"; then
                echo -e "${Info} SQL 连接设置成功!"
                echo -e "${Info} 数据库路径: ${Green_font_prefix}${db_path}${Font_color_suffix}"
                
                # 测试数据库目录是否可写
                local test_file="${db_dir}/test_write_$$.tmp"
                if touch "${test_file}" 2>/dev/null; then
                    rm -f "${test_file}"
                    echo -e "${Info} 数据库目录可写性测试通过"
                else
                    echo -e "${Warning} 数据库目录可能无法写入，请检查权限"
                fi
                
                # 清理备份
                rm -f "${env_file}.bak"
                return 0
            fi
        else
            # 如果sed失败，尝试追加配置
            echo "DB_URL = \"${db_path}\"" >> "${env_file}" 2>/dev/null
            if grep -q "DB_URL = \"${db_path}\"" "${env_file}"; then
                echo -e "${Info} SQL 连接设置成功（追加模式）!"
                echo -e "${Info} 数据库路径: ${Green_font_prefix}${db_path}${Font_color_suffix}"
                rm -f "${env_file}.bak"
                return 0
            fi
        fi
        
        echo -e "${Error} 配置更新失败，正在重试..."
        ((attempt++))
        echo -e "${Info} 剩余尝试次数: $((max_attempts - attempt))"
        
        # 恢复备份重试
        if [[ -f "${env_file}.bak" ]]; then
            mv "${env_file}.bak" "${env_file}" 2>/dev/null || true
            cp "${env_file}" "${env_file}.bak" 2>/dev/null || true
        fi
    done
    
    echo -e "${Error} SQL 连接设置失败，已达到最大尝试次数"
    # 恢复备份
    if [[ -f "${env_file}.bak" ]]; then
        mv "${env_file}.bak" "${env_file}" 2>/dev/null || true
    fi
    return 1
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
    #Start_postgresql
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
    
    [[ -n ${PID} ]] && echo -e "${Error} napcat 正在运行，请检查 !" && exit 1
    
    cd $napcat_DIR/napcat/config/ || {
        echo -e "${Error} napcat 配置目录不存在: $napcat_DIR/napcat/config/"
        exit 1
    }
    
    # 获取配置信息
    pathName=$(jq -r '.pathName // empty' napcat.json 2>/dev/null)
    if [[ -z "${pathName}" ]]; then
        echo -e "${Error} 无法从 napcat.json 获取 pathName"
        exit 1
    fi
    
    # 检查日志目录
    local log_dir="${napcat_DIR}/napcat/logs"
    if [[ ! -d "${log_dir}" ]]; then
        mkdir -p "${log_dir}" || {
            echo -e "${Error} 无法创建日志目录: ${log_dir}"
            exit 1
        }
    fi
    
    # 获取本机IP地址（兼容Windows和Linux）
    local local_ipv4="127.0.0.1"
    local local_ipv6=""
    
    # 尝试获取IPv4地址
    if command -v hostname >/dev/null 2>&1; then
        local_ipv4=$(hostname -I 2>/dev/null | awk '{print $1}' | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || echo "127.0.0.1")
    elif command -v ip >/dev/null 2>&1; then
        local_ipv4=$(ip route get 1 2>/dev/null | awk '{print $7; exit}' | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || echo "127.0.0.1")
    fi
    
    # 尝试获取IPv6地址
    if command -v ip >/dev/null 2>&1; then
        local_ipv6=$(ip -6 addr show scope global 2>/dev/null | grep -oE 'inet6 [0-9a-fA-F:]+' | awk '{print $2}' | head -n1 | cut -d'/' -f1 || echo "")
    fi
    
    # 检查并配置 OneBot 配置
    local onebot_config="${napcat_DIR}/napcat/config/onebot11_${pathName}.json"
    if [[ -f "${onebot_config}" ]]; then
        echo -e "${Info} 检测到 OneBot 配置文件: ${onebot_config}"
        
        # 备份配置
        cp "${onebot_config}" "${onebot_config}.bak" 2>/dev/null || true
        
        # 更新 WebSocket URL 以支持 IPv6
        if [[ -n "${local_ipv6}" ]]; then
            # 支持 IPv4 和 IPv6
            if ! update_json_config "${onebot_config}" ".urls" "[\"ws://${local_ipv4}:${Port:-3000}/onebot/v11/ws\", \"ws://[${local_ipv6}]:${Port:-3000}/onebot/v11/ws\"]"; then
                echo -e "${Error} 更新 OneBot 配置失败"
            fi
        else
            # 仅 IPv4
            if ! update_json_config "${onebot_config}" ".urls[0]" "\"ws://${local_ipv4}:${Port:-3000}/onebot/v11/ws\""; then
                echo -e "${Error} 更新 OneBot 配置失败"
            fi
        fi
    fi
    
    # 启动 napcat
    cd "${log_dir}" || exit 1
    
    local log_file="${log_dir}/napcat_${pathName}.log"
    local pid_file="${napcat_DIR}/napcat/napcat.pid"
    
    # 清理旧的日志文件（如果太大）
    local log_size=0
    if [[ -f "${log_file}" ]]; then
        if command -v stat >/dev/null 2>&1; then
            log_size=$(stat -f%z "${log_file}" 2>/dev/null || stat -c%s "${log_file}" 2>/dev/null || echo 0)
        elif command -v wc >/dev/null 2>&1; then
            log_size=$(wc -c < "${log_file}" 2>/dev/null || echo 0)
        fi
        
        if [[ ${log_size} -gt 10485760 ]]; then
            mv "${log_file}" "${log_file}.old" 2>/dev/null || true
        fi
    fi
    
    echo -e "${Info} 正在启动 napcat (QQ: ${Green_font_prefix}${pathName}${Font_color_suffix})..."
    echo -e "${Info} 日志文件: ${log_file}"
    
    # 启动命令（兼容Windows和Linux）
    local start_cmd=""
    
    # 检测操作系统
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux系统
        start_cmd="xvfb-run -a qq --no-sandbox -q ${pathName}"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        # Windows系统（通过Git Bash或Cygwin）
        start_cmd="qq --no-sandbox -q ${pathName}"
    else
        # 其他系统，使用基础命令
        start_cmd="qq -q ${pathName}"
    fi
    
    # 启动并记录PID
    nohup ${start_cmd} >> "${log_file}" 2>&1 &
    local napcat_pid=$!
    
    # 保存PID
    echo "${napcat_pid}" > "${pid_file}" 2>/dev/null || true
    
    # 等待启动
    sleep 3
    
    # 检查进程是否还在运行
    if kill -0 "${napcat_pid}" 2>/dev/null; then
        echo -e "${Info} napcat 启动成功! PID: ${Green_font_prefix}${napcat_pid}${Font_color_suffix}"
        echo -e "${Info} OneBot WebSocket 地址:"
        echo -e "${Info} IPv4: ws://${local_ipv4}:${Port:-3000}/onebot/v11/ws"
        if [[ -n "${local_ipv6}" ]]; then
            echo -e "${Info} IPv6: ws://[${local_ipv6}]:${Port:-3000}/onebot/v11/ws"
        fi
        
        # 显示 WebUI 信息（如果可用）
        if [[ -f "${napcat_DIR}/napcat/config/webui.json" ]]; then
            local webui_port=$(jq -r '.port // empty' "${napcat_DIR}/napcat/config/webui.json" 2>/dev/null)
            local webui_token=$(jq -r '.token // empty' "${napcat_DIR}/napcat/config/webui.json" 2>/dev/null)
            if [[ -n "${webui_port}" && -n "${webui_token}" ]]; then
                echo -e "${Info} WebUI 地址: http://${local_ipv4}:${webui_port}/webui/login.html"
                echo -e "${Info} WebUI Token: ${webui_token}"
            fi
        fi
        
        return 0
    else
        echo -e "${Error} napcat 启动失败，请检查日志: ${log_file}"
        # 清理PID文件
        rm -f "${pid_file}"
        return 1
    fi
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
    pathName=$(jq '.pathName' napcat.json | sed 's/\"//g')
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
    pathName=$(jq '.pathName' napcat.json | sed 's/\"//g')
    vim ${napcat_DIR}/napcat/config/onebot_${pathName}.json
}

Set_config_zhenxun() {
    vim ${WORK_DIR}/zhenxun_bot/configs/config.yaml
}

Set_apt_source() {
    local max_attempts=3
    local attempt=0
    
    # 检查是否为root用户
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Error} 修改apt源需要root权限，请使用sudo运行"
        return 1
    fi
    
    # 检查系统是否支持apt
    if ! command -v apt &>/dev/null; then
        echo -e "${Error} 当前系统不支持apt包管理器"
        return 1
    fi
    
    echo -e "${Info} 请选择apt源修改方式"
    echo -e "${Green_font_prefix} 1.${Font_color_suffix} apt源列表 (推荐)"
    echo -e "${Green_font_prefix} 2.${Font_color_suffix} 手动输入"
    
    while [ $attempt -lt $max_attempts ]; do
        read -erp "请输入数字 [1-2], 默认为 1:" apt_source
        
        case "${apt_source}" in
            ""|"1")
                select_apt_source
                return 0
                ;;
            "2")
                Manual_input_source
                return 0
                ;;
            *)
                echo -e "${Error} 无效的选择，请输入 1 或 2"
                ((attempt++))
                echo -e "${Info} 剩余尝试次数: $((max_attempts - attempt))"
                ;;
        esac
    done
    
    echo -e "${Error} 已达到最大尝试次数，使用默认apt源列表"
    select_apt_source
}

select_apt_source() {
    local max_attempts=3
    local attempt=0
    
    echo -e "${Info} 请输入要选择的apt源, 默认为北外源"
    echo -e "${Green_font_prefix} 1.${Font_color_suffix} 北外 (默认)"
    echo -e "${Green_font_prefix} 2.${Font_color_suffix} 清华"
    echo -e "${Green_font_prefix} 3.${Font_color_suffix} 阿里"
    echo -e "${Green_font_prefix} 4.${Font_color_suffix} 华为"
    echo -e "${Green_font_prefix} 5.${Font_color_suffix} 中科大"
    echo -e "${Green_font_prefix} 6.${Font_color_suffix} 163 (广东电信：适合电信用户)"
    echo -e "${Green_font_prefix} 7.${Font_color_suffix} 取消修改"
    
    while [ $attempt -lt $max_attempts ]; do
        read -erp "请输入数字 [1-7], 默认为 1:" select_source
        
        case "${select_source}" in
            ""|"1")
                apt_source_bfsu
                return 0
                ;;
            "2")
                apt_source_tsinghua
                return 0
                ;;
            "3")
                apt_source_ali
                return 0
                ;;
            "4")
                apt_source_huawei
                return 0
                ;;
            "5")
                apt_source_ustc
                return 0
                ;;
            "6")
                apt_source_163
                return 0
                ;;
            "7")
                echo -e "${Info} 已取消apt源修改"
                return 0
                ;;
            *)
                echo -e "${Error} 无效的选择，请输入 1-7 之间的数字"
                ((attempt++))
                echo -e "${Info} 剩余尝试次数: $((max_attempts - attempt))"
                ;;
        esac
    done
    
    echo -e "${Error} 已达到最大尝试次数，使用默认北外源"
    apt_source_bfsu
}

update_apt_sources() {
    local mirror_url="$1"
    local mirror_name="$2"
    
    echo -e "${Info} 正在将apt源修改为 ${mirror_name}..."
    
    # 备份原始sources.list
    if [[ -f "/etc/apt/sources.list" ]]; then
        cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    fi
    
    # 使用更精确的正则表达式替换apt源
    local sed_patterns="s@http://[^/]*\.ubuntu\.com/@${mirror_url}@g;"
    sed_patterns+="s@http://[^/]*\.debian\.org/@${mirror_url}@g;"
    sed_patterns+="s@http://[^/]*security\.ubuntu\.com/@${mirror_url}@g;"
    sed_patterns+="s@http://[^/]*security\.debian\.org/@${mirror_url}@g;"
    sed_patterns+="s@https://[^/]*\.ubuntu\.com/@${mirror_url}@g;"
    sed_patterns+="s@https://[^/]*\.debian\.org/@${mirror_url}@g;"
    sed_patterns+="s@https://[^/]*security\.ubuntu\.com/@${mirror_url}@g;"
    sed_patterns+="s@https://[^/]*security\.debian\.org/@${mirror_url}@g;"
    
    if sed -i "${sed_patterns}" /etc/apt/sources.list 2>/dev/null; then
        echo -e "${Info} apt源地址替换完成，正在更新软件包列表..."
        if apt update 2>/dev/null; then
            echo -e "${Info} apt源已成功修改为 ${mirror_name}"
            return 0
        else
            echo -e "${Error} apt更新失败，请检查网络连接和源地址"
            return 1
        fi
    else
        echo -e "${Error} apt源修改失败"
        return 1
    fi
}

apt_source_bfsu() {
    update_apt_sources "https://mirrors.bfsu.edu.cn/" "北外源"
}

apt_source_tsinghua() {
    update_apt_sources "https://mirrors.tuna.tsinghua.edu.cn/" "清华源"
}

apt_source_ali() {
    update_apt_sources "http://mirrors.aliyun.com/" "阿里源"
}

apt_source_ustc() {
    update_apt_sources "https://mirrors.ustc.edu.cn/" "中科大源"
}

apt_source_163() {
    update_apt_sources "http://mirrors.163.com/" "163源"
}

apt_source_huawei() {
    update_apt_sources "https://repo.huaweicloud.com/" "华为源"
}

Manual_input_source() {
    local max_attempts=3
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        read -erp "请输入镜像站地址 (示例: https://mirrors.bfsu.edu.cn/):" input
        
        # 输入验证
        if [[ -z "${input}" ]]; then
            echo -e "${Error} 镜像站地址不能为空"
            ((attempt++))
            echo -e "${Info} 剩余尝试次数: $((max_attempts - attempt))"
            continue
        fi
        
        # URL格式验证
        if ! [[ "${input}" =~ ^https?://[^/]+/$ ]]; then
            echo -e "${Error} 请输入正确的镜像站地址格式 (如: https://mirrors.bfsu.edu.cn/)"
            ((attempt++))
            echo -e "${Info} 剩余尝试次数: $((max_attempts - attempt))"
            continue
        fi
        
        # 备份原始sources.list
        if [[ -f "/etc/apt/sources.list" ]]; then
            cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
        fi
        
        echo -e "${Info} 正在将apt源修改为 ${input}..."
        
        # 使用更精确的正则表达式替换apt源
        local sed_patterns="s@http://[^/]*\.ubuntu\.com/@${input}@g;"
        sed_patterns+="s@http://[^/]*\.debian\.org/@${input}@g;"
        sed_patterns+="s@http://[^/]*security\.ubuntu\.com/@${input}@g;"
        sed_patterns+="s@http://[^/]*security\.debian\.org/@${input}@g;"
        sed_patterns+="s@https://[^/]*\.ubuntu\.com/@${input}@g;"
        sed_patterns+="s@https://[^/]*\.debian\.org/@${input}@g;"
        sed_patterns+="s@https://[^/]*security\.ubuntu\.com/@${input}@g;"
        sed_patterns+="s@https://[^/]*security\.debian\.org/@${input}@g;"
        
        if sed -i "${sed_patterns}" /etc/apt/sources.list 2>/dev/null; then
            echo -e "${Info} apt源地址替换完成，正在更新软件包列表..."
            if apt update 2>/dev/null; then
                echo -e "${Info} apt源已成功修改为 ${input}"
                return 0
            else
                echo -e "${Error} apt更新失败，请检查网络连接和源地址"
                return 1
            fi
        else
            echo -e "${Error} apt源修改失败"
            return 1
        fi
    done
    
    echo -e "${Error} 已达到最大尝试次数，返回主菜单"
    return 1
}

View_napcat_webui_info() {
    check_installed_napcat_status
    
    cd ${napcat_DIR}/napcat/config || {
        echo -e "${Error} napcat 配置目录不存在"
        return 1
    }
    
    # 获取基本配置
    pathName=$(jq -r '.pathName // "未知"' napcat.json 2>/dev/null)
    
    # 检查 WebUI 配置是否存在
    if [[ ! -f "webui.json" ]]; then
        echo -e "${Error} WebUI 配置文件不存在: webui.json"
        echo -e "${Info} 请确保 napcat 已正确安装并配置"
        echo "请按任意键返回..."
        read -n 1 -s
        return 1
    fi
    
    token=$(jq -r '.token // "未设置"' webui.json 2>/dev/null)
    port=$(jq -r '.port // 0' webui.json 2>/dev/null)
    
    # 获取IP地址
    local local_ipv4=$(hostname -I | awk '{print $1}' | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || echo "127.0.0.1")
    local public_ipv4=""
    local public_ipv6=""
    
    # 获取公网IP（带超时和错误处理）
    echo -e "${Info} 正在获取公网IP地址..."
    
    # 获取公网IPv4
    if command -v curl &>/dev/null; then
        public_ipv4=$(timeout 5 curl -s -4 https://api.ipify.org 2>/dev/null || timeout 5 curl -s -4 http://4.ipw.cn 2>/dev/null || echo "无法获取")
    else
        public_ipv4="curl 未安装"
    fi
    
    # 获取公网IPv6
    if command -v curl &>/dev/null && ip -6 addr show scope global &>/dev/null; then
        public_ipv6=$(timeout 5 curl -s -6 https://api.ipify.org 2>/dev/null || timeout 5 curl -s -6 http://6.ipw.cn 2>/dev/null || echo "无法获取")
    else
        public_ipv6="IPv6 不可用"
    fi
    
    # 获取 OneBot 配置端口
    local onebot_port=""
    local onebot_config="onebot11_${pathName}.json"
    if [[ -f "${onebot_config}" ]]; then
        onebot_port=$(jq -r '.port // 0' "${onebot_config}" 2>/dev/null)
        if [[ "${onebot_port}" == "0" ]]; then
            # 尝试从 WebSocket URL 提取端口
            onebot_port=$(jq -r '.urls[0] // ""' "${onebot_config}" 2>/dev/null | sed -n 's/.*://p' | sed 's|/onebot.*||')
        fi
    fi
    
    # 显示信息
    echo -e "========================================="
    echo -e "${Info} 当前 Bot QQ：${Green_font_prefix}${pathName}${Font_color_suffix}"
    echo -e "${Info} WebUI 登录密钥（token）：${Green_font_prefix}${token}${Font_color_suffix}"
    echo -e "${Info} WebUI 端口：${Green_font_prefix}${port}${Font_color_suffix}"
    if [[ -n "${onebot_port}" && "${onebot_port}" != "0" ]]; then
        echo -e "${Info} OneBot 端口：${Green_font_prefix}${onebot_port}${Font_color_suffix}"
    fi
    echo -e "========================================="
    echo -e "${Info} WebUI 访问地址："
    echo -e "${Info} 内网 IPv4：http://${local_ipv4}:${port}/webui/login.html"
    
    if [[ "${public_ipv4}" != "无法获取" && -n "${public_ipv4}" ]]; then
        echo -e "${Info} 公网 IPv4：http://${public_ipv4}:${port}/webui/login.html"
    else
        echo -e "${Info} 公网 IPv4：无法获取（可能需要配置端口转发）"
    fi
    
    if [[ "${public_ipv6}" != "IPv6 不可用" && -n "${public_ipv6}" ]]; then
        echo -e "${Info} 公网 IPv6：http://[${public_ipv6}]:${port}/webui/login.html"
    else
        echo -e "${Info} 公网 IPv6：${public_ipv6}"
    fi
    echo -e "========================================="
    
    # 显示 OneBot WebSocket 地址
    if [[ -n "${onebot_port}" && "${onebot_port}" != "0" ]]; then
        echo -e "${Info} OneBot WebSocket 地址："
        echo -e "${Info} IPv4: ws://${local_ipv4}:${onebot_port}/onebot/v11/ws"
        if [[ "${public_ipv4}" != "无法获取" && -n "${public_ipv4}" ]]; then
            echo -e "${Info} 公网 IPv4: ws://${public_ipv4}:${onebot_port}/onebot/v11/ws"
        fi
        if [[ "${public_ipv6}" != "IPv6 不可用" && -n "${public_ipv6}" ]]; then
            echo -e "${Info} IPv6: ws://[${public_ipv6}]:${onebot_port}/onebot/v11/ws"
        fi
        echo -e "========================================="
    fi
    
    # napcat 不支持代理配置，已移除相关功能
    
    # 显示连接状态提示
    echo -e "${Tip} 提示："
    echo -e "${Tip} 1. 如果无法访问 WebUI，请检查防火墙设置"
    echo -e "${Tip} 2. 公网访问需要配置端口转发（如果是内网）"
    echo -e "${Tip} 3. IPv6 访问需要防火墙放行对应端口"
    echo -e "${Tip} 4. 确保 token 安全，不要泄露给他人"
    
    echo -e "========================================="
    echo "请按任意键返回..."
    read -n 1 -s
}

Set_dependency() {
    cd ${WORK_DIR}/zhenxun_bot || exit
    Set_pip_Mirror
    pip install poetry || pip install poetry --break-system-packages
    poetry env use ${python_v}
    if [ $python_v = "3.9" ]; then
      sed -i 's|python =.*|python = "\^3\.9"|g' pyproject.toml
      sed -i 's|pythonVersion =.*|pythonVersion = "3.9"|g' pyproject.toml
    fi
    poetry install
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
      echo -e "${Info} 操作已取消..." && # 命令行参数处理
parse_arguments() {
    local use_docker="n"
    local use_cli="n" 
    local proxy_num="0"
    local force_install="n"
    local qq_number=""
    local run_mode="reverse_ws"
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --docker)
                use_docker="$2"
                shift 2
                ;;
            --cli)
                use_cli="$2"
                shift 2
                ;;
            --proxy)
                proxy_num="$2"
                shift 2
                ;;
            --force)
                force_install="y"
                shift
                ;;
            --qq)
                qq_number="$2"
                shift 2
                ;;
            --mode)
                run_mode="$2"
                shift 2
                ;;
            --help|-h)
                echo "用法: $0 [选项]"
                echo "选项:"
                echo "  --docker <y/n>     是否使用Docker安装 (默认: n)"
                echo "  --cli <y/n>        是否安装TUI-CLI (默认: n)"
                echo "  --proxy <0-4>      代理选择 (0: 不使用, 1-4: 不同代理)"
                echo "  --force            强制安装/更新"
                echo "  --qq <QQ号>        QQ号 (Docker模式需要)"
                echo "  --mode <模式>      运行模式: ws, reverse_ws, reverse_http (默认: reverse_ws)"
                echo "  --help, -h         显示帮助信息"
                echo ""
                echo "示例:"
                echo "  $0 --docker n --cli n --proxy 0 --force"
                echo "  $0 --docker y --qq 123456 --mode reverse_ws --proxy 1"
                exit 0
                ;;
            *)
                echo "未知参数: $1"
                echo "使用 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done
    
    # 设置代理
    if [[ "${proxy_num}" != "0" ]]; then
        Set_ghproxy_auto "${proxy_num}"
    fi
    
    # 设置force变量
    if [[ "${force_install}" == "y" ]]; then
        force="y"
    fi
    
    # 执行安装
    if [[ "${use_docker}" == "y" ]]; then
        # Docker模式
        if [[ -z "${qq_number}" ]]; then
            echo -e "${Error} Docker模式需要提供QQ号"
            exit 1
        fi
        install_napcat_docker "${qq_number}" "${run_mode}"
    else
        # Shell模式
        Install_napcat
        
        # 如果需要安装CLI
        if [[ "${use_cli}" == "y" ]]; then
            install_napcat_cli
        fi
    fi
}

# 自动设置代理函数
Set_ghproxy_auto() {
    local proxy_num="${1:-1}"
    
    if [[ "${proxy_num}" == "0" ]]; then
        ghproxy=""
        return
    fi
    
    # 代理列表
    local proxy_arr=("https://github.moeyy.xyz/" "https://gh-proxy.com/" "https://x.haod.me/" "https://mirror.ghproxy.com/")
    
    # 确保proxy_num在有效范围内
    if [[ ${proxy_num} -lt 1 || ${proxy_num} -gt ${#proxy_arr[@]} ]]; then
        proxy_num=1
    fi
    
    ghproxy="${proxy_arr[$((proxy_num-1))]}"
    echo -e "${Info} 自动设置代理: ${ghproxy}"
}

# 如果有命令行参数，则解析参数，否则显示菜单
if [[ $# -gt 0 ]]; then
    parse_arguments "$@"
else
    menu_zhenxun
fi
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
    
    # 检查Python版本，如果低于3.10则提供安装选项
    if ! check_python_version; then
        echo -e "${Error} 检测到系统Python版本低于3.10，真寻机器人需要Python 3.10或更高版本"
        echo -e "${Info} 是否自动安装Python 3.10+？ (y/n)"
        read -r install_python_choice
        if [[ "$install_python_choice" == "y" || "$install_python_choice" == "Y" ]]; then
            echo -e "${Info} 开始安装Python 3.10+..."
            install_python_minimal
        else
            echo -e "${Error} 安装已取消，请先手动安装Python 3.10或更高版本"
            exit 1
        fi
    fi
    
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

Install_Python() {
    echo -e "${Info} 开始检查Python版本..."
    if check_python_version; then
        echo -e "${Info} 当前Python版本符合要求，无需安装"
        return 0
    fi
    
    echo -e "${Info} 检测到系统Python版本低于3.10"
    echo -e "${Info} 是否自动安装Python 3.10+？ (y/n)"
    read -r install_python_choice
    if [[ "$install_python_choice" == "y" || "$install_python_choice" == "Y" ]]; then
        echo -e "${Info} 开始安装Python 3.10+..."
        install_python_minimal
        echo -e "${Info} Python安装完成！"
    else
        echo -e "${Info} 安装已取消"
    fi
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
    pathName=$(jq '.pathName' napcat.json | sed 's/\"//g')
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
 ${Green_font_prefix} 9.${Font_color_suffix} 安装/升级 Python 3.10+
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 termux 菜单
 ${Green_font_prefix}11.${Font_color_suffix} 切换为 napcat 菜单
 ${Green_font_prefix}12.${Font_color_suffix} 切换为 postgresql 菜单" && echo
  
  # 显示Python版本状态
  if check_python_version; then
    current_python=$(python3 --version 2>/dev/null || echo "未安装")
    echo -e " Python状态: ${Green_font_prefix}${current_python}${Font_color_suffix} (符合要求)"
  else
    current_python=$(python3 --version 2>/dev/null || echo "未安装")
    echo -e " Python状态: ${Red_font_prefix}${current_python}${Font_color_suffix} (需要3.10+)"
  fi
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
    Install_Python
    ;;
  10)
    menu_termux
    ;;
  11)
    menu_napcat
    ;;
  12)
    menu_postgresql
    ;;
  *)
    echo "请输入正确数字 [0-12]" && menu_zhenxun
    ;;
  esac
}
menu_zhenxun
