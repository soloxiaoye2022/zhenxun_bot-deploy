import json
import re
from typing import Iterable, Optional


PORT_MIN = 1024
PORT_MAX = 49151
DEFAULT_PORT = 8080
DEFAULT_DNS = "8.8.8.8"
WORK_DIR = "/root"
NAPCAT_HOME = "/root/LLBot"
NAPCAT_DIR = "/root/LLBot"
LLBOT_HOME = "/root/LLBot"
ZX_DIR = "/root/zhenxun_bot/"
SSH_PORT = "8022"
SHELL_VERSION = "3.2.0"
DEFAULT_DB_USER = "postgres"
DEFAULT_DB_NAME = "zhenxun_bot"
DEFAULT_DB_PASSWORD = "zhenxun_bot"
DEFAULT_DB_PORT = 5432
DEFAULT_SQLITE_URL = "sqlite:data/db/zhenxun.db"
DEFAULT_MUSIC_SIGN_URL = "https://llob.linyuchen.net/sign/music"
ZHENXUN_REPO = "https://github.com/zhenxun-org/zhenxun_bot.git"
LLBOT_REPO = "https://github.com/LuckyLilliaDev/LuckyLilliaBot"
LLBOT_API_URL = "https://api.github.com/repos/LuckyLilliaDev/LuckyLilliaBot/releases/latest"
LLBOT_CLI_X64 = "LuckyLillia-CLI-linux-x64.zip"
LLBOT_CLI_ARM64 = "LuckyLillia-CLI-linux-arm64.zip"
NAPCAT_INSTALLER_URL = "https://github.com/LuckyLilliaDev/LuckyLilliaBot/releases/latest/download/"

PIP_MIRRORS = {
    "1": "https://pypi.tuna.tsinghua.edu.cn/simple/",
    "2": "https://mirrors.cloud.tencent.com/pypi/simple/",
    "3": "http://mirrors.aliyun.com/pypi/simple/",
    "4": "https://pypi.mirrors.ustc.edu.cn/simple/",
    "5": "https://mirrors.bfsu.edu.cn/pypi/web/simple/",
}

APT_MIRRORS = {
    "1": "https://mirrors.bfsu.edu.cn/",
    "2": "https://mirrors.tuna.tsinghua.edu.cn/",
    "3": "http://mirrors.aliyun.com/",
    "4": "https://repo.huaweicloud.com/",
    "5": "https://mirrors.ustc.edu.cn/",
    "6": "http://mirrors.163.com/",
}

ARCH_MAP = {
    "x86_64": "amd64",
    "aarch64": "arm64",
    "v8l": "arm64",
}

LLBOT_ASSET_MAP = {
    "amd64": LLBOT_CLI_X64,
    "arm64": LLBOT_CLI_ARM64,
}


def llbot_asset_name(arch: str) -> str:
    if arch not in LLBOT_ASSET_MAP:
        raise ValueError(f"unsupported arch: {arch}")
    return LLBOT_ASSET_MAP[arch]

APT_SOURCE_PATTERN = (
    r"https://.*.c../|http://.*.c../|https://.*.c./|http://.*.c./|"
    r"https://.*.org/|http://.*.org/|https://.*.net/|http://.*.net/"
)


def is_valid_qq(value: Optional[str]) -> bool:
    if value is None:
        return False
    return bool(re.fullmatch(r"[0-9]+", value))


def is_bot_qq_allowed(bot_qq: str, admin_qq: str) -> bool:
    return is_valid_qq(bot_qq) and is_valid_qq(admin_qq) and bot_qq != admin_qq


def is_valid_port(port) -> bool:
    try:
        value = int(str(port).strip())
    except (TypeError, ValueError):
        return False
    return PORT_MIN <= value <= PORT_MAX


def map_arch(get_arch: str) -> str:
    if get_arch not in ARCH_MAP:
        raise ValueError(f"unsupported arch: {get_arch}")
    return ARCH_MAP[get_arch]


def is_supported_os(release: str, version_id: Optional[str]) -> bool:
    if release not in ("debian", "ubuntu", "centos", "archlinux"):
        return False
    if not version_id:
        return True
    major = version_id.split(".")[0]
    if not major.isdigit():
        return True
    ver = int(major)
    if release == "debian":
        return ver >= 11
    if release == "ubuntu":
        return ver >= 20
    return True


def parse_semver(version: str) -> tuple:
    cleaned = version[1:] if version.startswith("v") else version
    parts = cleaned.split(".")
    if len(parts) != 3 or not all(part.isdigit() for part in parts):
        raise ValueError(f"invalid semver: {version}")
    return tuple(int(part) for part in parts)


def needs_napcat_update(current: str, latest_tag: str) -> bool:
    i1, i2, i3 = parse_semver(current)
    t1, t2, t3 = parse_semver(latest_tag)
    return i1 < t1 or (i1 == t1 and i2 < t2) or (i1 == t1 and i2 == t2 and i3 < t3)


