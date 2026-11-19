class TestReadme:
    def test_title(self, repo_root):
        text = (repo_root / "README.md").read_text(encoding="utf-8")
        assert "zhenxun_bot-deploy" in text
        assert "真寻 bot 一键部署脚本" in text

    def test_supported_distros(self, repo_root):
        text = (repo_root / "README.md").read_text(encoding="utf-8")
        assert "Debian11/12" in text
        assert "Ubuntu20/22/24" in text
        assert "Python 3.10+" in text or "python3.10+" in text.lower() or ">= 3.10" in text
        assert "whiptail" in text or "tmoe" in text

    def test_install_command_points_to_install_sh(self, repo_root):
        text = (repo_root / "README.md").read_text(encoding="utf-8")
        assert "install.sh" in text
        assert "soloxiaoye2022/zhenxun_bot-deploy" in text

    def test_official_uv_and_napcat(self, repo_root):
        text = (repo_root / "README.md").read_text(encoding="utf-8")
        assert "uv sync" in text
        assert "uv run zx" in text
        assert "zhenxun-org/zhenxun_bot" in text
        assert "LuckyLilliaBot" in text
        assert "LuckyLillia-CLI-linux-x64.zip" in text
        assert "ws://127.0.0.1:8080/onebot/v11/ws" in text

    def test_napcat_migration_note(self, repo_root):
        text = (repo_root / "README.md").read_text(encoding="utf-8")
        assert "NapCat" in text or "Napcat" in text
        assert "go-cqhttp" in text

    def test_mirror_section(self, repo_root):
        text = (repo_root / "README.md").read_text(encoding="utf-8")
        assert "GitHub 镜像" in text
        assert "/root/.zhenxun_deploy/proxy.conf" in text
        assert "gh-proxy.org" in text

    def test_dead_mirrors_not_in_commands(self, repo_root):
        text = (repo_root / "README.md").read_text(encoding="utf-8")
        command_lines = [l for l in text.splitlines() if "curl -s -L" in l]
        for line in command_lines:
            assert "github.moeyy.xyz" not in line
            assert "mirror.ghproxy.com" not in line
