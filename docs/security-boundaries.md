# Security Boundaries

This repo intentionally avoids publishing or automating:

- iCloud or activation-lock bypasses
- account-state tampering for Apple services
- forged eligibility or model unlock workflows
- anything that depends on publishing private keys or personal access secrets

## Safer alternatives

- read-only auditing
- reversible plist changes
- explicit backups before edits
- local-only secret injection through environment variables

