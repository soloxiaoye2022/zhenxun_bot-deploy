#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

update_shell_url="https://raw.githubusercontent.com/soloxiaoye2022/zhenxun_bot-deploy/main/install.sh"
zhenxun_url="https://github.com/zhenxun-org/zhenxun_bot.git"
proxy_arr=("https://ghfast.top/" "https://github.moeyy.xyz/" "https://gh-proxy.com/" "https://mirror.ghproxy.com/")
check_url="https://raw.githubusercontent.com/LuckyLilliaDev/LuckyLilliaBot/main/README.md"
llbot_repo="https://github.com/LuckyLilliaDev/LuckyLilliaBot"
zhenxun_bot_plugins_url="https://github.com/zhenxun-org/zhenxun_bot_plugins"
llbot_cli_x64="LuckyLillia-CLI-linux-x64.zip"
llbot_cli_arm64="LuckyLillia-CLI-linux-arm64.zip"
api_url="https://api.github.com/repos/LuckyLilliaDev/LuckyLilliaBot/releases/latest"
WORK_DIR="/root"
TMP_DIR="$(mktemp -d)"
NAPCAT_HOME="/root/LLBot"
napcat_DIR="/root/LLBot"
LLBOT_HOME="/root/LLBot"
ZX_DIR="${WORK_DIR}/zhenxun_bot/"
sh_ver="3.2.0"
LLBOT_WEBUI_PORT="3080"
TUI_BIN=""
mirror_url='"https://pypi.org/simple"'
musicSignUrl="https://llob.linyuchen.net/sign/music"
ssh_port="8022"
mix="1024"
max="49151"
dns="8.8.8.8"
DEFAULT_PORT="8080"
DEFAULT_SQLITE_URL="sqlite:data/db/zhenxun.db"

#检查python（真寻需要 >= 3.10）
if which python3.12 > /dev/null;then
  which python3.12
elif which python3.11 > /dev/null;then
  which python3.11
elif which python3.10 > /dev/null;then
  which python3.10
fi
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Red_background_prefix="\033[41;37m" && Purple_font_prefix="\033[33m" && Font_color_suffix="\033[0m"
Green_background_prefix="\033[42;37m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Purple_font_prefix}[注意]${Font_color_suffix}"

ensure_tui() {
	TUI_BIN=""
	if command -v whiptail >/dev/null 2>&1; then
		TUI_BIN="whiptail"
	elif command -v dialog >/dev/null 2>&1; then
		TUI_BIN="dialog"
	fi
}

tui_available() {
	[[ -n "${TUI_BIN}" && -t 0 && -t 1 && -z "${ZX_NO_TUI:-}" ]]
}

tui_menu() {
	local title="$1"
	local text="$2"
	shift 2
	"${TUI_BIN}" --title "${title}" --menu "${text}" 0 60 0 "$@" 3>&1 1>&2 2>&3
}

tui_yesno() {
	local title="$1"
	local text="$2"
	"${TUI_BIN}" --title "${title}" --yes-button "Yes" --no-button "No" --yesno "${text}" 0 60
}

tui_input() {
	local title="$1"
	local text="$2"
	local default="${3:-}"
	"${TUI_BIN}" --title "${title}" --inputbox "${text}" 0 60 "${default}" 3>&1 1>&2 2>&3
}

tui_msg() {
	local title="$1"
	local text="$2"
	"${TUI_BIN}" --title "${title}" --msgbox "${text}" 0 60
}

press_enter_to_return() {
	echo -e "按 ${Green_font_prefix}回车键${Font_color_suffix} 返回"
	read -r
}

install_tui_pkg() {
	if command -v whiptail >/dev/null 2>&1 || command -v dialog >/dev/null 2>&1; then
		ensure_tui
		return 0
	fi
	if command -v apt-get >/dev/null 2>&1; then
		DEBIAN_FRONTEND=noninteractive apt-get update -y >/dev/null 2>&1 || true
		DEBIAN_FRONTEND=noninteractive apt-get install -y whiptail >/dev/null 2>&1 || DEBIAN_FRONTEND=noninteractive apt-get install -y dialog >/dev/null 2>&1 || true
	elif command -v yum >/dev/null 2>&1; then
		yum install -y newt >/dev/null 2>&1 || true
	elif command -v pacman >/dev/null 2>&1; then
		pacman -Sy --noconfirm libnewt >/dev/null 2>&1 || true
	fi
	ensure_tui
}

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
    check_supported_os
}

check_supported_os() {
    os_id=""
    os_ver=""
    if [[ -f /etc/os-release ]]; then
        os_id=$(grep -E '^ID=' /etc/os-release | head -n 1 | cut -d= -f2 | tr -d '"')
        os_ver=$(grep -E '^VERSION_ID=' /etc/os-release | head -n 1 | cut -d= -f2 | tr -d '"' | cut -d. -f1)
    fi
    if [[ "${release}" == "debian" && -n "${os_ver}" && "${os_ver}" -lt 11 ]]; then
        echo -e "${Error} 仅支持 Debian 11/12+，当前 VERSION_ID=${os_ver}" && exit 1
    fi
    if [[ "${release}" == "ubuntu" && -n "${os_ver}" && "${os_ver}" -lt 20 ]]; then
        echo -e "${Error} 仅支持 Ubuntu 20/22/24，当前 VERSION_ID=${os_ver}" && exit 1
    fi
}

check_installed_zhenxun_status() {
  [[ ! -e "${WORK_DIR}/zhenxun_bot/pyproject.toml" ]] && echo -e "${Error} zhenxun_bot 没有安装，请检查 !" && exit 1
}

