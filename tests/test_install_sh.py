import re

from tests.deploy_logic import (
    DEFAULT_DNS,
    DEFAULT_MUSIC_SIGN_URL,
    DEFAULT_PORT,
    DEFAULT_SQLITE_URL,
    NAPCAT_DIR,
    NAPCAT_HOME,
    NAPCAT_INSTALLER_URL,
    PORT_MAX,
    PORT_MIN,
    SHELL_VERSION,
    SSH_PORT,
    WORK_DIR,
    ZHENXUN_REPO,
    ZX_DIR,
    list_shell_functions,
    parse_assigned_string,
    parse_menu_cases,
    parse_proxy_array,
)


REQUIRED_FUNCTIONS = [
    "check_root",
    "check_sys",
    "check_arch",
    "check_installed_zhenxun_status",
    "check_installed_napcat_status",
    "Set_pip_Mirror",
    "Set_ghproxy",
    "network_test",
    "Installation_dependency",
    "Download_zhenxun_bot",
    "Install_linuxqq",
    "get_napcat_version",
    "Download_napcat",
    "Install_napcat",
    "llbot_asset_name",
    "write_llbot_onebot_config",
    "Set_config_admin",
    "Set_config_bot",
    "Set_Port",
    "Set_postgresql_bind",
    "Start_zhenxun_bot",
    "Stop_zhenxun_bot",
    "Start_napcat",
    "Stop_napcat",
    "Install_zhenxun_bot",
    "Install_postgresql",
    "create_database",
    "Update_Shell",
    "menu_napcat",
    "menu_postgresql",
    "menu_termux",
    "menu_zhenxun",
    "ensure_tui",
    "tui_available",
    "tui_menu",
    "tui_yesno",
    "tui_input",
    "install_tui_pkg",
    "check_supported_os",
    "main",
    "save_proxy_config",
    "measure_proxy",
    "select_ghproxy_manual",
]


class TestInstallConstants:
    def test_shebang(self, install_sh):
        assert install_sh.startswith("#!/usr/bin/env bash")

    def test_work_dir_and_zx_dir(self, install_sh):
        assert parse_assigned_string(install_sh, "WORK_DIR") == WORK_DIR
        assert 'ZX_DIR="${WORK_DIR}/zhenxun_bot/"' in install_sh
        assert ZX_DIR == "/root/zhenxun_bot/"

    def test_napcat_dir(self, install_sh):
        assert parse_assigned_string(install_sh, "napcat_DIR") == NAPCAT_DIR
        assert parse_assigned_string(install_sh, "NAPCAT_HOME") == NAPCAT_HOME

    def test_port_range(self, install_sh):
        assert parse_assigned_string(install_sh, "mix") == str(PORT_MIN)
        assert parse_assigned_string(install_sh, "max") == str(PORT_MAX)

    def test_dns_and_ssh_and_version(self, install_sh):
        assert parse_assigned_string(install_sh, "dns") == DEFAULT_DNS
        assert parse_assigned_string(install_sh, "ssh_port") == SSH_PORT
        assert parse_assigned_string(install_sh, "sh_ver") == SHELL_VERSION

    def test_music_sign_url(self, install_sh):
        assert DEFAULT_MUSIC_SIGN_URL in install_sh

    def test_repo_urls(self, install_sh):
        assert ZHENXUN_REPO in install_sh
        assert "https://github.com/zhenxun-org/zhenxun_bot_plugins" in install_sh
        assert "https://github.com/LuckyLilliaDev/LuckyLilliaBot" in install_sh
        assert "LuckyLillia-CLI-linux-x64.zip" in install_sh
        assert "LuckyLillia-CLI-linux-arm64.zip" in install_sh
        assert NAPCAT_INSTALLER_URL in install_sh
        assert "uv sync" in install_sh
        assert "uv run zx" in install_sh


class TestProxyArray:
    def test_proxy_hosts(self, install_sh):
        proxies = parse_proxy_array(install_sh)
        assert proxies == [
            "https://gh-proxy.org/",
            "https://ghproxy.cfd/",
            "https://gitproxy.click/",
            "https://gh-proxy.net/",
            "https://ghproxy.net/",
            "https://ghfast.top/",
        ]
        assert all(item.startswith("https://") and item.endswith("/") for item in proxies)

    def test_dead_mirrors_removed(self, install_sh):
        proxies = parse_proxy_array(install_sh)
        for dead in ("https://github.moeyy.xyz/", "https://mirror.ghproxy.com/"):
            assert dead not in proxies

    def test_proxy_persistence(self, install_sh):
        assert "PROXY_CACHE" in install_sh
        assert "/root/.zhenxun_deploy" in install_sh
        assert "save_proxy_config" in install_sh
        assert "measure_proxy" in install_sh
        assert "select_ghproxy_manual" in install_sh

    def test_auto_selects_fastest(self, install_sh):
        block = re.search(r"^network_test\(\) \{.*?\n\}", install_sh, re.S | re.M).group(0)
        assert "best_time" in block
        assert "已选择最快镜像" in block

    def test_proxy_modes_available(self, install_sh):
        block = re.search(r"^Set_ghproxy\(\) \{.*?\n\}", install_sh, re.S | re.M).group(0)
        assert "自动测速" in block
        assert "手动选择" in block
        assert "不使用镜像" in block


