class TestRequirementsFile:
    def test_points_to_uv_workflow(self, requirements_text):
        assert "uv sync" in requirements_text
        assert "uv run zx" in requirements_text
        assert "pip install uv" in requirements_text

    def test_official_repo(self, requirements_text):
        assert "https://github.com/zhenxun-org/zhenxun_bot.git" in requirements_text

    def test_python_constraint(self, requirements_text):
        assert "Python >= 3.10" in requirements_text

    def test_mentions_uv_lock(self, requirements_text):
        assert "uv.lock" in requirements_text

    def test_aliyun_index_note(self, requirements_text):
        assert "https://mirrors.aliyun.com/pypi/simple/" in requirements_text
