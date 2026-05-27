# Workspace, snapshot, and timeline stack

**Repo:** `novolis-workspaces`  
**Packages:** `Novolis.Workspaces.*`, `Novolis.Snapshots.*`, `Novolis.Timeline.*`

## Purpose

Editor and studio apps (Voice Studio, scenario tools, 4X saves) need:

- Workspace / project folder structure
- Normal save/load and autosave
- Manual save points and restore points
- Branchable, project-local or workspace-local history
- UI projections for timeline trees

## Rules

| Layer | Owns |
|-------|------|
| **Snapshots** | `ISnapshotStore` — state ↔ ref (memory, zip, file) |
| **Timeline** | `ITimeline` — graph over refs only |
| **Workspaces** | `IWorkspace` / `IProject` — layout and manifests |
| **Adapters** | Zip workspace capture, save/restore orchestration |

**Snapshots** do not know history. **Timeline** does not know files. **Workspaces** do not implement branching.

## Not the same as

- `Novolis.IO.Workspace` — keyed file root for Storage.Json
- `ISnapshotCapableEventStore` — event stream compaction
- `SimulationTimeline<TState>` — simulation tick replay

## Consumer pattern

Apps reference adapter packages (`Workspaces.Timeline`, etc.) via GitHub Packages `2026.1.*`. See [novolis-workspaces design](https://github.com/Novolis-Platform/novolis-workspaces/blob/main/docs/design.md).
