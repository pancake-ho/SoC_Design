"""Import a DICE result archive and rebuild a portable HTML comparison."""
import html
from pathlib import Path

from import_server_results import main
from pc_paths import display_path, filesystem_path
from server_comparison import build


def report():
    root = Path(__file__).resolve().parents[1]
    output = root / 'reports'
    output.mkdir(exist_ok=True)

    def link(path, label):
        uri = display_path(path.absolute()).as_uri()
        return f'<a href="{html.escape(uri, quote=True)}">{html.escape(label)}</a>'

    comparison = build(filesystem_path(root / 'server_results'), output, link)
    page = '''<!doctype html>
<html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>EE470 V8 실행 결과</title>
<style>
body { font: 16px/1.6 system-ui; margin: 2rem; color: #172135 }
main { overflow: auto } details { margin-block: 1rem }
summary { cursor: pointer; font-weight: bold } code { overflow-wrap: anywhere }
table { border-collapse: collapse; margin-block: 1rem }
th, td { padding: .5rem .75rem; border-bottom: 1px solid #ccd4df; text-align: left }
</style><h1>EE470 V8 실행 결과</h1><main>''' + comparison + '</main></html>\n'
    target = output / 'index.html'
    target.write_text(page, encoding='utf-8')
    print('REPORT=' + str(target))


if __name__ == '__main__':
    raise SystemExit(main(on_import=report))
