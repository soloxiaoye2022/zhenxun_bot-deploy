from tests.deploy_logic import PORT_MAX, PORT_MIN


REQUIRED_TOP_LEVEL_KEYS = {
    "group_manager",
    "hook",
    "_task",
    "_backup",
    "invite_manager",
    "admin_bot_manage",
    "shop",
    "alapi",
    "draw_card",
    "genshin",
    "word_bank",
    "pixiv",
    "hibiapi",
    "pix",
    "image_management",
    "reload_setting",
    "open_cases",
    "search_buff_skin_price",
    "mute",
    "check_zhenxun_update",
    "ban",
    "nickname",
    "bt",
    "search_image",
    "coser",
    "resin_remind",
    "russian",
    "send_setu",
    "update_gocqhttp",
    "search_anime",
    "pixiv_rank_search",
    "bilibili_sub",
    "sign_in",
    "fudu",
    "ai",
}


class TestConfigStructure:
    def test_file_notes_runtime_path(self, repo_root):
        text = (repo_root / "config.yaml").read_text(encoding="utf-8")
        assert "data/config.yaml" in text

    def test_top_level_keys_exist(self, config_data):
        missing = REQUIRED_TOP_LEVEL_KEYS - set(config_data)
        assert missing == set()

    def test_yaml_loads_as_dict(self, config_data):
        assert isinstance(config_data, dict)
        assert config_data


class TestGroupAndHookDefaults:
    def test_group_manager_defaults(self, config_data):
        gm = config_data["group_manager"]
        assert gm["DEFAULT_GROUP_LEVEL"] == 5
        assert gm["DEFAULT_GROUP_BOT_STATUS"] is True

    def test_hook_malicious_thresholds(self, config_data):
        hook = config_data["hook"]
        assert hook["CHECK_NOTICE_INFO_CD"] == 300
        assert hook["MALICIOUS_BAN_TIME"] == 30
        assert hook["MALICIOUS_CHECK_TIME"] == 5
        assert hook["MALICIOUS_BAN_COUNT"] == 6
        assert hook["BAN_RESULT"] == "才不会给你发消息."
        assert hook["MALICIOUS_BAN_COUNT"] > 0
        assert hook["MALICIOUS_CHECK_TIME"] > 0


class TestTaskAndBackup:
    def test_all_default_tasks_enabled(self, config_data):
        task = config_data["_task"]
        expected = [
            "DEFAULT_BROADCAST",
            "DEFAULT_ZWA",
            "DEFAULT_GROUP_WELCOME",
            "DEFAULT_REFUND_GROUP_REMIND",
            "DEFAULT_OPEN_CASE_RESET_REMIND",
            "DEFAULT_BILIBILI_PARSE",
            "DEFAULT_FUDU",
            "DEFAULT_GENSHIN_ALC",
            "DEFAULT_EPIC_FREE_GAME",
            "DEFAULT_PA",
        ]
        for key in expected:
            assert task[key] is True

    def test_backup_paths(self, config_data):
        backup = config_data["_backup"]
        assert backup["BACKUP_FLAG"] is True
        paths = backup["BACKUP_DIR_OR_FILE"]
        assert "configs" in paths
        assert "data/configs" in paths
        assert all(isinstance(item, str) and item for item in paths)


class TestInviteAndAdmin:
    def test_invite_manager(self, config_data):
        invite = config_data["invite_manager"]
        assert invite["FLAG"] is True
        assert invite["AUTO_ADD_FRIEND"] is False
        assert invite["WELCOME_MSG_CD"] == 5
        assert "真寻" in invite["MESSAGE"]

    def test_admin_bot_manage_levels(self, config_data):
        admin = config_data["admin_bot_manage"]
        assert admin["SET_GROUP_WELCOME_MESSAGE_LEVEL"] == 2
        assert admin["CHANGE_GROUP_SWITCH_LEVEL"] == 2
        assert admin["ADMIN_DEFAULT_AUTH"] == 5
        assert 1 <= admin["ADMIN_DEFAULT_AUTH"] <= 9


class TestDrawCardAndGenshin:
    def test_all_draw_card_flags_enabled(self, config_data):
        draw = config_data["draw_card"]
        flags = [
            "PRTS_FLAG",
            "GENSHIN_FLAG",
            "PRETTY_FLAG",
            "GUARDIAN_FLAG",
            "PCR_FLAG",
            "AZUR_FLAG",
            "FGO_FLAG",
            "ONMYOJI_FLAG",
            "PCR_TAI",
        ]
        for flag in flags:
            assert draw[flag] is True
        assert draw["SEMAPHORE"] == 5
        assert draw["SEMAPHORE"] > 0

    def test_genshin_client_fields(self, config_data):
        genshin = config_data["genshin"]
        assert genshin["MHYVERSION"] == "2.11.1"
        assert genshin["CLIENT_TYPE"] == "5"
        assert genshin["SALT"]
        assert genshin["N"]


