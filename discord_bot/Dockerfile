FROM rust:1.86 as builder

WORKDIR /usr/src/app

COPY Cargo.toml Cargo.lock ./
RUN mkdir -p src && echo "fn main() {}" > src/main.rs
RUN cargo fetch
RUN cargo build --release
RUN rm -rf src

COPY . .

RUN cargo install --path .

FROM debian:bookworm-slim
RUN apt-get update && \
    apt-get install -y openssl libssl-dev ca-certificates && \
    rm -rf /var/lib/apt/lists/*
RUN /usr/sbin/update-ca-certificates
COPY --from=builder /usr/local/cargo/bin/discord_bot /usr/local/bin/discord_bot
ENV RUST_LOG="discord_bot=debug"
CMD ["discord_bot"]
