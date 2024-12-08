# FROM python:3.11 as builder
# FROM python:3.11-slim as builder
FROM ubuntu:25.04

# 指定构建过程中的工作目录
WORKDIR /app

RUN apt-get update -y && \
    apt-get install --no-install-recommends -y g++ ffmpeg tesseract-ocr cmake libavformat-dev libavfilter-dev libavdevice-dev libssl-dev libtesseract-dev libxdo-dev libsdl2-dev libclang-dev libxtst-dev  && \
    rm -rf /var/lib/apt/lists/* 

# Install rust
RUN apt-get update -qq && \
    curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path --profile minimal && \
    ln -s $HOME/.cargo/bin/cargo /usr/local/bin && \
    ln -s $HOME/.cargo/bin/rustup /usr/local/bin && \
    rustup install 1.83.0

# Install screenpipe
RUN apt-get update -qq && \
    apt-get install -qq libasound2-dev libavdevice-dev libavfilter-dev libavformat-dev libclang-16-dev libtesseract-dev tesseract-ocr libxdo-dev libxtst-dev && \
    git clone --depth 1 https://github.com/mediar-ai/screenpipe /opt/screenpipe && \
    cd /opt/screenpipe && \
    cargo build --release && \
    install target/release/screenpipe /usr/local/bin

# Install screenpipe ui
RUN apt-get update -qq && \
    apt-get install -qq libappindicator3-dev && \
    cd /opt/screenpipe/screenpipe-app-tauri && \
    npm install bun && \
    npx bun install && \
    npx bun scripts/pre_build.js >/dev/null && \
    PATH=$HOME/.cargo/bin:$PATH npx bun tauri build || true

# 将当前目录（dockerfile所在目录）下所有文件都拷贝到工作目录下（.dockerignore中文件除外）
COPY . /app/

# FROM python:3.11
# FROM python:3.11-slim
FROM ubuntu:25.04
# 引入存了镜像加速构建

# 指定运行时的工作目录
WORKDIR /app

# 将构建产物/app/main拷贝到运行时的工作目录中
# COPY --from=builder /app/main /app/index.html /app/
COPY --from=builder /opt/screenpipe/target/release/screenpipe /app/screenpipe
COPY --from=builder /opt/screenpipe/target/release/screenpipe /app/screenpipe

COPY --from=builder /app/ /app/
COPY --from=builder /opt/ /opt/

EXPOSE 8000
 
CMD ["screenpipe"]