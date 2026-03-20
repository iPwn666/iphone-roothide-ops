# WireGuard Notes

## Why keep it

WireGuard is the most reliable fallback when:

- USB forwarding disappears
- localhost SSH mapping breaks
- the phone moves off the local Wi-Fi

## Practical expectations

- keep the tunnel import stored on the phone
- keep a dedicated SSH alias for the tunnel address
- prefer key auth instead of passwords

## Operational rule

After a respring or userspace restart, verify the tunnel first. Only then debug SSH or package-manager behavior.
