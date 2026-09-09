# syntax=docker/dockerfile:1.7

# ────────────────────────
#  1️⃣ 编译阶段
# ────────────────────────
FROM debian:stable AS builder

ARG TARGETPLATFORM

# 依赖：gcc / make 以及 ffmpeg（便于在编译镜像里自测）
RUN --mount=type=cache,id=silk-base-builder-apt-cache-${TARGETPLATFORM},target=/var/cache/apt,sharing=locked \
  --mount=type=cache,id=silk-base-builder-apt-lib-${TARGETPLATFORM},target=/var/lib/apt,sharing=locked \
  rm -f /etc/apt/apt.conf.d/docker-clean && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
  build-essential \
  ffmpeg

# 拷贝源码（当前项目即为 silk-v3-decoder）
WORKDIR /src
COPY . .

# 编译 silk 解码器二进制
WORKDIR /src/silk
RUN make && make decoder && make encoder

# ────────────────────────
#  2️⃣ 运行阶段（最终基础镜像）
# ────────────────────────
FROM debian:stable-slim AS silk-base

ARG TARGETPLATFORM
ARG TARGETARCH
ARG TYPST_VERSION=0.15.1
ARG FANDOL_SHA256=9278f01b417ded5766d98c3937192a1a6a2c73a5e94a3493fdfc932b2a55005a
ARG NODE_MAJOR=24
ARG TSX_VERSION=latest
ARG PDFPLUMBER_VERSION=0.11.9
ARG PYPDF_VERSION=6.10.0
ARG REPORTLAB_VERSION=4.4.9
ARG RAPIDOCR_VERSION=3.9.1
ARG OMEGACONF_VERSION=2.3.1
ARG PDF_PLAYWRIGHT_CORE_VERSION=1.63.0
ARG PAGEDJS_VERSION=0.4.3
ARG KATEX_VERSION=0.18.7
ARG MERMAID_VERSION=11.17.2
ARG TECTONIC_VERSION=0.17.0
ARG TECTONIC_SHA256_AMD64=8533d07f9ccbd7a65824b9e0459041bca34af1eb33daba48f59215593753a3b7
ARG TECTONIC_SHA256_ARM64=b10954a95404f3ab2328d2fa59a5ebab8e657f893fab096f98be8db7c0c979b8
ARG ONNXRUNTIME_VERSION=1.27.0
ARG OPENCV_PYTHON_VERSION=4.12.0.88
ARG OPENPYXL_VERSION=3.1.5
ARG PILLOW_VERSION=12.3.0
ARG PANDAS_VERSION=3.0.5
ARG SCIPY_VERSION=1.18.1
ARG SCIKIT_LEARN_VERSION=1.9.0
ARG MARKITDOWN_VERSION=0.1.6
ARG DOCX_VERSION=9.7.1
ARG PYTHON_DOCX_VERSION=1.2.0
ARG LXML_VERSION=6.1.1
ARG DEFUSEDXML_VERSION=0.7.1
ARG PPTXGENJS_VERSION=4.0.1
ARG REACT_VERSION=19.2.8
ARG REACT_DOM_VERSION=19.2.8
ARG REACT_ICONS_VERSION=5.7.0
ARG SHARP_VERSION=0.35.3
ARG PYTHON_PPTX_VERSION=1.0.2