class TestShellFunctions:
    def test_required_functions_exist(self, install_sh):
        names = set(list_shell_functions(install_sh))
        missing = set(REQUIRED_FUNCTIONS) - names
        assert missing == set()

    def test_function_count(self, install_sh):
        names = list_shell_functions(install_sh)
        unique = [n for n in names if n != "Set_config_zhenxun"]
        assert len(names) >= 70
        assert len(unique) == len(set(unique))
        assert names.count("Set_config_zhenxun") == 1

    def test_skip_menu_guard(self, install_sh):
        assert 'ZX_SKIP_MENU' in install_sh
        assert 'if [[ "${ZX_SKIP_MENU:-}" != "1" ]]; then' in install_sh


class TestValidationSnippets:
    def test_admin_qq_regex(self, install_sh):
        assert r'[[ ! "$admin_qq" =~ ^[0-9]+$ ]]' in install_sh

    def test_bot_qq_regex(self, install_sh):
        assert r'[[ ! "$bot_qq" =~ ^[0-9]+$ ]]' in install_sh

    def test_bot_qq_cannot_equal_admin(self, install_sh):
        assert '[ "$bot_qq" = "$admin_qq" ]' in install_sh

    def test_port_range_check(self, install_sh):
        assert "[ \"${Port}\" -ge ${mix} -a \"${Port}\" -le ${max} ]" in install_sh

    def test_root_check_exits(self, install_sh):
        assert "[[ $EUID != 0 ]]" in install_sh
        assert "exit 1" in install_sh

    def test_arch_mapping_present(self, install_sh):
        assert '[[ ${get_arch} == "x86_64" ]]' in install_sh
        assert 'arch="amd64"' in install_sh
        assert 'arch="arm64"' in install_sh


class TestPythonSelection:
    def test_python_priority_order(self, install_sh):
        order = [
            "python3.12",
            "python3.11",
            "python3.10",
        ]
        positions = [install_sh.find(f"which {name}") for name in order]
        assert all(pos != -1 for pos in positions)
        assert positions == sorted(positions)


class TestDatabaseDefaults:
    def test_create_database_credentials(self, install_sh):
        assert 'databaseuser="postgres"' in install_sh
        assert 'databasename="zhenxun_bot"' in install_sh
        assert 'password="zhenxun_bot"' in install_sh

    def test_sqlite_is_default(self, install_sh):
        assert DEFAULT_SQLITE_URL in install_sh
        assert "Set_sqlite_bind" in install_sh
        assert parse_assigned_string(install_sh, "DEFAULT_PORT") == str(DEFAULT_PORT)

    def test_db_url_rewrite(self, install_sh):
        assert "postgres://postgres:zhenxun_bot@127.0.0.1:5432/zhenxun_bot" in install_sh


class TestMenus:
    def test_menu_zhenxun_cases(self, install_sh):
        cases = parse_menu_cases(install_sh, "menu_zhenxun")
        assert cases == [str(i) for i in range(12)]

    def test_menu_napcat_cases(self, install_sh):
        cases = parse_menu_cases(install_sh, "menu_napcat")
        assert "0" in cases
        assert "11" in cases

    def test_menu_postgresql_cases(self, install_sh):
        cases = parse_menu_cases(install_sh, "menu_postgresql")
        assert cases[0] == "0"
        assert "11" in cases

    def test_menu_termux_cases(self, install_sh):
        cases = parse_menu_cases(install_sh, "menu_termux")
        assert cases == [str(i) for i in range(8)]

    def test_menu_hint_ranges_match_cases(self, install_sh):
        for menu, top in (
            ("menu_napcat", 11),
            ("menu_postgresql", 11),
            ("menu_termux", 7),
            ("menu_zhenxun", 11),
        ):
            block = re.search(rf"^{menu}\(\) \{{.*?\n\}}", install_sh, re.S | re.M).group(0)
            cases = parse_menu_cases(install_sh, menu)
            assert cases == [str(i) for i in range(top + 1)], menu
            assert f"[0-{top}]" in block, menu
            assert "[0-10]" not in block or top == 10, menu

    def test_menu_labels_consistent(self, install_sh):
        assert "切换为 termux 菜单" not in install_sh
        for menu in ("menu_napcat", "menu_postgresql", "menu_termux", "menu_zhenxun"):
            block = re.search(rf"^{menu}\(\) \{{.*?\n\}}", install_sh, re.S | re.M).group(0)
            assert "系统工具" in block or "termux" in block, menu

    def test_default_entry_is_menu_zhenxun(self, install_sh):
        assert "menu_zhenxun" in install_sh
        assert "main() {" in install_sh
        assert 'if [[ "${ZX_SKIP_MENU:-}" != "1" ]]; then' in install_sh
        assert install_sh.rstrip().endswith("fi")

    def test_tui_uses_whiptail(self, install_sh):
        assert "whiptail" in install_sh
        assert 'TUI_BIN="whiptail"' in install_sh
        assert "--menu" in install_sh
        assert "--yesno" in install_sh
        assert "--inputbox" in install_sh
        assert "ZX_NO_TUI" in install_sh

    def test_supported_os_gate(self, install_sh):
        assert "仅支持 Debian 11/12+" in install_sh
        assert "仅支持 Ubuntu 20/22/24" in install_sh
        assert "Python-3.11.2.tgz" not in install_sh