def resolve_pip_mirror(mirror_num: Optional[str]) -> Optional[str]:
    if mirror_num is None or mirror_num == "":
        return PIP_MIRRORS["5"]
    if mirror_num in PIP_MIRRORS:
        return PIP_MIRRORS[mirror_num]
    if mirror_num == "6":
        return None
    raise ValueError("invalid pip mirror option")


def resolve_apt_source(select_source: Optional[str]) -> Optional[str]:
    if select_source is None or select_source == "":
        return APT_MIRRORS["1"]
    if select_source in APT_MIRRORS:
        return APT_MIRRORS[select_source]
    if select_source == "7":
        return None
    raise ValueError("invalid apt source option")


def rewrite_apt_source_line(line: str, mirror: str) -> str:
    return re.sub(APT_SOURCE_PATTERN, mirror, line)


def extract_missing_modules(log_text: str) -> list:
    names = []
    for line in log_text.splitlines():
        if "No module named" not in line:
            continue
        parts = line.split("'")
        if len(parts) >= 2:
            name = parts[1].replace('"', "").replace(",", "").replace(" ", "")
            names.append(name)
    return names


def filter_install_modules(names: Iterable[str]) -> list:
    unique = sorted(set(names))
    return [name for name in unique if name and not name.startswith("enchant")]


def build_postgres_url(
    user: str = DEFAULT_DB_USER,
    password: str = DEFAULT_DB_PASSWORD,
    host: str = "127.0.0.1",
    port: int = DEFAULT_DB_PORT,
    database: str = DEFAULT_DB_NAME,
) -> str:
    return f"postgres://{user}:{password}@{host}:{port}/{database}"


def build_sqlite_url(path: str = "data/db/zhenxun.db") -> str:
    return f"sqlite:{path}"


def build_qq_data(bot_qq: str) -> dict:
    return {"bot_qq": bot_qq, "other_QQ": []}


def build_onebot11_config(bot_qq: str, port: int, music_sign_url: str = DEFAULT_MUSIC_SIGN_URL) -> dict:
    return {
        "ob11": {
            "enable": True,
            "connect": [
                {
                    "type": "ws-reverse",
                    "enable": True,
                    "url": f"ws://127.0.0.1:{port}/onebot/v11/ws",
                    "token": "",
                    "reportSelfMessage": True,
                    "reportOfflineMessage": False,
                    "messageFormat": "array",
                    "debug": True,
                    "heartInterval": 30000,
                }
            ],
        },
        "webui": {
            "enable": True,
            "host": "127.0.0.1",
            "port": 3080,
        },
    }


def dumps_onebot11_config(bot_qq: str, port: int, music_sign_url: str = DEFAULT_MUSIC_SIGN_URL) -> str:
    return json.dumps(build_onebot11_config(bot_qq, port, music_sign_url), ensure_ascii=False, indent=2)


def detect_release(issue_text: str = "", proc_version: str = "", redhat_release: bool = False) -> str:
    if redhat_release:
        return "centos"
    blob = f"{issue_text}\n{proc_version}".lower()
    if re.search(r"debian", blob):
        return "debian"
    if re.search(r"ubuntu", blob):
        return "ubuntu"
    if re.search(r"centos|red hat|redhat", blob):
        return "centos"
    if re.search(r"arch|manjaro", blob):
        return "archlinux"
    raise ValueError("unsupported linux distribution")


def package_format(release: str) -> Optional[str]:
    if release in ("debian", "ubuntu"):
        return "deb"
    if release == "centos":
        return "rpm"
    if release == "archlinux":
        return None
    raise ValueError(f"unknown release: {release}")


def choose_python(available: Iterable[str]) -> Optional[str]:
    order = ["python3.12", "python3.11", "python3.10"]
    available_set = set(available)
    for name in order:
        if name in available_set:
            return name
    return None


def install_duration(start_ts: int, end_ts: int) -> int:
    return end_ts - start_ts


def parse_proxy_array(install_text: str) -> list:
    match = re.search(r'proxy_arr=\((.*?)\)', install_text, re.S)
    if not match:
        raise ValueError("proxy_arr not found")
    return re.findall(r'"([^"]+)"', match.group(1))


def parse_assigned_string(install_text: str, name: str) -> str:
    match = re.search(rf'^{re.escape(name)}="([^"]*)"', install_text, re.M)
    if not match:
        raise ValueError(f"{name} not found")
    return match.group(1)


def list_shell_functions(install_text: str) -> list:
    return re.findall(r"^([A-Za-z_][A-Za-z0-9_]*)\(\)", install_text, re.M)


def parse_menu_cases(install_text: str, menu_name: str) -> list:
    pattern = rf"{re.escape(menu_name)}\(\) \{{.*?case \"\$num\" in(.*?)esac"
    match = re.search(pattern, install_text, re.S)
    if not match:
        raise ValueError(f"menu {menu_name} not found")
    return re.findall(r"^\s+(\d+)\)", match.group(1), re.M)
