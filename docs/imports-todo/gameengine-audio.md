# Import: `Frank.GameEngine.Audio` → Novolis

**Source:** `D:\frankrepos\Frank.GameEngine\src\Frank.GameEngine.Audio`

## What

| Area | Types |
|------|-------|
| Contract | `IAudioEngine`, `IAudioLibrary`, `IAudioPlayer`, `IAudioPlayer2` |
| Ogg | `Audio.Ogg` — NAudio looping clips |
| MIDI | `Audio.Midi` — `MidiSong`, `SongPlayer`, `TuneLibrary` |
| Console | `Audio.Console` — beep/tone fallback |

Embedded samples ship from `Frank.GameEngine.Assets` (`Audio/Midi/Songs`); decouple or duplicate minimal test clips on port.

## Why

- **No Novolis audio package** exists; dogfood apps are silent or ad-hoc.
- Self-contained vertical (NAudio stack); no conflict with math/physics/simulation boundaries.
- Frank `GameEngine` docs require `Shutdown()` to stop looping audio — pattern worth preserving.

## How

### Target (choose one)

| Option | Pros |
|--------|------|
| **A. `novolis-audio` (new repo)** | Clean dependency island; Raylib + apps consume |
| **B. `novolis-raylib` facet** | Fewer repos; couples audio to graphics host |

**Recommendation:** **A** if multiple hosts (Avalonia apps, headless tools) need sound; **B** if only Raylib games for next 12 months.

### Port steps

1. Create `Novolis.Audio.Abstractions` + `Novolis.Audio.NAudio` (or single package initially).
2. Port interfaces and Ogg player first; MIDI second; Console fallback for CI.
3. Native/content: pack minimal `.ogg` under `contentFiles` or skip MIDI in v1.
4. Lifecycle: `IAudioEngine.Start` / `Stop` documented for host loop (mirror `GameEngine.Shutdown`).
5. Tests: mock `IAudioPlayer`; one integration test optional (skip on headless CI).

### Skip

- Tight coupling to `Frank.GameEngine.Core` scene loop — apps call audio explicitly.

## Acceptance

- At least Ogg play/loop API on GPR.
- No Frank.* package references in Novolis production code.