class TestPixAndImage:
    def test_pix_defaults(self, config_data):
        pix = config_data["pix"]
        assert pix["PIX_IMAGE_SIZE"] in {"original", "master"}
        assert pix["SEARCH_HIBIAPI_BOOKMARKS"] == 5000
        assert pix["TIMEOUT"] == 10
        assert pix["SHOW_INFO"] is True
        delay, chat_type = pix["WITHDRAW_PIX_MESSAGE"]
        assert delay == 0
        assert chat_type in {0, 1, 2}

    def test_image_management_dirs(self, config_data):
        image = config_data["image_management"]
        assert image["IMAGE_DIR_LIST"] == ["美图", "萝莉", "壁纸"]
        assert image["DELETE_IMAGE_LEVEL"] == 7
        assert image["MOVE_IMAGE_LEVEL"] == 7
        assert image["UPLOAD_IMAGE_LEVEL"] == 6
        assert image["UPLOAD_IMAGE_LEVEL"] <= image["DELETE_IMAGE_LEVEL"]

    def test_pixiv_proxy_and_hibiapi(self, config_data):
        assert config_data["pixiv"]["PIXIV_NGINX_URL"] == "i.pixiv.re"
        assert config_data["hibiapi"]["HIBIAPI"].startswith("https://")


class TestMuteBanAndShop:
    def test_mute_defaults(self, config_data):
        mute = config_data["mute"]
        assert mute["MUTE_DEFAULT_COUNT"] == 10
        assert mute["MUTE_DEFAULT_TIME"] == 7
        assert mute["MUTE_DEFAULT_DURATION"] == 10

    def test_shop_imports_default_goods(self, config_data):
        assert config_data["shop"]["IMPORT_DEFAULT_SHOP_GOODS"] is True

    def test_auto_update_disabled(self, config_data):
        assert config_data["check_zhenxun_update"]["AUTO_UPDATE_ZHENXUN"] is False


class TestGameAndSignIn:
    def test_russian_max_bet(self, config_data):
        assert config_data["russian"]["MAX_RUSSIAN_BET_GOLD"] == 1000

    def test_sign_in_probabilities(self, config_data):
        sign = config_data["sign_in"]
        assert sign["MAX_SIGN_GOLD"] == 200
        assert 0 <= sign["SIGN_CARD1_PROB"] <= 1
        assert 0 <= sign["SIGN_CARD2_PROB"] <= 1
        assert 0 <= sign["SIGN_CARD3_PROB"] <= 1
        assert sign["SIGN_CARD1_PROB"] > sign["SIGN_CARD2_PROB"] > sign["SIGN_CARD3_PROB"]

    def test_fudu_probability(self, config_data):
        assert 0 <= config_data["fudu"]["FUDU_PROBABILITY"] <= 1

    def test_send_setu_defaults(self, config_data):
        setu = config_data["send_setu"]
        assert setu["ONLY_USE_LOCAL_SETU"] is False
        assert 0 <= setu["INITIAL_SETU_PROBABILITY"] <= 1
        assert setu["DOWNLOAD_SETU"] is True
        assert setu["TIMEOUT"] == 10


class TestNicknameAndAiFilter:
    def test_nickname_black_words(self, config_data):
        words = config_data["nickname"]["BLACK_WORD"]
        assert "爸" in words
        assert "爹" in words
        assert "爷" in words

    def test_ai_text_filter(self, config_data):
        ai = config_data["ai"]
        assert ai["ALAPI_AI_CHECK"] is False
        assert ai["TL_KEY"] == []
        assert "鸡" in ai["TEXT_FILTER"]


class TestNumericBounds:
    def test_bt_max_num(self, config_data):
        assert 1 <= config_data["bt"]["BT_MAX_NUM"] <= 50

    def test_search_image_count(self, config_data):
        assert 1 <= config_data["search_image"]["MAX_FIND_IMAGE_COUNT"] <= 10

    def test_search_anime_max(self, config_data):
        assert config_data["search_anime"]["SEARCH_ANIME_MAX_INFO"] == 20

    def test_reload_setting(self, config_data):
        reload_setting = config_data["reload_setting"]
        assert reload_setting["AUTO_RELOAD"] is False
        assert reload_setting["AUTO_RELOAD_TIME"] == 180

    def test_open_cases(self, config_data):
        cases = config_data["open_cases"]
        assert cases["INITIAL_OPEN_CASE_COUNT"] == 20
        assert cases["EACH_IMPRESSION_ADD_COUNT"] == 3

    def test_resin_remind(self, config_data):
        resin = config_data["resin_remind"]
        assert resin["AUTO_CLOSE_QUERY_FAIL_RESIN_REMIND"] is True
        assert resin["CUSTOM_RESIN_OVERFLOW_REMIND"] == 20

    def test_bilibili_sub_level(self, config_data):
        assert config_data["bilibili_sub"]["GROUP_BILIBILI_SUB_LEVEL"] == 5

    def test_pixiv_rank_limits(self, config_data):
        rank = config_data["pixiv_rank_search"]
        assert rank["TIMEOUT"] == 10
        assert rank["MAX_PAGE_LIMIT"] == 20
        assert PORT_MIN <= 14514 <= PORT_MAX
