# Pythonista Workflow

Pythonista is useful when SSH is temporarily unavailable but you still need a phone-side script runner.

## Good uses

- restore `authorized_keys`
- inspect sandbox-visible paths
- run small diagnostics
- write quick recovery output to `Documents`

## Best practice

- keep scripts small and explicit
- write results to a text or JSON file in `Documents`
- do not hardcode private keys or tokens into the script body
- prefer environment variables or manual paste-in for secrets

## Recovery pattern

1. open Pythonista in the foreground
2. run a minimal script that writes diagnostics and updates a target file
3. verify output in a companion `.txt` or `.json` file
4. switch back to SSH as soon as access is restored

