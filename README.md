## Description

Decode silk v3 audio files (like wechat amr, aud files, qq slk files) and convert to other format (like mp3).
Batch conversion support.

<a href="https://github.com/kn007/silk-v3-decoder/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat"></a>

```
silk-v3-decoder            (Decode Silk V3 Audio Files)
  |
  |---  silk               (Skype Silk Codec)
  |
  |---  windows            (For Windows Platform Users Program)
  |
  |---  LICENSE            (License)
  |
  |---  README.md          (Readme)
  |
  |---  converter.sh       (Converter Shell Script)
  |
  |---  converter_beta.sh  (Converter Shell Script(Beta))
```

## Requirement

- gcc
- ffmpeg

## How To Use

```
sh converter.sh silk_v3_file/input_folder output_format/output_folder flag(format)
```

E.g., convert a file:

```
sh converter.sh 33921FF3774A773BB193B6FD4AD7C33E.slk mp3
```

Notice: the `33921FF3774A773BB193B6FD4AD7C33E.slk` is an audio file you need to convert, the `mp3` is a format you need to output.

If you need to convert all audio files in one folder, now batch conversion support, using like this:

```
sh converter.sh input ouput mp3
```

Notice: the `input` folder is content the audio files you need to convert, the `output` folder is content the audio files after conversion finished, the `mp3` is a format you need to output.

