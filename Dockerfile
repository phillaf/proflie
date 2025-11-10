FROM rust:1.83 as builder
WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
WORKDIR /app

# Create non-root user
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

COPY --from=builder --chown=appuser:appuser /app/target/release/proflie-rust .

USER appuser
EXPOSE 3000 
CMD ["./proflie-rust"]
