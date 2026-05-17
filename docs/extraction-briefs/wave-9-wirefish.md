# Wave 9 — Frank.WireFish

**Target repo:** [novolis-wirefish](https://github.com/Novolis-Platform/novolis-wirefish)  
**Source:** [frankhaugen/Frank.WireFish](https://github.com/frankhaugen/Frank.WireFish)  
**Package id (unchanged):** `Frank.WireFish`

## Scope

| In | Out |
|----|-----|
| `Frank.WireFish` library (SharpPcap capture + channel dispatch) | Samples (`Frank.WireFishApp`, `PacketScroller`) — defer to `samples/` or personal repo |
| TUnit smoke + extension unit tests | Live-capture integration tests until Npcap CI story |
| `Novolis.Messaging.Channels` instead of `Frank.Channels.DependencyInjection` | Renaming package to `Novolis.WireFish` |

## Dependencies

- **Requires:** `novolis-messaging` (`Novolis.Messaging.Channels`) — workspace `ProjectReference` until messaging preview is on NuGet.

## Follow-ups

See [novolis-wirefish/TODO.md](https://github.com/Novolis-Platform/novolis-wirefish/blob/main/TODO.md).

## Personal repo

Keep [Frank.WireFish](https://github.com/frankhaugen/Frank.WireFish) active with a partial-migration README; do not archive.
