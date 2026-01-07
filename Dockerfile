# --- 第一阶段：构建/获取二进制文件 ---
FROM alpine:latest AS fetcher
RUN apk add --no-cache curl unzip
RUN curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip /tmp/xray.zip -d /tmp/xray-files

# --- 第二阶段：最终运行环境 ---
# 使用 static-debian11，仅包含基础的 SSL 证书和用户组信息
FROM gcr.io/distroless/static-debian11

# 复制 Xray 二进制文件
COPY --from=fetcher /tmp/xray-files/xray /usr/bin/xray

# 复制路由分流所需的地理数据 (必备)
COPY --from=fetcher /tmp/xray-files/geoip.dat /usr/bin/geoip.dat
COPY --from=fetcher /tmp/xray-files/geosite.dat /usr/bin/geosite.dat

# 设置环境变量，告知 Xray 资源文件位置
ENV XRAY_LOCATION_ASSET=/usr/bin

# Distroless 默认不以 root 运行，增强安全性 (可选)
USER nonroot:nonroot

# 启动命令
ENTRYPOINT ["/usr/bin/xray", "run", "-config", "/etc/xray/config.json"]