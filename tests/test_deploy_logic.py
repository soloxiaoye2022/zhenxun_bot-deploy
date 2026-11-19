import json

import pytest

from tests.deploy_logic import (
    APT_MIRRORS,
    DEFAULT_DB_NAME,
    DEFAULT_DB_PASSWORD,
    DEFAULT_DB_USER,
    DEFAULT_MUSIC_SIGN_URL,
    DEFAULT_PORT,
    DEFAULT_SQLITE_URL,
    PIP_MIRRORS,
    PORT_MAX,
    PORT_MIN,
    build_onebot11_config,
    build_postgres_url,
    build_qq_data,
    build_sqlite_url,
    choose_python,
    detect_release,
    dumps_onebot11_config,
    extract_missing_modules,
    filter_install_modules,
    install_duration,
    is_bot_qq_allowed,
    is_valid_port,
    is_valid_qq,
    map_arch,
    needs_napcat_update,
    package_format,
    parse_semver,
    resolve_apt_source,
    resolve_pip_mirror,
    rewrite_apt_source_line,
)


class TestQQValidation:
    @pytest.mark.parametrize("value", ["1", "123456", "10001", "9876543210"])
    def test_valid_qq_numbers(self, value):
        assert is_valid_qq(value) is True

    @pytest.mark.parametrize("value", [None, "", "abc", "12a", " 123", "123 ", "12.3", "-1"])
    def test_invalid_qq_numbers(self, value):
        assert is_valid_qq(value) is False

    def test_bot_qq_must_differ_from_admin(self):
        assert is_bot_qq_allowed("10001", "10002") is True
        assert is_bot_qq_allowed("10001", "10001") is False
        assert is_bot_qq_allowed("", "10001") is False
        assert is_bot_qq_allowed("bot", "10001") is False


class TestPortValidation:
    @pytest.mark.parametrize("port", [PORT_MIN, PORT_MIN + 1, 8080, 14514, PORT_MAX])
    def test_valid_ports(self, port):
        assert is_valid_port(port) is True

    @pytest.mark.parametrize("port", [0, 80, 1023, 49152, 65535, -1, "", "abc", None, "  "])
    def test_invalid_ports(self, port):
        assert is_valid_port(port) is False

    def test_string_port_is_accepted(self):
        assert is_valid_port("14514") is True


class TestArchMapping:
    def test_x86_64(self):
        assert map_arch("x86_64") == "amd64"

    def test_aarch64(self):
        assert map_arch("aarch64") == "arm64"

    def test_v8l(self):
        assert map_arch("v8l") == "arm64"

    def test_llbot_assets(self):
        from tests.deploy_logic import llbot_asset_name

        assert llbot_asset_name("amd64") == "LuckyLillia-CLI-linux-x64.zip"
        assert llbot_asset_name("arm64") == "LuckyLillia-CLI-linux-arm64.zip"

    @pytest.mark.parametrize("arch", ["i386", "armv7l", "mips", ""])
    def test_unsupported_arch(self, arch):
        with pytest.raises(ValueError, match="unsupported arch"):
            map_arch(arch)


class TestSupportedOs:
    def test_debian_11_and_12(self):
        from tests.deploy_logic import is_supported_os

        assert is_supported_os("debian", "11") is True
        assert is_supported_os("debian", "12") is True
        assert is_supported_os("debian", "10") is False

    def test_ubuntu_floor(self):
        from tests.deploy_logic import is_supported_os

        assert is_supported_os("ubuntu", "20.04") is True
        assert is_supported_os("ubuntu", "22.04") is True
        assert is_supported_os("ubuntu", "24.04") is True
        assert is_supported_os("ubuntu", "18.04") is False

    def test_centos_and_arch_pass(self):
        from tests.deploy_logic import is_supported_os

        assert is_supported_os("centos", "7") is True
        assert is_supported_os("archlinux", None) is True


class TestNapcatVersion:
    def test_parse_semver_with_v_prefix(self):
        assert parse_semver("v2.1.0") == (2, 1, 0)

    def test_parse_semver_without_prefix(self):
        assert parse_semver("1.2.3") == (1, 2, 3)

    @pytest.mark.parametrize("value", ["1.2", "abc", "v1", "1.2.3.4", ""])
    def test_invalid_semver(self, value):
        with pytest.raises(ValueError):
            parse_semver(value)

    def test_needs_update_when_major_is_behind(self):
        assert needs_napcat_update("1.9.9", "v2.0.0") is True

    def test_needs_update_when_minor_is_behind(self):
        assert needs_napcat_update("2.0.9", "v2.1.0") is True

    def test_needs_update_when_patch_is_behind(self):
        assert needs_napcat_update("2.1.0", "v2.1.1") is True

    def test_no_update_when_equal(self):
        assert needs_napcat_update("2.1.0", "v2.1.0") is False

    def test_no_update_when_current_is_newer(self):
        assert needs_napcat_update("3.0.0", "v2.9.9") is False


