# 额外字体

原版宋体、黑体、仿宋、楷体、微软雅黑及方正小标宋简体按 `fonts/cjk-fonts.tsv` 安装；苹方 SC 和 SF Pro 按 `fonts/apple-fonts.tsv` 安装。Dockerfile 会自动下载这些字体，无须放入本目录。

将额外的 `.ttf`、`.otf`、`.ttc` 机构字体放在本目录，构建时自动安装到 `/usr/local/share/fonts/custom/` 并刷新字体缓存。避免放入同一家族的重复版本，以免实际选用版本不确定。

用 `fc-list` 或 docx skill 的 `inspect_environment.py --font '<字体家族>'` 确认实际家族名称。
