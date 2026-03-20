# MCP And Host Tooling

## Linux-safe MCP stack

- filesystem
- memory
- github
- playwright
- chrome devtools
- official OpenAI docs MCP
- optional local CUA server

## What not to enable on Linux

Apple-focused MCP servers that depend on AppleScript, JXA, or macOS system apps are not good fits for a Linux host.

## Useful host utilities

- `tmux`
- `autossh`
- `iproxy`
- `tidevice`
- `pymobiledevice3`
- `frida-tools`
- `wireguard-tools`
- `kdeconnect-cli`

## Why this matters

The host stack should make remote phone maintenance easier, not more fragile. Keep the tooling practical and cross-platform where possible.