class TestPipMirror:
    def test_default_is_bfsu(self):
        assert resolve_pip_mirror(None) == PIP_MIRRORS["5"]
        assert resolve_pip_mirror("") == PIP_MIRRORS["5"]

    @pytest.mark.parametrize("num,expected", list(PIP_MIRRORS.items()))
    def test_known_mirrors(self, num, expected):
        assert resolve_pip_mirror(num) == expected

    def test_skip_change(self):
        assert resolve_pip_mirror("6") is None

    def test_invalid_option(self):
        with pytest.raises(ValueError):
            resolve_pip_mirror("9")


class TestAptSource:
    def test_default_is_bfsu(self):
        assert resolve_apt_source(None) == APT_MIRRORS["1"]
        assert resolve_apt_source("") == APT_MIRRORS["1"]

    @pytest.mark.parametrize("num,expected", list(APT_MIRRORS.items()))
    def test_known_sources(self, num, expected):
        assert resolve_apt_source(num) == expected

    def test_keep_current_source(self):
        assert resolve_apt_source("7") is None

    def test_invalid_option(self):
        with pytest.raises(ValueError):
            resolve_apt_source("8")

    def test_rewrite_https_org_source(self):
        line = "deb https://archive.ubuntu.org/ubuntu jammy main"
        rewritten = rewrite_apt_source_line(line, "https://mirrors.bfsu.edu.cn/")
        assert rewritten == "deb https://mirrors.bfsu.edu.cn/ubuntu jammy main"

    def test_rewrite_http_com_source(self):
        line = "deb http://mirrors.aliyun.com/debian bookworm main"
        rewritten = rewrite_apt_source_line(line, "https://mirrors.tuna.tsinghua.edu.cn/")
        assert rewritten.startswith("deb https://mirrors.tuna.tsinghua.edu.cn/")


class TestMissingModules:
    def test_extracts_quoted_module_names(self):
        log = (
            "ModuleNotFoundError: No module named 'nonebot'\n"
            "ImportError: No module named 'aiohttp'\n"
            "ok line\n"
        )
        assert extract_missing_modules(log) == ["nonebot", "aiohttp"]

    def test_filter_dedup_and_drop_enchant(self):
        names = ["aiohttp", "enchant", "aiohttp", "nonebot", "enchant.utils"]
        assert filter_install_modules(names) == ["aiohttp", "nonebot"]

    def test_empty_log(self):
        assert extract_missing_modules("") == []
        assert filter_install_modules([]) == []


class TestPostgresUrl:
    def test_default_url(self):
        assert (
            build_postgres_url()
            == f"postgres://{DEFAULT_DB_USER}:{DEFAULT_DB_PASSWORD}@127.0.0.1:5432/{DEFAULT_DB_NAME}"
        )

    def test_default_sqlite_url(self):
        assert build_sqlite_url() == DEFAULT_SQLITE_URL

    def test_custom_url(self):
        url = build_postgres_url("u", "p", "db.host", 15432, "bot")
        assert url == "postgres://u:p@db.host:15432/bot"


class TestNapcatConfigBuilders:
    def test_qq_data_shape(self):
        data = build_qq_data("123456")
        assert data == {"bot_qq": "123456", "other_QQ": []}

    def test_onebot_ws_url_and_music_sign(self):
        cfg = build_onebot11_config("123456", DEFAULT_PORT)
        client = cfg["ob11"]["connect"][0]
        assert client["url"] == f"ws://127.0.0.1:{DEFAULT_PORT}/onebot/v11/ws"
        assert client["type"] == "ws-reverse"
        assert client["enable"] is True
        assert cfg["ob11"]["enable"] is True
        assert cfg["webui"]["port"] == 3080

    def test_onebot_config_is_json_serializable(self):
        raw = dumps_onebot11_config("10001", 8080)
        parsed = json.loads(raw)
        assert parsed["ob11"]["connect"][0]["url"].endswith(":8080/onebot/v11/ws")


class TestReleaseDetection:
    def test_debian_from_issue(self):
        assert detect_release(issue_text="Debian GNU/Linux 12") == "debian"

    def test_ubuntu_from_issue(self):
        assert detect_release(issue_text="Ubuntu 22.04 LTS") == "ubuntu"

    def test_centos_from_redhat_release_file(self):
        assert detect_release(redhat_release=True) == "centos"

    def test_centos_from_proc_version(self):
        assert detect_release(proc_version="centos kernel") == "centos"

    def test_archlinux(self):
        assert detect_release(issue_text="Arch Linux") == "archlinux"

    def test_unsupported(self):
        with pytest.raises(ValueError):
            detect_release(issue_text="Fedora Linux")

    def test_package_format(self):
        assert package_format("debian") == "deb"
        assert package_format("ubuntu") == "deb"
        assert package_format("centos") == "rpm"
        assert package_format("archlinux") is None


class TestPythonChooser:
    def test_prefers_newest_available(self):
        assert choose_python(["python3.10", "python3.11", "python3.12"]) == "python3.12"

    def test_falls_back_to_3_10(self):
        assert choose_python(["python3.10"]) == "python3.10"

    def test_none_when_missing(self):
        assert choose_python(["python3.8", "python3.9", "python2"]) is None


class TestInstallDuration:
    def test_duration(self):
        assert install_duration(100, 250) == 150