class TestPipAndAptMirrors:
    def test_pip_mirror_urls(self, install_sh):
        assert "https://pypi.tuna.tsinghua.edu.cn/simple/" in install_sh
        assert "https://mirrors.cloud.tencent.com/pypi/simple/" in install_sh
        assert "http://mirrors.aliyun.com/pypi/simple/" in install_sh
        assert "https://pypi.mirrors.ustc.edu.cn/simple/" in install_sh
        assert "https://mirrors.bfsu.edu.cn/pypi/web/simple/" in install_sh

    def test_apt_mirror_urls(self, install_sh):
        assert "https://mirrors.bfsu.edu.cn/" in install_sh
        assert "https://mirrors.tuna.tsinghua.edu.cn/" in install_sh
        assert "http://mirrors.aliyun.com/" in install_sh
        assert "https://repo.huaweicloud.com/" in install_sh
        assert "https://mirrors.ustc.edu.cn/" in install_sh
        assert "http://mirrors.163.com/" in install_sh


class TestOnebotConfigTemplate:
    def test_websocket_url_template(self, install_sh):
        assert "ws://127.0.0.1:${Port}/onebot/v11/ws" in install_sh

    def test_onebot_filename_uses_bot_qq(self, install_sh):
        assert "config_${bot_qq}.json" in install_sh

    def test_reverse_ws_enabled(self, install_sh):
        assert '"enable": true' in install_sh
        assert '"type": "ws-reverse"' in install_sh

    def test_official_napcat_installer_flags(self, install_sh):
        assert "LuckyLillia-CLI-linux-x64.zip" in install_sh
        assert "LuckyLillia-CLI-linux-arm64.zip" in install_sh
        assert "--headless --host=127.0.0.1 --port=13000" in install_sh
        assert "ZX_SKIP_MENU" in install_sh


class TestRetryLoops:
    def test_download_retries_five_times(self, install_sh):
        matches = re.findall(r"for \(\( i=1; i<=5; i\+\+ \)\); do", install_sh)
        assert len(matches) >= 2


class TestDependencyAudit:
    def test_no_unused_xvfb(self, install_sh):
        block = re.search(r"^Installation_dependency\(\) \{.*?\n\}", install_sh, re.S | re.M).group(0)
        assert " xvfb" not in block
        assert "Xvfb" not in block

    def test_no_duplicate_python_install_calls(self, install_sh):
        block = re.search(r"^Installation_dependency\(\) \{.*?\n\}", install_sh, re.S | re.M).group(0)
        assert block.count("apt-get install -y python3 python3-pip") == 1

    def test_libasound_probe(self, install_sh):
        assert "apt-cache show libasound2t64" in install_sh
        assert "libasound2t64" in install_sh
        assert "apt-get install -y libasound2 ||" in install_sh

    def test_fonts_installed_individually(self, install_sh):
        assert "for f in ttf-wqy-zenhei ttf-wqy-microhei" in install_sh

    def test_centos_package_names(self, install_sh):
        block = re.search(r"^Installation_dependency\(\) \{.*?\n\}", install_sh, re.S | re.M).group(0)
        assert "mkfontscale" not in block
        assert "xorg-x11-server-Xvfb" not in block
        assert "python3" in block


class TestInstallTailIsNonBlocking:
    def test_install_zhenxun_does_not_tail_logs(self, install_sh):
        block = re.search(r"^Install_zhenxun_bot\(\) \{.*?\n\}", install_sh, re.S | re.M).group(0)
        assert "View_napcat_log" not in block
        assert "tail -f" not in block
        assert "返回主菜单" in block

    def test_log_paths_printed(self, install_sh):
        assert "${LLBOT_HOME}/logs/llbot.log" in install_sh
        assert "${WORK_DIR}/zhenxun_bot/zhenxun_bot.log" in install_sh

    def test_webui_info_uses_enter_prompt(self, install_sh):
        block = re.search(r"^View_napcat_webui_info\(\) \{.*?\n\}", install_sh, re.S | re.M).group(0)
        assert "press_enter_to_return" in block
        assert "read -n 1 -s" not in block
