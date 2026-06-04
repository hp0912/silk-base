# ────────────────────────
#  1️⃣ 编译阶段
# ────────────────────────
FROM debian:stable AS builder

# 依赖：gcc / make 以及 ffmpeg（便于在编译镜像里自测）
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
  build-essential \
  ffmpeg \
  && rm -rf /var/lib/apt/lists/*

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

ARG NODE_MAJOR=24
ARG TSX_VERSION=latest

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates curl ffmpeg git unzip \
  tzdata \
  chromium \
  fontconfig fonts-noto-cjk fonts-noto-color-emoji fonts-inter \
  python3 python3-venv python3-pip \
  && curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nodejs \
  && npm install -g tsx@${TSX_VERSION} \
  && corepack enable \
  && curl -fsSL https://bun.sh/install | bash \
  && curl -LsSf https://astral.sh/uv/install.sh | sh \
  && ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
  && echo Asia/Shanghai > /etc/timezone \
  && rm -rf /var/lib/apt/lists/*

# 基础运行环境变量（减少 Python 缓冲 & 关闭 pip 缓存）
ENV PYTHONUNBUFFERED=1 \
  PIP_NO_CACHE_DIR=1 \
  TZ=Asia/Shanghai \
  CHROME_BIN=/usr/bin/chromium \
  CHROME_PATH=/usr/bin/chromium \
  BUN_INSTALL="/root/.bun" \
  PATH="/root/.bun/bin:/root/.local/bin:/root/.cargo/bin:$PATH"

# 搬运编译好的二进制和脚本
COPY --from=builder /src/silk/decoder          /usr/local/bin/silk/decoder
COPY --from=builder /src/silk/encoder          /usr/local/bin/silk/encoder
COPY --from=builder /src/converter.sh          /usr/local/bin/silk-converter

# 赋可执行权限
RUN chmod +x /usr/local/bin/silk/decoder /usr/local/bin/silk/encoder /usr/local/bin/silk-converter

# 可选：将 converter.sh 作为默认入口，也方便在其它镜像里直接调用
ENTRYPOINT ["/usr/local/bin/silk-converter"]