RUN --mount=type=cache,id=silk-base-runtime-apt-cache-${TARGETPLATFORM},target=/var/cache/apt,sharing=locked \
  --mount=type=cache,id=silk-base-runtime-apt-lib-${TARGETPLATFORM},target=/var/lib/apt,sharing=locked \
  --mount=type=cache,id=silk-base-npm-${TARGETPLATFORM},target=/root/.npm \
  rm -f /etc/apt/apt.conf.d/docker-clean && \
  sed -i 's/^Components: main$/Components: main contrib/' /etc/apt/sources.list.d/debian.sources && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates curl ffmpeg git ripgrep unzip zip xz-utils \
  tzdata \
  chromium \
  fontconfig fonts-noto-cjk fonts-noto-color-emoji fonts-inter fonts-liberation \
  fonts-crosextra-caladea fonts-crosextra-carlito ttf-mscorefonts-installer \
  python3 python3-venv python3-pip \
  libgomp1 libgl1 libglib2.0-0t64 \
  pandoc \
  poppler-utils poppler-data \
  libreoffice-calc-nogui libreoffice-writer-nogui libreoffice-impress-nogui \
  && curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nodejs \
  && npm install -g \
  tsx@${TSX_VERSION} \
  docx@${DOCX_VERSION} \
  pptxgenjs@${PPTXGENJS_VERSION} \
  react@${REACT_VERSION} \
  react-dom@${REACT_DOM_VERSION} \
  react-icons@${REACT_ICONS_VERSION} \
  sharp@${SHARP_VERSION} \
  && npm install -g --ignore-scripts --no-audit --no-fund \
  playwright-core@${PDF_PLAYWRIGHT_CORE_VERSION} \
  pagedjs@${PAGEDJS_VERSION} \
  katex@${KATEX_VERSION} \
  mermaid@${MERMAID_VERSION} \
  && corepack enable \
  && curl -fsSL https://bun.sh/install | env BUN_INSTALL=/usr/local bash \
  && curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL=/usr/local/bin sh \
  && command -v bun >/dev/null \
  && command -v bunx >/dev/null \
  && command -v uv >/dev/null \
  && command -v uvx >/dev/null \
  && ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
  && echo Asia/Shanghai > /etc/timezone

# Typst 官方固定版本；按目标架构安装静态二进制，不增加 Rust 构建依赖。
RUN set -eu; \
  case "${TARGETARCH}" in \
    amd64) typst_target=x86_64-unknown-linux-musl ;; \
    arm64) typst_target=aarch64-unknown-linux-musl ;; \
    *) echo "Unsupported Typst architecture: ${TARGETARCH}" >&2; exit 1 ;; \
  esac; \
  curl -fL --retry 3 --proto '=https' --proto-redir '=https' \
    "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-${typst_target}.tar.xz" \
    -o /tmp/typst.tar.xz; \
  mkdir -p /tmp/typst /usr/local/share/doc/typst; \
  tar -xJf /tmp/typst.tar.xz -C /tmp/typst --strip-components=1; \
  install -m 0755 /tmp/typst/typst /usr/local/bin/typst; \
  install -m 0644 /tmp/typst/LICENSE /tmp/typst/NOTICE /usr/local/share/doc/typst/; \
  typst --version; \
  rm -rf /tmp/typst /tmp/typst.tar.xz

