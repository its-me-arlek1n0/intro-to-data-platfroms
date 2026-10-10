#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source env.sh

# На edge каждому интерфейсу нужен отдельный локальный порт.
forwards=""
while IFS=$'\t' read -r id service host backend port page; do
  [[ -z "$id" || "$id" == \#* ]] && continue
  curl --noproxy '*' -fsSL --connect-timeout 3 --max-time 10 "http://$host:$backend$page" >/dev/null
  forwards="$forwards -L 127.0.0.1:$port:$host:$backend"
done < config/web-interfaces.tsv

# systemd держит SSH-туннель edge -> внутренние узлы после выхода из SSH.
mkdir -p "$HOME/.config/systemd/user"
unit="$HOME/.config/systemd/user/hdfs-hw2-web.service"
candidate=$(mktemp)
trap 'rm -f "$candidate"' EXIT
cat > "$candidate" <<EOF
[Unit]
Description=HDFS HW2 all daemon web interfaces over SSH
[Service]
ExecStart=/usr/bin/ssh -NT -i "$SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=10 -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3$forwards $SSH_USER@$RESOURCE_MANAGER
Restart=on-failure
RestartSec=5
[Install]
WantedBy=default.target
EOF

if [ "$(loginctl show-user "$USER" -p Linger --value)" != yes ]; then
  sudo -n loginctl enable-linger "$USER"
fi
if ! cmp -s "$candidate" "$unit"; then
  cp "$candidate" "$unit"
  systemctl --user daemon-reload
  systemctl --user restart hdfs-hw2-web.service
fi
systemctl --user enable --now hdfs-hw2-web.service
systemctl --user is-active hdfs-hw2-web.service
