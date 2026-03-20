# Package Manager Notes

## Goals

- keep `apt-get update` and `apt-get check` clean
- avoid parse failures from broken third-party repos
- prefer a small trusted source set over dozens of stale legacy repos

## Minimal working source strategy

Recommended active sources:

- `https://apt.procurs.us/`
- `https://repo.chariz.com/`
- `https://havoc.app/`

Everything else should be justified by an installed package that you actively want to update.

## Practical rules

- back up `sources.list.d/*.sources` before changing anything
- clear stale list caches after large source-set changes
- disable `Acquire::Languages` to avoid useless translation fetches
- treat unsigned or malformed legacy repos as optional, not foundational

## Useful commands

```bash
apt-get update
apt-get check
apt list --upgradable
dpkg-query -W
```

## When to remove a repo

Remove or disable a repo if it does any of the following:

- breaks APT parsing
- returns `NOSPLIT`, `403`, or invalid metadata
- serves only old tweak variants you do not need to update
- duplicates packages already covered by a cleaner repo

