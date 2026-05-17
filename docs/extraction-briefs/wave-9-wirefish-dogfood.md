# Wave 9 — WireFish Avalonia dogfood

**Target repos:** [novolis-avalonia](https://github.com/Novolis-Platform/novolis-avalonia), [novolis-transports](https://github.com/Novolis-Platform/novolis-transports), [novolis-dogfooding](https://github.com/Novolis-Platform/novolis-dogfooding)  
**Source inspiration:** [WireShark](https://www.wireshark.org/) layout (packet list, protocol tree, hex dump)  
**Acceptance app:** `novolis-dogfooding/apps/WireFishViewer`

## Scope (in)

| Area | Novolis home | Notes |
|------|--------------|-------|
| Analyzer workspace layout | `Novolis.Avalonia.Layout` | `AnalyzerWorkspace`, `ToolbarRow`, `FilterBar`, `DetailTreeNode` |
| Hex dump, tree, packet table | `Novolis.Avalonia.Controls` | `HexDumpView`, `TreeDetailsView`, `PacketTableView` |
| Live capture UI | `novolis-dogfooding/apps/WireFishViewer` | Dogfoods `Novolis.Transports.WireFish` |
| Protocol tree + row formatting tests | `WireFishViewer.Tests` | TUnit |

## Out of scope

- Offline `.pcap` import/export
- Display filters (Wireshark green bar); BPF only via `WireFishOptions`
- Follow-stream, dissector plugins, statistics dialogs
- Security scan panels (`DevicePacketSecurityExtensions` UI)

## Dependencies

- `Novolis.Avalonia.Controls` → `Novolis.Avalonia.Layout`
- `WireFishViewer` → `Novolis.Transports.WireFish`, `Novolis.Messaging.Channels`, Avalonia 12 + Fluent
- Live capture requires **Npcap** (Windows) or libpcap

## Done when

- `dotnet build` / `dotnet run --project apps/WireFishViewer` from `novolis-dogfooding`
- `dotnet test` for `WireFishViewer.Tests` and `Novolis.Avalonia.Controls.Tests`
- App starts without Npcap (`AllowNoCaptureDevices`) with warning banner
- Start/Stop capture, interface picker, packet list + detail + hex on selection

## Related

- [wave-9-wirefish.md](wave-9-wirefish.md)
- [wirefish-rename-plan.md](../wirefish-rename-plan.md)