If you need to convert files on the `Windows` platfrom, [click here](https://dl.kn007.net/directlink/silk2mp3.zip "silk2mp3.zip") to download zip package for `silk2mp3.exe` to convert, also can <a href='/windows' target="_blank">click here</a> to get more information.

## Other

Also provide silk v3 encode codec, compatible with Wechat/QQ.

## About

[kn007's blog](https://kn007.net)

---

## 中文说明

解码silk v3音频文件（类似微信的amr和aud文件、QQ的slk文件）并转换为其它格式（如MP3）。
支持批量转换。

<a href="https://github.com/kn007/silk-v3-decoder/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat"></a>

```
silk-v3-decoder            (解码silk v3音频文件)
  |
  |---  silk               (Skype Silk源码)
  |
  |---  windows            (可用于Windows平台的应用程序)
  |
  |---  LICENSE            (软件使用范围许可)
  |
  |---  README.md          (说明)
  |
  |---  converter.sh       (转换脚本)
  |
  |---  converter_beta.sh  (转换脚本(测试版))
```

## 依赖组件

- gcc
- ffmpeg

## 如何使用

```
sh converter.sh silk_v3_file/input_folder output_format/output_folder flag(format)
```

比如转换一个文件，使用：

```
sh converter.sh 33921FF3774A773BB193B6FD4AD7C33E.slk mp3
```

注意：其中`33921FF3774A773BB193B6FD4AD7C33E.slk`是要转换的文件，而`mp3`是最终转换后输出的格式。

如果你需要批量转换，比如转换某个目录，那么使用：

```
sh converter.sh input ouput mp3
```

注意：其中`input`是要转换的目录，而`output`是最终转换后音频输出的目录，最后的`mp3`参数是最终转换后输出的格式。

如果你需要在`Windows`下使用该程序，请下载[silk2mp3.exe](https://dl.kn007.net/directlink/silk2mp3.zip "silk2mp3.zip")应用程序来完成转换，你可<a href='/windows' target="_blank">点击这里</a>来查看更多Windows下如何使用的相关说明。

## 其他说明

如果你需要对音频文件进行silk v3编码，源码也已经提供，并且对微信、QQ进行了兼容，详见参数。

## 关于作者

`docker build -t registry.cn-shenzhen.aliyuncs.com/houhou/silk-base:latest --platform=linux/amd64 .`

[kn007的个人博客](https://kn007.net)

## 文档排版依赖

基础镜像包含 LibreOffice、Pandoc、Poppler、Python 文档/PDF/OCR 库和 Node docx。Typst 使用官方 0.15.1 发行版， 按 linux/amd64 或 linux/arm64 下载静态程序；版本可通过 `TYPST_VERSION` 构建参数调整。

字体包括已有 Noto/Inter/Liberation、Debian `ttf-mscorefonts-installer` 提供的 Arial/Times New Roman，以及 CTAN Fandol 0.3 的宋、黑、楷、仿宋风格。Fandol 下载会校验 SHA-256，并保留许可证。构建时检查字体库存，下载失败或必需字体缺失会使构建失败。

原版中文字体按 `fonts/cjk-fonts.tsv` 中的固定提交 URL 下载，逐文件核对 SHA-256 后安装；清单保留在镜像的 `/usr/local/share/doc/windows-cjk/sources.tsv`。当前安装以下已授权字体，合计约 98 MiB：

| 字体           | 实际家族名                          | 文件 / 内置版本                               |
| -------------- | ----------------------------------- | --------------------------------------------- |
| 宋体、新宋体   | SimSun、NSimSun                     | simsun.ttc / 5.16                             |
| 黑体           | SimHei                              | simhei.ttf / 5.03                             |
| 仿宋           | FangSong                            | simfang.ttf / 5.01                            |
| 楷体           | KaiTi                               | simkai.ttf / 5.01                             |
| 微软雅黑及 UI  | Microsoft YaHei、Microsoft YaHei UI | msyh.ttc、msyhbd.ttc / 6.25；msyhl.ttc / 6.23 |
| 方正小标宋简体 | FZXiaoBiaoSong-B05S、方正小标宋简体 | FZXBSJW.TTF / 4.00                            |

下载使用 [Windows 中文字体镜像](https://github.com/xoofee/chinese_fonts/tree/5f6db40c7cc93fb54e4cf16641ba54cf84889f62) 和 [方正小标宋字体镜像](https://github.com/genqiaolynn/fonts/tree/e4ab27ccafd22211c09109ac6e0c7e70c29cb2e9)，具体文件地址和校验值以清单为准。构建不依赖仓库分支后续更新，字体文件本身不放入 Git。

苹果风格的简体中文、英文和数字通过 `fonts/apple-fonts.tsv` 安装，增加约 88 MiB：

| 字体              | 实际家族名           | 文件 / 内置版本                                                                           |
| ----------------- | -------------------- | ----------------------------------------------------------------------------------------- |
| 苹方简体中文      | PingFang SC、苹方-简 | PingFangSC-\*.otf / 19.0d5e3；Ultralight、Thin、Light、Regular、Medium、Semibold 六种字重 |
| SF Pro 英文和数字 | SF Pro               | SF-Pro.ttf、SF-Pro-Italic.ttf / 16.0d18e1；可变字重正体和斜体                             |

字体分别来自固定提交的 [苹方 OTF 跨平台版本](https://github.com/ZWolken/PingFang/tree/92cad0e8cfce61ddae4a220739a250d95f22fb78) 和 [SF Pro 字体镜像](https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts/tree/8bfea09aa6f1139479f80358b2e1e5c6dc991a58)，下载后逐文件核对 SHA-256。只选择苹方 SC 文件；来源清单保留在 `/usr/local/share/doc/apple-fonts/sources.tsv`，字体安装到 `/usr/local/share/fonts/apple/`。无需新增系统或 Python 依赖。

Word 中将西文字体设为 `SF Pro`、东亚字体设为 `PingFang SC`；Typst 使用 `#set text(font: ("SF Pro", "PingFang SC"))`。使用前可检查 `inspect_environment.py --font 'PingFang SC' --font 'SF Pro'`。

额外机构字体可放入 `custom-fonts/` 再构建。任务可用 docx skill 的 `inspect_environment.py --font '<字体家族>'` 检查实际家族；Fandol 保留作为独立备用字库。上述字体会在重新构建基础镜像后生效，旧镜像需重新部署。

来源：[Typst 官方发行版](https://github.com/typst/typst/releases/tag/v0.15.1)、[CTAN Fandol](https://ctan.org/pkg/fandol)、[Debian Microsoft core fonts](https://packages.debian.org/trixie/ttf-mscorefonts-installer)。
