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
ARG NODE_MAJOR=24
ARG TSX_VERSION=latest
ARG PDFPLUMBER_VERSION=0.11.9
ARG PYPDF_VERSION=6.10.0
ARG REPORTLAB_VERSION=4.4.9
ARG RAPIDOCR_VERSION=3.9.1
ARG ONNXRUNTIME_VERSION=1.27.0
ARG OPENCV_PYTHON_VERSION=4.12.0.88
ARG OPENPYXL_VERSION=3.1.5
ARG PILLOW_VERSION=12.3.0
ARG PANDAS_VERSION=3.0.5
ARG MARKITDOWN_VERSION=0.1.6
ARG DOCX_VERSION=9.7.1
ARG PYTHON_DOCX_VERSION=1.2.0
ARG LXML_VERSION=6.1.1
ARG DEFUSEDXML_VERSION=0.7.1

RUN --mount=type=cache,id=silk-base-runtime-apt-cache-${TARGETPLATFORM},target=/var/cache/apt,sharing=locked \
  --mount=type=cache,id=silk-base-runtime-apt-lib-${TARGETPLATFORM},target=/var/lib/apt,sharing=locked \
  --mount=type=cache,id=silk-base-npm-${TARGETPLATFORM},target=/root/.npm \
  rm -f /etc/apt/apt.conf.d/docker-clean && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates curl ffmpeg git ripgrep unzip zip \
  tzdata \
  chromium \
  fontconfig fonts-noto-cjk fonts-noto-color-emoji fonts-inter fonts-liberation \
  fonts-crosextra-caladea fonts-crosextra-carlito \
  python3 python3-venv python3-pip \
  libgomp1 libgl1 libglib2.0-0t64 \
  pandoc \
  poppler-utils \
  libreoffice-calc-nogui libreoffice-writer-nogui \
  && curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nodejs \
  && npm install -g tsx@${TSX_VERSION} docx@${DOCX_VERSION} \
  && corepack enable \
  && curl -fsSL https://bun.sh/install | bash \
  && curl -LsSf https://astral.sh/uv/install.sh | sh \
  && ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
  && echo Asia/Shanghai > /etc/timezone

# 基础运行环境变量（减少 Python 缓冲 & 关闭 pip 缓存）
ENV PYTHONUNBUFFERED=1 \
  PIP_NO_CACHE_DIR=1 \
  VIRTUAL_ENV="/opt/venv" \
  TZ=Asia/Shanghai \
  CHROME_BIN=/usr/bin/chromium \
  CHROME_PATH=/usr/bin/chromium \
  BUN_INSTALL="/root/.bun" \
  NODE_PATH="/usr/local/lib/node_modules:/usr/lib/node_modules" \
  PATH="/opt/venv/bin:/root/.bun/bin:/root/.local/bin:/root/.cargo/bin:$PATH"

# PDF 解析、生成、表单处理、页面渲染和本地 OCR 依赖
RUN --mount=type=cache,id=silk-base-uv-${TARGETPLATFORM},target=/root/.cache/uv,sharing=locked \
  uv venv "${VIRTUAL_ENV}" --python python3 \
  && uv pip install --python "${VIRTUAL_ENV}/bin/python" \
  "pdfplumber==${PDFPLUMBER_VERSION}" \
  "pypdf==${PYPDF_VERSION}" \
  "reportlab==${REPORTLAB_VERSION}" \
  "rapidocr==${RAPIDOCR_VERSION}" \
  "onnxruntime==${ONNXRUNTIME_VERSION}" \
  "opencv-python==${OPENCV_PYTHON_VERSION}" \
  && "${VIRTUAL_ENV}/bin/python" -c "import cv2, onnxruntime, pdfplumber, pypdf, reportlab; from rapidocr import RapidOCR; RapidOCR(); print('PDF and OCR dependencies OK')" \
  && command -v pdftoppm >/dev/null \
  && command -v pdfinfo >/dev/null

# Anthropic xlsx skill 的 Python 运行时和公式重算依赖
RUN --mount=type=cache,id=silk-base-uv-${TARGETPLATFORM},target=/root/.cache/uv,sharing=locked \
  uv pip install --python "${VIRTUAL_ENV}/bin/python" \
  "openpyxl==${OPENPYXL_VERSION}" \
  "Pillow==${PILLOW_VERSION}" \
  "pandas==${PANDAS_VERSION}" \
  "markitdown[xlsx]==${MARKITDOWN_VERSION}" \
  && "${VIRTUAL_ENV}/bin/python" -c "import openpyxl, pandas; from PIL import Image; from markitdown import MarkItDown" \
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

# 搬运编译好的二进制和脚本
COPY --from=builder /src/silk/decoder          /usr/local/bin/silk/decoder
COPY --from=builder /src/silk/encoder          /usr/local/bin/silk/encoder
COPY --from=builder /src/converter.sh          /usr/local/bin/silk-converter

# 赋可执行权限
RUN chmod +x /usr/local/bin/silk/decoder /usr/local/bin/silk/encoder /usr/local/bin/silk-converter

# 可选：将 converter.sh 作为默认入口，也方便在其它镜像里直接调用
ENTRYPOINT ["/usr/local/bin/silk-converter"]
