#!/usr/bin/env bash
# fetch-covers.sh — 从 Google Books 抓取中文封面到数据仓
# 用法: GOOGLE_BOOKS_API_KEY=<key> ./scripts/fetch-covers.sh
# 规则:
#   - 只查 langRestrict=zh,要求返回条目 language 以 zh 开头且带 imageLinks
#   - 标题双向包含校验(返回 title 含书名,或书名含返回 title),防同名不同书
#   - 命中下载 zoom=3 大图(约 512px 宽)存 covers/<id>-<slug>.jpg
#   - 命中与否写回 books/index.json 的 cover 字段(true/false)
#   - 未命中的书由站点侧回退为程序生成书衣
#   - 限速 0.4s/请求;429/403 立即终止(API key 配额异常)
set -uo pipefail
cd "$(dirname "$0")/.."

KEY="${GOOGLE_BOOKS_API_KEY:?需要 GOOGLE_BOOKS_API_KEY 环境变量(免费申请于 Google Cloud Console > APIs & Services > Credentials)}"
OUT="covers"
mkdir -p "$OUT"

pyget() { py -c "$1"; }

# 生成任务清单
pyget "
import json
books = json.load(open('books/index.json', encoding='utf-8'))
open('.covers-tasks.tsv', 'w', encoding='utf-8').write('\n'.join(f\"{b['id']}\t{b['slug']}\t{b['title']}\" for b in books))
print(len(books))
" > .covers-count

TOTAL=$(cat .covers-count)
HIT=0; MISS=0; N=0

while IFS=$'\t' read -r id slug title; do
  N=$((N+1))
  # Git Bash 的 curl -G --data-urlencode 对部分中文序列有编码 bug;py 的 argv 中文传参在 Windows 也不可靠——一律走环境变量
  # 响应绝不经过 shell 变量/命令替换(MSYS locale 会损坏 UTF-8)——curl 直写文件
  ENC=$(TITLE="$title" py -c "import os, urllib.parse; print(urllib.parse.quote(os.environ['TITLE']))")
  curl -s --max-time 20 "https://www.googleapis.com/books/v1/volumes?q=$ENC&maxResults=5&langRestrict=zh&key=$KEY" -o .covers-resp.json
  if grep -q '"error"' .covers-resp.json 2>/dev/null; then echo "API ERROR, abort: $(head -c 200 .covers-resp.json)"; exit 1; fi
  THUMBURL=$(TITLE="$title" py -c "
import json, os, sys
from zhconv import convert
title = os.environ['TITLE']
try:
    r = json.load(open('.covers-resp.json', encoding='utf-8'))
except Exception:
    print(''); sys.exit()
t = title.replace(' ', '')
variants = {t, convert(t, 'zh-hant'), convert(t, 'zh-hans')}
def hit(vt):
    return any(v in vt or vt in v for v in variants if v)
for it in r.get('items') or []:
    v = it.get('volumeInfo', {})
    lang = (v.get('language') or '')
    vt = (v.get('title') or '').replace(' ', '')
    if not lang.startswith('zh'): continue
    thumb = (v.get('imageLinks') or {}).get('thumbnail') or ''
    if not thumb: continue
    if not hit(vt): continue
    print(thumb); break
")
  if [ -n "$THUMBURL" ]; then
    # zoom 提升;404/占位图回退原 URL(zoom=1)
    BIGURL=$(printf '%s' "$THUMBURL" | sed 's/zoom=1/zoom=3/')
    curl -sL --max-time 30 -o "$OUT/$id-$slug.jpg" "$BIGURL"
    SZ=$(wc -c < "$OUT/$id-$slug.jpg")
    if [ "$SZ" -lt 3000 ]; then
      curl -sL --max-time 30 -o "$OUT/$id-$slug.jpg" "$THUMBURL"
      SZ=$(wc -c < "$OUT/$id-$slug.jpg")
    fi
    if [ "$SZ" -gt 3000 ]; then
      HIT=$((HIT+1)); echo "[$N/$TOTAL] HIT     $title ($SZ bytes)"
    else
      rm -f "$OUT/$id-$slug.jpg"; MISS=$((MISS+1)); echo "[$N/$TOTAL] miss    $title (tiny image)"
    fi
  else
    MISS=$((MISS+1)); echo "[$N/$TOTAL] miss    $title"
  fi
  sleep 0.4
done < .covers-tasks.tsv

# 回写 index.json 的 cover 字段
pyget "
import json, os
books = json.load(open('books/index.json', encoding='utf-8'))
for b in books:
    b['cover'] = os.path.exists(f'covers/{b[\"id\"]}-{b[\"slug\"]}.jpg')
json.dump(books, open('books/index.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
print('index.json updated')
"
rm -f .covers-tasks.tsv .covers-count
echo "===== done: $HIT hit / $MISS miss ====="
