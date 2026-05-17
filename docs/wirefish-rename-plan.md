# WireFish → Novolis.Transports.WireFish

**Status:** Completed — library lives in [novolis-transports](https://github.com/Novolis-Platform/novolis-transports).

| Former | Current |
|--------|---------|
| `novolis-wirefish` repo | Redirect only; implementation in `novolis-transports` |
| `Frank.WireFish` package id | `Novolis.Transports.WireFish` |
| `Frank.WireFish` namespace | `Novolis.Transports.WireFish` (obsolete `Frank.WireFish` aliases in-package) |

## Rationale

Packet capture is a **transport-layer** concern (adapters, live I/O, channels), alongside TCP and HTTP clients. A dedicated unpublished repo added navigation cost without a separate release lifecycle.

## Consumer migration

1. Replace project/package reference `Frank.WireFish` → `Novolis.Transports.WireFish`.
2. Update usings to `Novolis.Transports.WireFish`.
3. Replace `AddWireFish` with `AddNovolisWireFish` (optional `WireFishOptions` for BPF/device filter).
4. Remove dependency on `novolis-wirefish` repo path in multi-repo checkouts.
