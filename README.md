# 叁仟书屋数据仓

本仓库是**人类文明公版书的元数据仓**，只收录书目、字段约定与导读模板，不托管任何书籍全文。

网站代码与页面在独立仓库：[LF2023/3000books](https://github.com/LF2023/3000books)。本仓与网站仓分离：改元数据不必动站点，改站点不必动书目。

项目中文名：叁仟书屋。维护者：Fan Lao（LF2023）。

## 本仓放什么、不放什么

- 放：`meta.json` 书目字段、`summary.md` 导读空模板、JSON Schema、节点说明。
- 不放：EPUB / PDF / TXT 全文、下载链接、CDN、封面图、评分、译者杜撰、线下咖啡馆或守书人虚构点位。
- 公版状态**未逐本核验**。每条记录的 `rights.status` 均为 `unverified`，`rights.hostsFullText` 均为 `false`。

## 目录结构

```
.
├── README.md                 本说明
├── LICENSE                   CC0 1.0（元数据公有领域奉献）
├── .gitignore
├── schema/
│   └── book.schema.json      单本书 meta.json 的 JSON Schema
├── books/
│   ├── index.json            全部书目简表（按 id 排序）
│   └── <id>-<slug>/
│       ├── meta.json         书目元数据
│       └── summary.md        导读模板（标题、作者、时代 + 空章节）
└── nodes/
    ├── README.md             线下节点约定（现无点位）
    └── .gitkeep
```

`books/index.json` 中每条为 `{id, slug, title, author, era, category}`，与对应目录下 `meta.json` 的核心字段一致。

## 贡献方式

1. 先读 `schema/book.schema.json`，新增或修改的 `meta.json` 必须能通过该 schema 校验。
2. 一书一目录：`books/<四位id>-<slug>/`，内含 `meta.json` 与 `summary.md`。
3. 同步更新 `books/index.json`，保持按 `id` 升序。
4. `summary.md` 只保留模板结构（书名、作者、时代，以及「为何收录 / 要点 / 版本备忘」三个空的二级标题）。不要编造学术导读、馆藏数字或评分。
5. 不要提交：全文文件、下载 URL、CDN、封面、译者杜撰、评分、虚构节点坐标。
6. 不要把 `rights.status` 改成已核验，除非你提供可复核的公版依据，并在贡献说明里写明来源。默认保持 `unverified`。
7. 用 UTF-8、无 BOM、JSON 缩进 2 空格、Markdown 使用 LF 换行，然后提交 Pull Request。

## 版权声明

- **本仓只放元数据与导读模板，不托管全文。**
- 各书是否进入公版、在何法域进入公版，**未逐本核验**。机器可读字段为 `rights.status: "unverified"`。
- **勿提交受版权保护的全文**，也勿提交指向这类全文的下载地址。
- 本仓库内由维护者编写的元数据与模板，依 [CC0 1.0](LICENSE) 奉献至公有领域。原书本身的版权状态与本仓元数据许可是两件事，互不替代。

## 许可

见 [LICENSE](LICENSE)（CC0 1.0 Universal）。
