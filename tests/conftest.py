from pathlib import Path

import pytest
import yaml


@pytest.fixture(scope="session")
def repo_root():
    return Path(__file__).resolve().parents[1]


@pytest.fixture(scope="session")
def install_sh(repo_root):
    return (repo_root / "install.sh").read_text(encoding="utf-8")


@pytest.fixture(scope="session")
def config_data(repo_root):
    with open(repo_root / "config.yaml", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


@pytest.fixture(scope="session")
def requirements_text(repo_root):
    return (repo_root / "requirements.txt").read_text(encoding="utf-8")
