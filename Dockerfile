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
RUN make && make decoder

# ────────────────────────
#  2️⃣ 运行阶段（最终基础镜像）
# ────────────────────────
FROM debian:stable-slim AS silk-base

# 只保留运行所需的 ffmpeg（及其依赖）
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends ffmpeg \
  && rm -rf /var/lib/apt/lists/*

# 搬运编译好的二进制和脚本
COPY --from=builder /src/silk/decoder          /usr/local/bin/silk-decoder
COPY --from=builder /src/converter.sh          /usr/local/bin/silk-convert

# 赋可执行权限
RUN chmod +x /usr/local/bin/silk-decoder /usr/local/bin/silk-convert

# 可选：将 converter.sh 作为默认入口，也方便在其它镜像里直接调用
ENTRYPOINT ["/usr/local/bin/silk-convert"]