# CTAN Fandol 0.3：宋、黑、楷、仿宋风格；保留真实家族名和许可证。
# 使用固定 HTTPS 镜像并在失败时切换，避免自动跳转到证书链异常的镜像。
RUN set -eu; \
  fandol_downloaded=0; \
  for fandol_url in \
    https://ftp.fau.de/ctan/fonts/fandol.zip \
    https://mirrors.tuna.tsinghua.edu.cn/CTAN/fonts/fandol.zip; do \
    echo "Downloading Fandol from ${fandol_url}"; \
    if curl -fL --retry 2 --connect-timeout 20 --max-time 300 \
      --proto '=https' --proto-redir '=https' \
      "${fandol_url}" -o /tmp/fandol.zip \
      && echo "${FANDOL_SHA256}  /tmp/fandol.zip" | sha256sum -c -; then \
      fandol_downloaded=1; \
      break; \
    fi; \
    echo "Fandol download or checksum failed: ${fandol_url}" >&2; \
    rm -f /tmp/fandol.zip; \
  done; \
  if [ "${fandol_downloaded}" -ne 1 ]; then \
    echo "Unable to download a verified Fandol archive from all configured mirrors." >&2; \
    exit 1; \
  fi; \
  unzip -q /tmp/fandol.zip -d /tmp/fandol-fonts; \
  mkdir -p /usr/local/share/fonts/fandol /usr/local/share/doc/fandol; \
  install -m 0644 /tmp/fandol-fonts/fandol/*.otf /usr/local/share/fonts/fandol/; \
  install -m 0644 /tmp/fandol-fonts/fandol/COPYING /tmp/fandol-fonts/fandol/README /usr/local/share/doc/fandol/; \
  rm -rf /tmp/fandol.zip /tmp/fandol-fonts

# 已授权的原版中文字体：固定来源版本，并逐文件校验 SHA-256。
COPY fonts/cjk-fonts.tsv /tmp/cjk-fonts.tsv
RUN set -eu; \
  mkdir -p /usr/local/share/fonts/windows-cjk /usr/local/share/doc/windows-cjk; \
  while read -r font_sha font_name font_url; do \
    curl -fL --retry 3 --connect-timeout 20 --max-time 300 --proto '=https' --proto-redir '=https' \
      "${font_url}" -o "/tmp/${font_name}"; \
    echo "${font_sha}  /tmp/${font_name}" | sha256sum -c -; \
    install -m 0644 "/tmp/${font_name}" /usr/local/share/fonts/windows-cjk/; \
    rm -f "/tmp/${font_name}"; \
  done < /tmp/cjk-fonts.tsv; \
  install -m 0644 /tmp/cjk-fonts.tsv /usr/local/share/doc/windows-cjk/sources.tsv; \
  rm -f /tmp/cjk-fonts.tsv

# 已授权的苹果风格字体：苹方 SC 用于简体中文，SF Pro 用于英文和数字。
COPY fonts/apple-fonts.tsv /tmp/apple-fonts.tsv
RUN set -eu; \
  mkdir -p /usr/local/share/fonts/apple /usr/local/share/doc/apple-fonts; \
  while read -r font_sha font_name font_url; do \
    curl -fL --retry 3 --connect-timeout 20 --max-time 300 --proto '=https' --proto-redir '=https' \
      "${font_url}" -o "/tmp/${font_name}"; \
    echo "${font_sha}  /tmp/${font_name}" | sha256sum -c -; \
    install -m 0644 "/tmp/${font_name}" /usr/local/share/fonts/apple/; \
    rm -f "/tmp/${font_name}"; \
  done < /tmp/apple-fonts.tsv; \
  install -m 0644 /tmp/apple-fonts.tsv /usr/local/share/doc/apple-fonts/sources.tsv; \
  rm -f /tmp/apple-fonts.tsv

# 额外的机构字体可放在构建上下文 custom-fonts/ 中。
COPY custom-fonts/ /usr/local/share/fonts/custom/
RUN set -eu; \
  fc-cache -f; \
  fc-list --format '%{family}\n' > /tmp/document-fonts.txt; \
  for family in 'Arial' 'Times New Roman' 'FandolSong' 'FandolHei' 'FandolKai' 'FandolFang' \
    'SimSun' 'SimHei' 'FangSong' 'KaiTi' 'Microsoft YaHei' 'Microsoft YaHei UI' '方正小标宋简体' 'PingFang SC' 'SF Pro'; do \
    grep -Eq "(^|,)${family}(,|$)" /tmp/document-fonts.txt || { echo "Missing font: ${family}" >&2; exit 1; }; \
  done; \
  rm -f /tmp/document-fonts.txt

# 基础运行环境变量（减少 Python 缓冲 & 关闭 pip 缓存）
ENV PYTHONUNBUFFERED=1 \
  PIP_NO_CACHE_DIR=1 \
  VIRTUAL_ENV="/opt/venv" \
  TZ=Asia/Shanghai \
  CHROME_BIN=/usr/bin/chromium \
  CHROME_PATH=/usr/bin/chromium \
  TECTONIC_CACHE_DIR=/opt/tectonic-cache \
  BUN_INSTALL="/usr/local" \
  NODE_PATH="/usr/local/lib/node_modules:/usr/lib/node_modules" \
  PATH="/opt/venv/bin:/usr/local/bin:/root/.cargo/bin:$PATH"

# PDF 解析、生成、表单处理、页面渲染和本地 OCR 依赖
RUN --mount=type=cache,id=silk-base-uv-${TARGETPLATFORM},target=/root/.cache/uv,sharing=locked \
  uv venv "${VIRTUAL_ENV}" --python python3 \
  && uv pip install --python "${VIRTUAL_ENV}/bin/python" \
  "pdfplumber==${PDFPLUMBER_VERSION}" \
  "pypdf==${PYPDF_VERSION}" \
  "reportlab==${REPORTLAB_VERSION}" \
  "rapidocr==${RAPIDOCR_VERSION}" \
  "omegaconf==${OMEGACONF_VERSION}" \
  "onnxruntime==${ONNXRUNTIME_VERSION}" \
  "opencv-python==${OPENCV_PYTHON_VERSION}" \
  && "${VIRTUAL_ENV}/bin/python" -c "import cv2, onnxruntime, pdfplumber, pypdf, reportlab; from rapidocr import RapidOCR; RapidOCR(); print('PDF and OCR dependencies OK')" \
  && command -v pdftoppm >/dev/null \
  && command -v pdfinfo >/dev/null \
  && test -s /usr/share/poppler/cMap/Adobe-GB1/UniGB-UTF16-H \
  && test -s /usr/share/poppler/cidToUnicode/Adobe-GB1

# PDF 设计使用已有系统 Chromium，所有分页/公式/流程图资源从本地包加载。
COPY pdf-runtime/design-smoke.cjs /tmp/pdf-design-smoke.cjs
RUN node /tmp/pdf-design-smoke.cjs && rm -f /tmp/pdf-design-smoke.cjs

# LaTeX 固定编译器：双架构静态发行包、SHA-256 校验，不执行远程安装脚本。
RUN set -eu; \
  case "${TARGETARCH}" in \
    amd64) tectonic_target=x86_64-unknown-linux-musl; tectonic_sha="${TECTONIC_SHA256_AMD64}" ;; \
    arm64) tectonic_target=aarch64-unknown-linux-musl; tectonic_sha="${TECTONIC_SHA256_ARM64}" ;; \
    *) echo "Unsupported Tectonic architecture: ${TARGETARCH}" >&2; exit 1 ;; \
  esac; \
  curl -fL --retry 3 --connect-timeout 20 --max-time 300 --proto '=https' --proto-redir '=https' \
    "https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%40${TECTONIC_VERSION}/tectonic-${TECTONIC_VERSION}-${tectonic_target}.tar.gz" \
    -o /tmp/tectonic.tar.gz; \
  echo "${tectonic_sha}  /tmp/tectonic.tar.gz" | sha256sum -c -; \
  mkdir -p /tmp/tectonic; \
  tar -xzf /tmp/tectonic.tar.gz -C /tmp/tectonic; \
  install -m 0755 /tmp/tectonic/tectonic /usr/local/bin/tectonic; \
  tectonic --version; \
  rm -rf /tmp/tectonic /tmp/tectonic.tar.gz

# 构建时预热常用中文/数学/图表/链接包；任务脚本只允许 --only-cached。
COPY pdf-runtime/latex-smoke.tex /tmp/pdf-latex-smoke.tex
RUN set -eu; \
  mkdir -p "${TECTONIC_CACHE_DIR}" /tmp/pdf-latex-check; \
  tectonic --untrusted --outdir /tmp/pdf-latex-check /tmp/pdf-latex-smoke.tex; \
  tectonic --untrusted --only-cached --outdir /tmp/pdf-latex-check /tmp/pdf-latex-smoke.tex; \
  "${VIRTUAL_ENV}/bin/python" -c "from pypdf import PdfReader; assert len(PdfReader('/tmp/pdf-latex-check/pdf-latex-smoke.pdf').pages) == 1; print('LaTeX cached resources OK')"; \
  pdftotext /tmp/pdf-latex-check/pdf-latex-smoke.pdf /tmp/pdf-latex-check/text.txt; \
  "${VIRTUAL_ENV}/bin/python" -c "from pathlib import Path; text = ''.join(Path('/tmp/pdf-latex-check/text.txt').read_text().split()); assert '中文排版验证' in text and '1234567890' in text; print('Chinese PDF mappings OK')"; \
  chmod -R a+rX "${TECTONIC_CACHE_DIR}"; \
  rm -rf /tmp/pdf-latex-check /tmp/pdf-latex-smoke.tex

# xlsx 读写/重算沿用原工具链；SciPy 和 scikit-learn 补充模型与优化求解。
RUN --mount=type=cache,id=silk-base-uv-${TARGETPLATFORM},target=/root/.cache/uv,sharing=locked \
  uv pip install --python "${VIRTUAL_ENV}/bin/python" --only-binary scipy,scikit-learn \
  "openpyxl==${OPENPYXL_VERSION}" \
  "Pillow==${PILLOW_VERSION}" \
  "pandas==${PANDAS_VERSION}" \
  "scipy==${SCIPY_VERSION}" \
  "scikit-learn==${SCIKIT_LEARN_VERSION}" \
  "markitdown[xlsx]==${MARKITDOWN_VERSION}" \
  && "${VIRTUAL_ENV}/bin/python" -c "import openpyxl, pandas; from PIL import Image; from markitdown import MarkItDown" \
  && "${VIRTUAL_ENV}/bin/python" -c "from scipy.optimize import milp; from sklearn.linear_model import LinearRegression; assert milp([1.0], integrality=[1]).success; model = LinearRegression().fit([[0.0], [1.0]], [0.0, 2.0]); assert abs(model.predict([[2.0]])[0] - 4.0) < 1e-8; print('xlsx modeling dependencies OK')" \
  && command -v markitdown >/dev/null \
  && command -v soffice >/dev/null

# Anthropic docx skill 的读取、创建、XML 校验和渲染依赖
RUN --mount=type=cache,id=silk-base-uv-${TARGETPLATFORM},target=/root/.cache/uv,sharing=locked \
  uv pip install --python "${VIRTUAL_ENV}/bin/python" \
  "python-docx==${PYTHON_DOCX_VERSION}" \
  "lxml==${LXML_VERSION}" \
  "defusedxml==${DEFUSEDXML_VERSION}" \
  && "${VIRTUAL_ENV}/bin/python" -c "import defusedxml, docx, lxml.etree; from docx import Document; Document()" \
  && node -e "require('docx')" \
  && command -v pandoc >/dev/null \
  && command -v zip >/dev/null \
  && command -v soffice >/dev/null \
  && command -v pdftoppm >/dev/null

# PPTX skill 的创建、读取、图标渲染、结构校验和逐页预览依赖
RUN --mount=type=cache,id=silk-base-uv-${TARGETPLATFORM},target=/root/.cache/uv,sharing=locked \
  uv pip install --python "${VIRTUAL_ENV}/bin/python" \
  "markitdown[pptx]==${MARKITDOWN_VERSION}" \
  "python-pptx==${PYTHON_PPTX_VERSION}" \
  && "${VIRTUAL_ENV}/bin/python" -c "import defusedxml, lxml.etree, pptx; from PIL import Image; from markitdown import MarkItDown; from pptx import Presentation; Presentation()" \
  && node -e "require('pptxgenjs'); require('react'); require('react-dom/server'); require('react-icons/fi'); require('sharp')" \
  && command -v soffice >/dev/null \
  && command -v pdftoppm >/dev/null

# 搬运编译好的二进制和脚本
COPY --from=builder /src/silk/decoder          /usr/local/bin/silk/decoder
COPY --from=builder /src/silk/encoder          /usr/local/bin/silk/encoder
COPY --from=builder /src/converter.sh          /usr/local/bin/silk-converter

# 赋可执行权限
RUN chmod +x /usr/local/bin/silk/decoder /usr/local/bin/silk/encoder /usr/local/bin/silk-converter

# 可选：将 converter.sh 作为默认入口，也方便在其它镜像里直接调用
ENTRYPOINT ["/usr/local/bin/silk-converter"]