check_installed_napcat_status() {
  if [[ -x "${LLBOT_HOME}/llbot" ]] || [[ -x "${LLBOT_HOME}/start.sh" ]]; then
    return 0
  fi
  echo -e "${Error} LLBot 没有安装，请检查 !" && exit 1
}

check_pid_zhenxun() {
  PID=$(pgrep -f "uv run zx|zhenxun.cli|bot.py")
}

check_pid_napcat() {
  PID=$(pgrep -f "${LLBOT_HOME}/llbot|${LLBOT_HOME}/start.sh")
}

check_pid_postgres() {
  #PID=$(ps -ef | grep "sergate" | grep -v grep | grep -v ".sh" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
  PID=$(pgrep -f "postgresql")
}

Set_pip_Mirror() {
    if tui_available; then
      mirror_num=$(tui_menu "pip 源" "请选择 pip / uv 下载源（默认北外）" \
        "1" "清华" \
        "2" "腾讯" \
        "3" "阿里" \
        "4" "中科大" \
        "5" "北外 (默认)" \
        "6" "不修改") || mirror_num="5"
    else
      echo -e "${Info} 请输入要选择的pip下载源，默认使用北外源
    ${Green_font_prefix} 1.${Font_color_suffix} 清华 
    ${Green_font_prefix} 2.${Font_color_suffix} 腾讯
    ${Green_font_prefix} 3.${Font_color_suffix} 阿里
    ${Green_font_prefix} 4.${Font_color_suffix} 中科大
    ${Green_font_prefix} 5.${Font_color_suffix} 北外 (默认)
    ${Green_font_prefix} 6.${Font_color_suffix} 不修改"
      read -erp "请输入数字 [1-6], 默认为 5:" mirror_num
    fi
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
      export UV_INDEX_URL="${pip_url}"
    elif [ "$mirror_num" -gt 6 ]; then
      echo -e"${Info} 你可能没有输入正确的选项?"
      Set_pip_Mirror
    fi
}

