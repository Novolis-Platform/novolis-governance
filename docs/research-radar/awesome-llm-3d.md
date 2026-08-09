# Research radar: Awesome-LLM-3D → Novolis

Curated map of [ActiveVisionLab/Awesome-LLM-3D](https://github.com/ActiveVisionLab/Awesome-LLM-3D) onto Novolis library infrastructure.

**Survey:** [When LLMs step into the 3D World](https://arxiv.org/abs/2405.10255) (`arXiv:2405.10255`).

**Rule:** Absorb task taxonomy and interchange ideas into scene contracts and agent actions. Neural 3D models stay external (sidecar / app). No PyTorch or 3D-LLM weights in `Novolis.*` NuGet packages.

## Bucket → home → verdict

| Awesome bucket | Novolis home | Verdict | Notes |
|----------------|--------------|---------|-------|
| 3D Understanding (LLM) | `Modeling.Scene` + scene `ISceneSession` + SceneLab | **Adopt** | Deterministic `describescene` / `groundphrase` / `setsceneprops`; LLM calls them |
| 3D Understanding (CLIP/SAM/LERF…) | SceneLab `dumpviewport` + external VLM | **Adapter** | RGB PNG as multimodal context; no language fields in Rendering |
| 3D Generation (MeshGPT, LLaMA-Mesh, …) | `importmesh` (Assimp) + `importtriangles` (soup → `MeshEditBake`) | **Adopt** | Generation output becomes an importer, not a new mesh stack |
| 3D Reasoning / spatial VQA | Scene agent actions + `.nov3djson` | **Adopt** | Formal tool calls over the document; no CoT model in libraries |
| 3D Embodied agents | Game.Session / Humanoid / apps | **Skip** (radar) | Policy/VLA hosts are apps |
| 3D Benchmarks | dogfooding spatial-smoke | **Adapter** | Tiny named scenes only — not ScanNet |
| Unified understand+generate | — | **Skip** (radar) | Watch formats; keep NuGet Python-free |

## Scene agent actions (spatial tools)

Surface id `scene` (HTTP `:18785`, TCP `:18786`, env `NOVOLIS_SCENE_SESSION`). Domain work goes through `agent.command` / MCP `scene_command` with `actionId`.

| Action | Role for LLM workflows |
|--------|------------------------|
| `describescene` | Structured hierarchy / property summary (not an LLM call) |
| `groundphrase` | Name/id match → optional select |
| `setsceneprops` | Persist caption metadata on `SceneDocument.Properties` |
| `importtriangles` | Raw vertex/index soup → bake (LLM mesh dumps) |
| `importmesh` | Assimp FBX/OBJ/glTF |
| `dumpviewport` | Viewport PNG for VLM input; read artifact path from command result / `last-artifact.json` |
| `meshedit` / `addmodifier` / … | Existing mesh ops (canvas `propose_mesh_ops` not needed) |

## `SceneDocument.Properties` convention

Schema already allows string map `properties` ([novolis.scene.schema.json](../../schemas/3d/novolis.scene.schema.json)). Prefer these keys:

| Key | Meaning |
|-----|---------|
| `description` | Human/agent long description of the scene |
| `caption` | Short caption suitable for UI / VLM prompt |
| `source` | Provenance (URL, paper tag, generator id) |

Set via `setsceneprops` (`key`, optional `value` to clear).

## VLM context recipe

1. `dumpviewport` (optional `path`)
2. Read returned artifact path or SceneLab `dumps/last-artifact.json`
3. Pass PNG to an external VLM — never embed CLIP/LERF in `Novolis.Rendering.*`

## Related

- SceneLab dogfood: `novolis-dogfooding/apps/avalonia/SceneLab` (`--spatial-smoke`)
- MCP proxy: `novolis-dogfooding/apps/AvaloniaAgentMcp` (`scene_*` tools)
- Canvas placement: workspace `canvases/awesome-llm-3d-infrastructure.canvas.tsx`
