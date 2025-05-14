FROM rust:slim

ARG CLANG_VERSION=20

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    libssl-dev \
    gnupg \
    lsb-release \
    wget \
    --no-install-recommends

RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-${CLANG_VERSION} main" >> /etc/apt/sources.list.d/llvm.list && \
    apt-get update && apt-get install -y clang-${CLANG_VERSION} && \
    ln -s /usr/bin/clang-${CLANG_VERSION} /usr/bin/clang && \
    ln -s /usr/bin/clang++-${CLANG_VERSION} /usr/bin/clang++ && \
    rm -rf /var/lib/apt/lists/*

RUN curl -s https://packagecloud.io/install/repositories/wasmcloud/core/script.deb.sh | bash && \
    apt-get install -y wash && \
    rm -rf /var/lib/apt/lists/*

ENV CARGO_REGISTRIES_SEAMLEZZ_INDEX=sparse+https://git.seamlezz.com/api/packages/Seamlezz/cargo/

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN rustup target add wasm32-wasip2 && \
    rustup target add wasm32-unknown-unknown

RUN cargo build --release --locked

ENTRYPOINT ["/app/target/release/developer-watcher"]