Set_ghproxy() {
  if tui_available; then
    if tui_yesno "GitHub 代理" "是否使用 ghproxy 代理 git 相关下载？\n中国大陆建议使用"; then
      ghproxy_check="y"
    else
      ghproxy_check="n"
    fi
  else
    echo -e "${Info} 是否使用 ghproxy 代理git相关的下载？(中国大陆建议使用)"
    read -erp "请选择 [y/n], 默认为 y:" ghproxy_check
  fi
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
    export DEBIAN_FRONTEND=noninteractive
    if [[ ${release} == "centos" ]]; then
        yum -y update
        yum install -y git fontconfig mkfontscale epel-release wget vim zip unzip jq curl xorg-x11-server-Xvfb screen python3 python3-pip ffmpeg atk at-spi2-atk cups-libs libxkbcommon libXcomposite libXdamage libXrandr mesa-libgbm gtk3 newt
        echo -e "${Info} 默认使用 Sqlite，跳过自动安装 PostgreSQL（可在 postgresql 菜单中手动安装）"
    elif [[ ${release} == "debian" ]]; then
        apt-get update
        apt-get install -y wget ttf-wqy-zenhei jq xfonts-intl-chinese python3 python3-pip python3-venv python3-dev
        apt-get install -y \
            vim git zip unzip curl xvfb screen ffmpeg \
            libgl1 libglib2.0-0 libnss3 libatk1.0-0 libatk-bridge2.0-0 \
            libcups2 libxkbcommon0 libxcomposite1 libxrandr2 libgbm1 libgtk-3-0 \
            whiptail
        apt-get install -y libasound2t64 || apt-get install -y libasound2 || true
        apt --fix-broken install -y || true
        echo -e "${Info} 默认使用 Sqlite，跳过自动安装 PostgreSQL（可在 postgresql 菜单中手动安装）"
    elif [[ ${release} == "ubuntu" ]]; then
        apt-get update
        apt-get install -y software-properties-common ttf-wqy-zenhei ttf-wqy-microhei fonts-arphic-ukai fonts-arphic-uming python3 python3-pip python3-venv python3-dev
        fc-cache -f -v || true
        if ! which python3.12 >/dev/null 2>&1 && ! which python3.11 >/dev/null 2>&1 && ! which python3.10 >/dev/null 2>&1; then
            add-apt-repository -y ppa:deadsnakes/ppa || true
            apt-get update
            apt-get install -y python3.10-full || apt-get install -y python3.11-full || true
        fi
        apt-get install -y \
            vim git zip unzip jq curl xvfb screen ffmpeg \
            libgl1 libglib2.0-0 libnss3 libatk1.0-0 libatk-bridge2.0-0 \
            libcups2 libxkbcommon0 libxcomposite1 libxrandr2 libgbm1 libgtk-3-0 \
            whiptail
        apt-get install -y libasound2t64 || apt-get install -y libasound2 || true
        apt --fix-broken install -y || true
        echo -e "${Info} 默认使用 Sqlite，跳过自动安装 PostgreSQL（可在 postgresql 菜单中手动安装）"
    elif [[ ${release} == "archlinux" ]]; then
        pacman -Sy python python-pip unzip git curl wget jq zip ffmpeg libnewt --noconfirm
    fi

    if which python3.12 >/dev/null 2>&1; then
      python_v="python3.12"
    elif which python3.11 >/dev/null 2>&1; then
      python_v="python3.11"
    elif which python3.10 >/dev/null 2>&1; then
      python_v="python3.10"
    else
      echo -e "${Error} 真寻需要 Python >= 3.10，请先安装 python3.10/3.11/3.12" && exit 1
    fi
    
    [[ ! -e /usr/bin/python3 ]] && ln -s /usr/bin/${python_v} /usr/bin/python3
    if command -v apt-get >/dev/null 2>&1; then
      apt-get install -y ${python_v}-dev || apt-get install -y python3-dev || true
    fi
    ensure_tui
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
      echo -e "${Error} LLBot CLI 仅提供 linux-x64 / linux-arm64，不支持该内核版本(${get_arch})..." && exit 1
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
      nohup uv run zx > zhenxun_bot.log 2>&1 & 
      echo -e "${Info} 正在检测 zhenxun_bot 缺失依赖(需要约1分钟)"
      sleep 60
      [[ ! -z ${PID} ]] && kill -9 "${PID}"
      cat ${log} | grep "No module named" | awk -F "'" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g' | sed 's/ /\n/' > /root/zhenxun_bot/requests.txt
      Install_module
    else
      echo -e "${Error} log文件不存在,即将自动启动 zhenxun_bot 并生成log文件"
      cd ${dir} || exit
      nohup uv run zx > zhenxun_bot.log 2>&1 & 
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
      echo -e "${Info} 本次检测到以下版本依赖需要安装,如果安装失败请手动进入项目目录执行 uv add / uv sync"
      sleep 1
      uv add $module || uv pip install $module -i "${pip_url}"
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
      if tui_available; then
        if tui_yesno "DNS" "检测到本机 DNS [${local_dns}] 不是 8.8.8.8\n是否修改？大陆地区不改可能有网络问题"; then
          dns_check="y"
        else
          dns_check="n"
        fi
      else
        echo -e "${Info} 检测到本机dns [${local_dns}] 不是谷歌dns,是否修改 dns ?(大陆地区不修改可能会有各种蜜汁网络问题)"
        read -erp "请选择 [y/n], 默认为 y:" dns_check
      fi
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
        echo -e "${Info} 真寻本体已克隆，插件请启动后通过插件商店安装（本体与插件库已分离）"
        echo -e "${Info} 插件库：${zhenxun_bot_plugins_url}"
        echo -e "${Info} 插件索引库：https://github.com/zhenxun-org/zhenxun_bot_plugins_index"
        break
      elif [ $i -lt 5 ]; then
        echo -e "${Info} 第${i}次尝试失败，正在重试..."
      else
        echo -e "${Error} 无法下载 zhenxun_bot，请检查网络。" && exit 1
      fi
    done

    cd ${WORK_DIR}
    mv ${TMP_DIR}/zhenxun_bot ./
    mkdir -p ${ZX_DIR}data/db
    if [[ -e "${ZX_DIR}.env.example" && ! -e "${ZX_DIR}.env.dev" ]]; then
      cp "${ZX_DIR}.env.example" "${ZX_DIR}.env.dev"
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

llbot_asset_name() {
    if [[ "${arch}" == "arm64" ]]; then
      echo "${llbot_cli_arm64}"
    else
      echo "${llbot_cli_x64}"
    fi
}

get_napcat_version() {
    llbot_file=$(llbot_asset_name)
    json_data=$(curl -fsSL --connect-timeout 20 --max-time 60 -A "zhenxun-bot-deploy" "$api_url" || true)
    napcat_version=$(jq -r '.tag_name' <<< "$json_data" 2>/dev/null || true)
    napcat_download_url=$(jq -r --arg name "${llbot_file}" '.assets[] | select(.name == $name) | .browser_download_url' <<< "$json_data" 2>/dev/null || true)
    if [[ -z "${napcat_version}" || "${napcat_version}" == "null" ]]; then
      napcat_version="latest"
    fi
    if [[ -z "${napcat_download_url}" || "${napcat_download_url}" == "null" ]]; then
      napcat_download_url="https://github.com/LuckyLilliaDev/LuckyLilliaBot/releases/latest/download/${llbot_file}"
    fi
}

update_napcat() {
    check_arch
    get_napcat_version
    echo -e "${Info} 最新 LLBot 版本：${napcat_version}"
    if [[ -x "${LLBOT_HOME}/llbot" ]] || [[ -x "${LLBOT_HOME}/start.sh" ]]; then
      current_version="0.0.0"
      if [[ -f "${LLBOT_HOME}/version.txt" ]]; then
        current_version=$(tr -d 'vV \n' < "${LLBOT_HOME}/version.txt")
      fi
      echo -e "${Info} LLBot 已安装，记录版本：v${current_version}"
      if [[ "${napcat_version}" == "latest" ]]; then
        Install_napcat
        return 0
      fi
      target_version=${napcat_version#v}
      IFS='.' read -r i1 i2 i3 <<< "${current_version}"
      IFS='.' read -r t1 t2 t3 <<< "${target_version}"
      i1=${i1:-0}; i2=${i2:-0}; i3=${i3:-0}
      t1=${t1:-0}; t2=${t2:-0}; t3=${t3:-0}
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
    echo -e "${Info} LinuxQQ 由 LLBot start.sh 在缺失时引导安装，跳过旧版手动下载..."
}

Download_napcat() {
    echo -e "${Info} 下载并安装 LLBot CLI..."
    Install_napcat
}

Install_napcat() {
    check_arch
    check_sys
    get_napcat_version
    llbot_file=$(llbot_asset_name)
    echo -e "${Info} 开始安装 LLBot CLI（${llbot_file}）到 ${LLBOT_HOME} ..."
    echo -e "${Tip} NapCat-Installer 仓库已 404；真寻 QQ 页仍列 LLOneBot/NapCat/Lagrange。本脚本改用仍在发版的 LLBot（LuckyLilliaBot，原 LLOneBot）。"
    echo -e "${Tip} 官方 CLI 仅 linux-x64 / linux-arm64。Termux 请走 tmoe/proot 的 Debian12 或 Ubuntu22.04 arm64。"
    if [[ -z "${napcat_download_url}" || "${napcat_download_url}" == "null" ]]; then
      napcat_download_url="https://github.com/LuckyLilliaDev/LuckyLilliaBot/releases/latest/download/${llbot_file}"
    fi
    cd "${TMP_DIR}" || exit 1
    downloaded=""
    for (( i=1; i<=5; i++ )); do
      if curl -fL --connect-timeout 20 --max-time 1800 -o "${llbot_file}" "${ghproxy}${napcat_download_url}"; then
        downloaded="yes"
        break
      elif curl -fL --connect-timeout 20 --max-time 1800 -o "${llbot_file}" "${napcat_download_url}"; then
        downloaded="yes"
        break
      elif [ $i -lt 5 ]; then
        echo -e "${Info} 第${i}次尝试下载 LLBot 失败，正在重试..."
      fi
    done
    if [[ -z "${downloaded}" ]]; then
      echo -e "${Error} 无法下载 LLBot CLI。请检查网络后手动执行："
      echo -e "mkdir -p ${LLBOT_HOME} && cd ${LLBOT_HOME} && wget ${napcat_download_url}"
      exit 1
    fi
    mkdir -p "${LLBOT_HOME}"
    unzip -o "${llbot_file}" -d "${LLBOT_HOME}"
    if [[ -x "${LLBOT_HOME}/start.sh" ]]; then
      chmod +x "${LLBOT_HOME}/start.sh"
    fi
    if [[ -x "${LLBOT_HOME}/llbot" ]]; then
      chmod +x "${LLBOT_HOME}/llbot"
    fi
    echo "${napcat_version}" > "${LLBOT_HOME}/version.txt"
    echo -e "${Info} LLBot 安装完成：${LLBOT_HOME}  WebUI 默认 http://127.0.0.1:${LLBOT_WEBUI_PORT}"
}

clean() {
    rm -rf ${TMP_DIR}
    if [ $? -ne 0 ]; then
      echo -e "${Error} 临时文件删除失败，请手动删除 ${TMP_DIR}。"
    fi
}


Set_config_admin() {
    while true; do
      if tui_available; then
        admin_qq=$(tui_input "管理员 QQ" "请输入管理员 QQ（超级用户）" "${admin_qq:-}") || admin_qq=""
      else
        echo -e "${Info} 请输入管理员QQ账号(也就超级用户账号):[QQ]"
        read -erp "管理员QQ:" admin_qq
      fi
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
      if tui_available; then
        bot_qq=$(tui_input "Bot QQ" "请输入 Bot QQ 账号" "${bot_qq:-}") || bot_qq=""
      else
        echo -e "${Info} 请输入Bot QQ账号:[QQ]"
        read -erp "Bot QQ:" bot_qq
      fi
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
    mkdir -p ${LLBOT_HOME}/bin/llbot/data ${LLBOT_HOME}/config
    echo $qq_data | jq > ${LLBOT_HOME}/qq_data.json
    echo -e "${Info} 设置成功!Bot QQ: [""${Green_font_prefix}"${bot_qq}"${Font_color_suffix}""]"
    
}

write_llbot_onebot_config() {
    mkdir -p ${LLBOT_HOME}/bin/llbot/data ${LLBOT_HOME}/config
    cat > ${LLBOT_HOME}/config/config_${bot_qq}.json <<-EOF
{
  "ob11": {
    "enable": true,
    "connect": [
      {
        "type": "ws-reverse",
        "enable": true,
        "url": "ws://127.0.0.1:${Port}/onebot/v11/ws",
        "token": "",
        "reportSelfMessage": true,
        "reportOfflineMessage": false,
        "messageFormat": "array",
        "debug": true,
        "heartInterval": 30000
      }
    ]
  },
  "webui": {
    "enable": true,
    "host": "127.0.0.1",
    "port": ${LLBOT_WEBUI_PORT}
  }
}
EOF
    cp -f ${LLBOT_HOME}/config/config_${bot_qq}.json ${LLBOT_HOME}/bin/llbot/config_${bot_qq}.json 2>/dev/null || true
    cp -f ${LLBOT_HOME}/config/config_${bot_qq}.json ${LLBOT_HOME}/bin/llbot/default_config.json 2>/dev/null || true
}

Set_config() { 
    Set_config_admin
    Set_config_bot
    Set_Port
    Set_sqlite_bind
    write_llbot_onebot_config
}

Set_Port() {
    while true; do
      if tui_available; then
        Port=$(tui_input "通信端口" "zhenxun_bot 与 LLBot 通信端口\n范围 ${mix}-${max}，默认 ${DEFAULT_PORT}" "${DEFAULT_PORT}") || Port="${DEFAULT_PORT}"
      else
        echo -e "${Info} 请设置zhenxun_bot 与 LLBot 通信端口:取值范围[""${Green_font_prefix}"${mix}-${max}"${Font_color_suffix}""]，默认 ${DEFAULT_PORT}"
        read -erp "Port:" Port
      fi
      [[ -z "${Port}" ]] && Port="${DEFAULT_PORT}"
        if [ "${Port}" -ge ${mix} -a "${Port}" -le ${max} ]; then
          cd ${WORK_DIR}/zhenxun_bot && sed -i -e "s/PORT.*/PORT = ${Port}/" .env.dev || echo -e "${Error} 配置文件不存在！请检查zhenxun_bot是否安装正确!"
          echo -e "${Info} 设置成功!端口: [""${Green_font_prefix}"${Port}"${Font_color_suffix}""]"
          echo -e "${Info} 反向 WS 地址：ws://127.0.0.1:${Port}/onebot/v11/ws"
          break
        else 
          echo -e "${Error} 端口设置错误，取值范围[""${Green_font_prefix}"${mix}-${max}"${Font_color_suffix}""]"
        fi  
    done   
}

Set_sqlite_bind() {
    echo -e "${Info} 默认使用 Sqlite（官方推荐开箱即用，无需安装数据库）..."
    mkdir -p ${WORK_DIR}/zhenxun_bot/data/db
    cd ${WORK_DIR}/zhenxun_bot && sed -i 's|DB_URL.*|DB_URL = "sqlite:data/db/zhenxun.db"|g' .env.dev
}

Set_postgresql_bind() {
    echo -e "${Info} 开始设置 PostgreSQL 连接语句..."
    echo -e "${Tip} 官方教程默认：postgres://postgres:zhenxun_bot@127.0.0.1:5432/zhenxun_bot"
    cd ${WORK_DIR}/zhenxun_bot && sed -i 's|DB_URL.*|DB_URL = "postgres://postgres:zhenxun_bot@127.0.0.1:5432/zhenxun_bot"|g' .env.dev
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
    cd ${WORK_DIR}/zhenxun_bot || exit
    nohup uv run zx >> zhenxun_bot.log 2>&1 &
    echo -e "${Info} zhenxun_bot 开始运行... 默认 WebUI: http://127.0.0.1:8080"
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

Start_napcat() {
    check_installed_napcat_status
    check_pid_napcat
    pathName=""
    if [[ -e "${LLBOT_HOME}/qq_data.json" ]]; then
      pathName=$(jq -r '.bot_qq' ${LLBOT_HOME}/qq_data.json)
    fi
    [[ -n ${PID} ]] && echo -e "${Error} LLBot 正在运行，请检查 !" && exit 1
    mkdir -p ${LLBOT_HOME}/logs
    cd ${LLBOT_HOME} || exit 1
    if [[ -x "${LLBOT_HOME}/start.sh" ]]; then
      nohup bash "${LLBOT_HOME}/start.sh" >> ${LLBOT_HOME}/logs/llbot.log 2>&1 &
    elif [[ -x "${LLBOT_HOME}/llbot" ]]; then
      nohup "${LLBOT_HOME}/llbot" --headless --host=127.0.0.1 --port=13000 >> ${LLBOT_HOME}/logs/llbot.log 2>&1 &
    else
      echo -e "${Error} 未找到 ${LLBOT_HOME}/start.sh 或 llbot" && exit 1
    fi
    echo -e "${Info} LLBot 开始运行... WebUI: http://127.0.0.1:${LLBOT_WEBUI_PORT}"
    echo -e "${Info} 反向 WS：ws://127.0.0.1:${Port:-${DEFAULT_PORT}}/onebot/v11/ws"
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
    [[ -z ${PID} ]] && echo -e "${Error} LLBot 没有运行，请检查 !" && exit 1
    kill -9 ${PID}
    echo -e "${Info} LLBot 停止运行..."
}

Restart_napcat() {
    Stop_napcat
    Start_napcat
}

View_napcat_log() {
    check_installed_napcat_status
    if [[ -e "${LLBOT_HOME}/logs/llbot.log" ]]; then
      tail -f -n 100 ${LLBOT_HOME}/logs/llbot.log
    else
      echo -e "${Tip} 日志文件不存在，请先启动 LLBot"
    fi
}

View_postgresql_info() {
    echo -e "${Info} 查询信息如下..."
    su postgres <<-EOF
          echo -e '\l' | psql
EOF

}

Set_config_napcat() {
    check_installed_napcat_status
    pathName=$(jq -r '.bot_qq' ${LLBOT_HOME}/qq_data.json 2>/dev/null)
    if [[ -n "${pathName}" && -e "${LLBOT_HOME}/config/config_${pathName}.json" ]]; then
      vim ${LLBOT_HOME}/config/config_${pathName}.json
    elif [[ -e "${LLBOT_HOME}/bin/llbot/default_config.json" ]]; then
      vim ${LLBOT_HOME}/bin/llbot/default_config.json
    else
      echo -e "${Error} 未找到 LLBot 配置文件" && exit 1
    fi
}

Set_config_zhenxun() {
    if [[ -e "${WORK_DIR}/zhenxun_bot/data/config.yaml" ]]; then
      vim ${WORK_DIR}/zhenxun_bot/data/config.yaml
    else
      echo -e "${Tip} data/config.yaml 需启动一次 Bot 后生成，先编辑 .env.dev"
      vim ${WORK_DIR}/zhenxun_bot/.env.dev
    fi
}

Set_apt_source() {
    if tui_available; then
      apt_source=$(tui_menu "apt 源" "请选择 apt 源修改方式" \
        "1" "apt 源列表" \
        "2" "手动输入") || apt_source="1"
    else
      echo -e "${Info} 请选择apt源修改方式
    ${Green_font_prefix} 1.${Font_color_suffix} apt源列表
    ${Green_font_prefix} 2.${Font_color_suffix} 手动输入"
      read -erp "请输入数字 [1-2], 默认为 1:" apt_source
    fi
    if [[ -z "${apt_source}" ]]; then
      select_apt_source
    elif [[ "${apt_source}" = "1" ]]; then
      select_apt_source
    elif [[ ${apt_source} = "2" ]]; then
      Manual_input_source
    fi

}

select_apt_source() {
    if tui_available; then
      select_source=$(tui_menu "apt 镜像" "请选择 apt 源，默认北外" \
        "1" "北外 (默认)" \
        "2" "清华" \
        "3" "阿里" \
        "4" "华为" \
        "5" "中科大" \
        "6" "163" \
        "7" "不修改") || select_source="1"
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
      return 0
    fi
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
    pathName=""
    if [[ -e "${LLBOT_HOME}/qq_data.json" ]]; then
      pathName=$(jq -r '.bot_qq' ${LLBOT_HOME}/qq_data.json)
    fi
    token=""
    if [[ -e "${LLBOT_HOME}/bin/llbot/data/webui_token.txt" ]]; then
      token=$(head -n 1 ${LLBOT_HOME}/bin/llbot/data/webui_token.txt)
    fi
    port="${LLBOT_WEBUI_PORT}"
    local_ipv4=$(ip addr show | grep -v docker | grep -v br-.* | grep -v "host lo" | grep 'inet ' | awk '{print $2}' | head -n 1 | cut -d'/' -f1) || local_ipv4=$(ifconfig | grep -v docker | grep -v br-.* | grep -v "host lo" | grep 'inet ' | awk '{print $2}' | head -n 1 | cut -d'/' -f1)
    echo -e "${Info} 当前协议端：LLBot（LuckyLilliaBot / 原 LLOneBot）"
    echo -e "${Info} 当前bot QQ：${Green_font_prefix}${pathName}${Font_color_suffix}"
    echo -e "${Info} WebUI 密码文件：${LLBOT_HOME}/bin/llbot/data/webui_token.txt"
    echo -e "${Info} WebUI 密码：${Green_font_prefix}${token}${Font_color_suffix}"
    echo -e "${Info} WebUI 本机：http://127.0.0.1:${port}"
    echo -e "${Info} WebUI 内网：http://${local_ipv4}:${port}"
    echo -e "${Info} 反向 WS：ws://127.0.0.1:${Port:-${DEFAULT_PORT}}/onebot/v11/ws"
    echo "请按任意键返回..."
    read -n 1 -s
    menu_napcat
}

Set_dependency() {
    cd ${WORK_DIR}/zhenxun_bot || exit
    Set_pip_Mirror
    echo -e "${Info} 安装 uv（官方推荐，替代 poetry/pip）..."
    ${python_v} -m pip install uv --break-system-packages || pip install uv --break-system-packages || pip3 install uv
    echo -e "${Info} 同步真寻依赖：uv sync"
    for (( i=1; i<=5; i++ )); do
      uv sync && break
      echo -e "${Info} 第${i}次 uv sync 失败，正在重试..."
    done
    apt --fix-broken install -y || true
    uv run playwright install-deps chromium || true
    uv run playwright install chromium || true
}

Uninstall_postgresql() {
    if tui_available; then
      if tui_yesno "卸载 PostgreSQL" "是否卸载 postgresql 数据库？此操作不可逆"; then
        uninstpsql_check="y"
      else
        uninstpsql_check="n"
      fi
    else
      echo -e "${Tip} 是否卸载 postgresql 数据库 ？(此操作不可逆)"
      read -erp "请选择 [y/n], 默认为 n:" uninstpsql_check
    fi
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
      [[ -z "$(psql_dir)" ]] && echo -e "${Info} postgresql 卸载完成" || echo -e "${Error} postgresql 卸载失败！"
    else
      echo -e "${Info} 操作已取消..." && menu_postgresql
    fi

}

Uninstall_napcat() {
    if tui_available; then
      if tui_yesno "卸载 LLBot" "是否卸载 LLBot？此操作不可逆"; then
        uninstnapcat_check="y"
      else
        uninstnapcat_check="n"
      fi
    else
      echo -e "${Tip} 是否卸载 LLBot ？(此操作不可逆)"
      read -erp "请选择 [y/n], 默认为 n:" uninstnapcat_check
    fi
    [[ -z "${uninstnapcat_check}" ]] && uninstnapcat_check='n'
    if [[ ${uninstnapcat_check} == 'y' ]]; then
      check_pid_napcat
      [[ -z ${PID} ]] || kill -9 ${PID}
      echo -e "${Info} 开始卸载 LLBot..."
      rm -rf ${LLBOT_HOME} || echo -e "${Error} LLBot 卸载失败！"
      echo -e "${Info} LLBot 卸载完成"
    else
      echo -e "${Info} 操作已取消..." && menu_napcat
    fi

}

Uninstall_zhenxun() {
    if tui_available; then
      if tui_yesno "卸载真寻" "是否卸载 zhenxun_bot？此操作不可逆"; then
        uninstllzhenxun_check="y"
      else
        uninstllzhenxun_check="n"
      fi
    else
      echo -e "${Tip} 是否卸载 zhenxun_bot ？(此操作不可逆)"
      read -erp "请选择 [y/n], 默认为 n:" uninstllzhenxun_check
    fi
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
    if tui_available; then
      if tui_yesno "完全卸载" "是否完全卸载 zhenxun_bot 和 LLBot？此操作不可逆"; then
        uninstall_check="y"
      else
        uninstall_check="n"
      fi
    else
      echo -e "${Tip} 是否完全卸载 zhenxun_bot 和 LLBot？(此操作不可逆)"
      read -erp "请选择 [y/n], 默认为 n:" uninstall_check
    fi
    [[ -z "${uninstall_check}" ]] && uninstall_check='n'
    if [[ ${uninstall_check} == 'y' ]]; then
      cd ${WORK_DIR} || exit
      check_pid_zhenxun
      [[ -z ${PID} ]] || kill -9 "${PID}"
      echo -e "${Info} 开始卸载 zhenxun_bot..."
      rm -rf zhenxun_bot || echo -e "${Error} zhenxun_bot 卸载失败！"
      check_pid_napcat
      [[ -z ${PID} ]] || kill -9 ${PID}
      echo -e "${Info} 开始卸载 LLBot..."
      rm -rf ${LLBOT_HOME} || echo -e "${Error} LLBot 卸载失败！"
      echo -e "${Info} 感谢使用真寻bot，期待与你的下次相会！"
    else
      echo -e "${Info} 操作已取消..." && menu_zhenxun
    fi
}

Install_zhenxun_bot() {
    check_root
    [[ -e "${WORK_DIR}/zhenxun_bot/pyproject.toml" ]] && echo -e "${Error} 检测到 zhenxun_bot 已安装 !" && exit 1
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
    echo -e "${Info} 请打开 http://127.0.0.1:${LLBOT_WEBUI_PORT} 或查看 LLBot 日志扫码登录"
    View_napcat_log
    
}

Install_postgresql() {
    databaseuser="postgres"
    databasename="zhenxun_bot"
    password="zhenxun_bot"
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

llbot_status_text() {
  if [[ -x "${LLBOT_HOME}/llbot" ]] || [[ -x "${LLBOT_HOME}/start.sh" ]]; then
    check_pid_napcat
    if [[ -n "${PID}" ]]; then
      echo "LLBot 已安装并已启动"
    else
      echo "LLBot 已安装但未启动"
    fi
  else
    echo "LLBot 未安装"
  fi
}

zhenxun_status_text() {
  if [[ -e "${WORK_DIR}/zhenxun_bot/pyproject.toml" ]]; then
    check_pid_zhenxun
    if [[ -n "${PID}" ]]; then
      echo "zhenxun_bot 已安装并已启动"
    else
      echo "zhenxun_bot 已安装但未启动"
    fi
  else
    echo "zhenxun_bot 未安装"
  fi
}

postgres_status_text() {
  psql_dir=$(command -v psql || true)
  if [[ -n "$psql_dir" ]]; then
    check_pid_postgres
    if [[ -n "${PID}" ]]; then
      echo "postgres 已安装并已启动"
    else
      echo "postgres 已安装但未启动"
    fi
  else
    echo "postgres 未安装"
  fi
}

menu_napcat() {
  local status_line pathName=""
  status_line=$(llbot_status_text)
  if [[ -e "${LLBOT_HOME}/qq_data.json" ]]; then
    pathName=$(jq -r '.bot_qq' ${LLBOT_HOME}/qq_data.json 2>/dev/null)
  fi
  if tui_available; then
    num=$(tui_menu "LLBot 管理  v${sh_ver}" "${status_line}\nBot QQ: ${pathName:-未登录}\nLinux x64 / arm64；tmoe/proot 用 Debian12 或 Ubuntu22.04" \
      "0" "安装/升级 LLBot" \
      "1" "卸载 LLBot" \
      "2" "启动 LLBot" \
      "3" "停止 LLBot" \
      "4" "重启 LLBot" \
      "5" "更换 bot QQ 账号(待实现)" \
      "6" "修改 LLBot 配置文件" \
      "7" "查看 LLBot 日志" \
      "8" "查看 webui 信息" \
      "9" "切换为 系统工具 菜单" \
      "10" "切换为 postgresql 菜单" \
      "11" "切换为 zhenxun_bot 菜单") || { echo -e "${Info} 已取消"; return 0; }
  else
    echo && echo -e "  zhenxun_bot 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Sakura | github.com/AkashiCoin --
 ${Green_font_prefix} 0.${Font_color_suffix} 安装/升级 LLBot
 ${Green_font_prefix} 1.${Font_color_suffix} 卸载 LLBot
————————————
 ${Green_font_prefix} 2.${Font_color_suffix} 启动 LLBot
 ${Green_font_prefix} 3.${Font_color_suffix} 停止 LLBot
 ${Green_font_prefix} 4.${Font_color_suffix} 重启 LLBot
————————————
 ${Green_font_prefix} 5.${Font_color_suffix} 更换 bot QQ 账号(待实现)
 ${Green_font_prefix} 6.${Font_color_suffix} 修改 LLBot 配置文件
 ${Green_font_prefix} 7.${Font_color_suffix} 查看 LLBot 日志
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 webui 信息
  ————————————
 ${Green_font_prefix} 9.${Font_color_suffix} 切换为 termux 菜单
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 postgresql 菜单
 ${Green_font_prefix}11.${Font_color_suffix} 切换为 zhenxun_bot 菜单" && echo
    echo -e " 当前状态: ${status_line}"
    echo
    read -erp " 请输入数字 [0-10]:" num
  fi
  case "$num" in
  0)
    update_napcat
    ;;
  1)
    Uninstall_napcat && menu_napcat
    ;;
  2)
    Start_napcat && menu_napcat
    ;;
  3)
    Stop_napcat && menu_napcat
    ;;
  4)
    Restart_napcat && menu_napcat
    ;;
  5)
    menu_napcat
    ;;
  6)
    Set_config_napcat && menu_napcat
    ;;
  7)
    View_napcat_log && menu_napcat
    ;;  
  8)
    View_napcat_webui_info && menu_napcat
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
  local status_line
  status_line=$(postgres_status_text)
  if tui_available; then
    num=$(tui_menu "PostgreSQL 管理  v${sh_ver}" "${status_line}\n默认 Sqlite；仅在需要时安装 PostgreSQL" \
      "0" "启动 postgresql 数据库" \
      "1" "重启 postgresql 数据库" \
      "2" "停止 postgresql 数据库" \
      "3" "安装 postgresql 数据库" \
      "4" "卸载 postgresql 数据库" \
      "5" "创建新数据库(待实现)" \
      "6" "修改数据库密码(待实现)" \
      "7" "查看数据库信息" \
      "8" "导出/导入数据库备份(待实现)" \
      "9" "切换为 系统工具 菜单" \
      "10" "切换为 LLBot 菜单" \
      "11" "切换为 zhenxun_bot 菜单") || { echo -e "${Info} 已取消"; return 0; }
  else
    echo && echo -e "  zhenxun_bot 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
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
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 LLBot 菜单
 ${Green_font_prefix}11.${Font_color_suffix} 切换为 zhenxun_bot 菜单" && echo
    echo -e " 当前状态: ${status_line}"
    echo
    read -erp " 请输入数字 [0-10]:" num
  fi
  case "$num" in
  0)
    Start_postgresql && menu_postgresql
    ;;
  1)
    Restart_postgresql && menu_postgresql
    ;;
  2)
    Stop_postgresql && menu_postgresql 
    ;;
  3)
    Install_postgresql && menu_postgresql
    ;;
  4)
    Uninstall_postgresql && menu_postgresql
    ;;
  5)
    menu_postgresql 
    ;;
  6)
    Set_dns && menu_postgresql
    ;;
  7)
    View_postgresql_info && menu_postgresql
    ;;  
  8)
    menu_postgresql 
    ;;
  9)
    menu_termux
    ;;
  10)
    menu_napcat
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
  local status_line
  status_line=$(postgres_status_text)
  if tui_available; then
    num=$(tui_menu "系统工具  v${sh_ver}" "${status_line}\nDNS / apt / pip / 端口 / 依赖" \
      "0" "修改 dns" \
      "1" "修改 apt 源" \
      "2" "修改 pip 源" \
      "3" "设置 zhenxun LLBot 端口" \
      "4" "自动检测 zhenxun_bot 依赖" \
      "5" "切换为 postgresql 菜单" \
      "6" "切换为 LLBot 菜单" \
      "7" "切换为 zhenxun_bot 菜单") || { echo -e "${Info} 已取消"; return 0; }
  else
    echo && echo -e "  zhenxun_bot 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Sakura | github.com/AkashiCoin --
 ${Green_font_prefix} 0.${Font_color_suffix} 修改 dns
 ${Green_font_prefix} 1.${Font_color_suffix} 修改 apt 源
 ${Green_font_prefix} 2.${Font_color_suffix} 修改 pip 源
  ————————————
 ${Green_font_prefix} 3.${Font_color_suffix} 设置 zhenxun LLBot 端口
 ${Green_font_prefix} 4.${Font_color_suffix} 自动检测 zhenxun_bot 依赖
  ————————————
 ${Green_font_prefix} 5.${Font_color_suffix} 切换为 postgresql 菜单
 ${Green_font_prefix} 6.${Font_color_suffix} 切换为 LLBot 菜单
 ${Green_font_prefix} 7.${Font_color_suffix} 切换为 zhenxun_bot 菜单" && echo
    echo -e " 当前状态: ${status_line}"
    echo
    read -erp " 请输入数字 [0-10]:" num
  fi
  case "$num" in
  0)
    Set_dns && menu_termux
    ;;
  1)
    Set_apt_source  && menu_termux
    ;;
  2)
    Set_pip_Mirror  && menu_termux
    ;;
  3)
    Set_Port  && menu_termux
    ;;
  4)
    check_module  && menu_termux
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
  local status_line
  status_line=$(zhenxun_status_text)
  if tui_available; then
    num=$(tui_menu "真寻 Bot 管理  v${sh_ver}" "${status_line}\nuv + LLBot CLI  linux-x64/arm64  默认 Sqlite :8080" \
      "0" "升级脚本" \
      "1" "安装 zhenxun_bot + LLBot" \
      "2" "启动 zhenxun_bot" \
      "3" "停止 zhenxun_bot" \
      "4" "重启 zhenxun_bot" \
      "5" "设置 管理员账号" \
      "6" "修改 zhenxun_bot 配置文件" \
      "7" "查看 zhenxun_bot 日志" \
      "8" "卸载 zhenxun_bot + LLBot" \
      "9" "切换为 系统工具 菜单" \
      "10" "切换为 LLBot 菜单" \
      "11" "切换为 postgresql 菜单") || { echo -e "${Info} 已取消"; return 0; }
  else
    echo && echo -e "  zhenxun_bot 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Sakura | github.com/AkashiCoin --
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 zhenxun_bot + LLBot
————————————
 ${Green_font_prefix} 2.${Font_color_suffix} 启动 zhenxun_bot
 ${Green_font_prefix} 3.${Font_color_suffix} 停止 zhenxun_bot
 ${Green_font_prefix} 4.${Font_color_suffix} 重启 zhenxun_bot
