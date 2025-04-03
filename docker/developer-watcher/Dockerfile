FROM rust:slim

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    libssl-dev \
    gnupg \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

RUN curl -s https://packagecloud.io/install/repositories/wasmcloud/core/script.deb.sh | bash && \
    apt-get install -y wash && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1001 appuser && \
    useradd --uid 1001 --gid 1001 --shell /bin/bash --create-home appuser && \
    mkdir -p /home/appuser/.cargo && \
    chown -R appuser:appuser /home/appuser

ENV CARGO_HOME=/home/appuser/.cargo
ENV PATH="/home/appuser/.cargo/bin:${PATH}"

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN chown -R appuser:appuser /app

USER appuser

RUN rustup target add wasm32-wasip2 && \
    rustup target add wasm32-unknown-unknown

RUN cargo build --release --locked

ENTRYPOINT ["/app/target/release/developer-watcher"]