#!/bin/sh
set -eu

if [ -z "${SSH_PUBLIC_KEY:-}" ]; then
  echo "Set SSH_PUBLIC_KEY before running this script."
  exit 1
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
grep -qxF "$SSH_PUBLIC_KEY" "$HOME/.ssh/authorized_keys" || printf '%s\n' "$SSH_PUBLIC_KEY" >> "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"

echo "SSH key installed for $(id -un)"
