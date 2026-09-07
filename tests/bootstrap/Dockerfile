FROM debian:trixie-slim
RUN apt-get update && apt-get install -y --no-install-recommends sudo ca-certificates curl git xz-utils unzip && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --shell /bin/bash tester \
    && echo 'tester ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/tester \
    && chmod 0440 /etc/sudoers.d/tester
COPY --chown=tester:tester . /home/tester/dotfiles
USER tester
ENV HOME=/home/tester USER=tester LOGNAME=tester SHELL=/bin/bash MISE_ENV=container MISE_YES=1
ENV PATH=/home/tester/.local/bin:/home/tester/.local/share/mise/shims:/home/tester/.cargo/bin:/usr/local/bin:/usr/bin:/bin
WORKDIR /home/tester/dotfiles
CMD ["bash", "tests/bootstrap/acceptance.sh"]
