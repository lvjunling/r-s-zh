"""把采集并翻译好的 JSON 嵌入 Lua，生成独立的汉化加载器。"""
import argparse
import json
from pathlib import Path
from urllib.parse import urlsplit


def lua_literal(text):
    # 长字符串首个换行会被 Lua 丢弃，JSON 和 URL 均不以换行开头。
    equals = ""
    while "]" + equals + "]" in text:
        equals += "="
    return "[" + equals + "[" + text + "]" + equals + "]"


def build(data, template):
    if not isinstance(data, dict) or data.get("version") != 1:
        raise ValueError("JSON version 必须为 1")
    url = data.get("script_url")
    if not isinstance(url, str) or any(c.isspace() for c in url):
        raise ValueError("script_url 应是没有空白的 HTTPS 地址")
    parsed = urlsplit(url)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password:
        raise ValueError("script_url 应是有效的 HTTPS 地址，且不含登录凭证")
    translations = data.get("translations")
    if not isinstance(translations, dict) or not all(
        isinstance(k, str) and isinstance(v, str) for k, v in translations.items()
    ):
        raise ValueError("translations 必须是原文到中文的字符串映射")
    start = "-- BEGIN GENERATED CONFIG"
    end = "-- END GENERATED CONFIG"
    if template.count(start) != 1 or template.count(end) != 1:
        raise ValueError("Lua 模板配置标记异常")
    before, rest = template.split(start)
    _, after = rest.split(end)
    payload = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    config = (
        "\nlocal SETTINGS = { script_url = " + lua_literal(url) + ', mode = "translate" }\n'
        + "local EMBEDDED_JSON = " + lua_literal(payload) + "\n"
    )
    return before + start + config + end + after


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("json_file", type=Path)
    parser.add_argument("output", type=Path, help="新的 .lua 路径；保留已有文件")
    args = parser.parse_args()
    try:
        data = json.loads(args.json_file.read_text(encoding="utf-8-sig"))
        template = Path(__file__).with_name("localizer.lua").read_text(encoding="utf-8")
        result = build(data, template)
        with args.output.open("x", encoding="utf-8") as file:
            file.write(result)
        print(f"已生成：{args.output.resolve()}")
    except (OSError, ValueError) as err:
        parser.exit(1, f"生成失败：{err}\n")


if __name__ == "__main__":
    main()