————————————
 ${Green_font_prefix} 5.${Font_color_suffix} 设置 管理员账号
 ${Green_font_prefix} 6.${Font_color_suffix} 修改 zhenxun_bot 配置文件
 ${Green_font_prefix} 7.${Font_color_suffix} 查看 zhenxun_bot 日志
————————————
 ${Green_font_prefix} 8.${Font_color_suffix} 卸载 zhenxun_bot + LLBot
 ${Green_font_prefix} 9.${Font_color_suffix} 切换为 termux 菜单
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 LLBot 菜单
 ${Green_font_prefix}11.${Font_color_suffix} 切换为 postgresql 菜单" && echo
    echo -e " 当前状态: ${status_line}"
    echo
    read -erp " 请输入数字 [0-10]:" num
  fi
  case "$num" in
  0)
    Update_Shell && menu_zhenxun
    ;;
  1)
    Install_zhenxun_bot
    ;;
  2)
    Start_zhenxun_bot && menu_zhenxun
    ;;
  3)
    Stop_zhenxun_bot && menu_zhenxun
    ;;
  4)
    Restart_zhenxun_bot && menu_zhenxun
    ;;
  5)
    Set_config_admin && menu_zhenxun
    ;;
  6)
    Set_config_zhenxun && menu_zhenxun
    ;;
  7)
    View_zhenxun_log && menu_zhenxun
    ;;
  8)
    Uninstall_All && menu_zhenxun
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

main() {
  install_tui_pkg
  ensure_tui
  menu_zhenxun
}

if [[ "${ZX_SKIP_MENU:-}" != "1" ]]; then
  main
fi

