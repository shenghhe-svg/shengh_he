# MS-MCP

External MCP server for BIOVIA Materials Studio. It lets Codex or any MCP client call Materials Studio through the supported MaterialsScript runtime (`RunMatScript.bat`) instead of fragile mouse automation.

This project is intentionally conservative: all generated scripts and outputs are kept inside a configured workspace, and arbitrary script execution is disabled unless you explicitly enable it.

## Current status

This is an initial bridge layer. It exposes:

- `ms_status`: verify Materials Studio paths and workspace.
- `ms_codex_config`: print a Codex MCP configuration snippet.
- `ms_create_molecule`: create standalone `.xsd` documents from atoms and bonds. For the already-open GUI project, prefer `ms_gui_create_current`.
- `ms_forcite`: run Forcite `Energy`, `GeometryOptimization`, or `Dynamics`.
- `ms_castep`: run CASTEP base tasks or high-level presets on a workspace structure. Presets include `Energy`, `GeometryOptimization`, `Frequency`, `DensityOfStates`, `PartialDensityOfStates`, `BandStructure`, `BandStructureAndDOS`, `ChargeDensity`, and `DensityDifference`.
- `ms_list_workspace`: list generated outputs.
- `ms_read_text`: read text outputs.
- `ms_run_materialscript`: run custom MaterialsScript when `MS_MCP_ALLOW_ARBITRARY_SCRIPT=1`.
- `ms_enqueue_materialscript`: queue custom MaterialsScript for the optional in-GUI loop.
- `ms_queue_status`: inspect the optional loop queue.
- `ms_gui_state`: inspect the current stateful GUI target.
- `ms_gui_project_dir`: show the active task/session output folder under the workspace.
- `ms_gui_start_project_session`: start a new task/session folder only when explicitly requested. It refuses accidental folder switching during normal modeling unless `allowExistingSessionSwitch=true` is provided.
- `ms_gui_set_current_document`: set the current GUI document without creating a new file.
- `ms_gui_new_structure_current`: unified first-entry tool for new structures. If an open and reliable CIF can be found, it downloads and imports that CIF as the initial `.xsd`; if a likely source needs an account/API, it asks for access; if no usable CIF source exists, it performs controlled MCP GUI creation from manual atoms/cell data.
- `ms_gui_find_cif_import_current`: search open CIF sources, currently COD, score candidate reliability, download/import one reliable CIF, or return candidates/credential guidance instead of guessing.
- `ms_gui_import_current`: import a workspace file or absolute-path CIF/structure file into the GUI project and make it current.
- `ms_gui_create_current`: create a GUI document and make it current.
- `ms_gui_apply_current`: modify the current GUI document in place.
- `ms_gui_model_current`: run basic modeling-toolbar operations such as `Clean` and `AdjustHydrogen` on the current GUI document without creating a new document.
- `ms_gui_edit_current`: run common molecule-building edits on the current GUI document, including add/delete atom, change element, add/delete bond, set bond type, calculate bonds, clean, and adjust hydrogens.
- `ms_gui_dmol3_optimize_current`: run DMol3 geometry optimization on the current GUI document and organize calculation outputs under a dedicated `DMol3_*` calculation folder.
- `ms_gui_forcite_optimize_current`: run Forcite geometry optimization on the current GUI document and organize calculation outputs under a dedicated `Forcite_*` calculation folder.
- `ms_gui_castep_current`: run CASTEP on the current GUI document with presets for energy, geometry optimization, phonon/frequency, DOS, band structure, charge density, and density difference calculations.

## GUI Dashboard

MS-MCP includes a first-pass local dashboard under `GUI-Dashboard`. It monitors MCP/workspace state, GUI loop status, queues, current task session, current document, calculation folders, and a lightweight `.xsd` structure preview.

```powershell
cd C:\Tools\MS-MCP 1.0
npm run dashboard
```

Then open:

```text
http://127.0.0.1:4877
```

The dashboard can stop the GUI loop, start a new task session, queue basic modeling actions, and queue basic Forcite/DMol3/CASTEP geometry optimizations. The structure viewer works when the current task session contains an exported `.xsd`.

## Requirements

- Windows.
- BIOVIA Materials Studio with MaterialsScript installed.
- Node.js 20 or newer.

Default local install path used by this repo:

```powershell
C:\Program Files\BIOVIA\Materials Studio
```

## Install

```powershell
cd C:\Tools\MS-MCP 1.0
npm install
npm run smoke
```

For other computers, clone the GitHub repo and set `MS_INSTALL_ROOT` to that machine's Materials Studio install root.

## Codex MCP configuration

Add this server in Codex settings under MCP servers:

```json
{
  "mcpServers": {
    "MS-MCP": {
      "command": "node",
      "args": ["D:\\App\\MCP-MS\\src\\index.js"],
      "env": {
        "MS_INSTALL_ROOT": "D:\\App\\Materials Studio\\Materials Studio\\Materials Studio 23.1",
        "MS_MCP_WORK_ROOT": "D:\\Work\\Work-Ph.D\\Experimental material\\DFT\\MS-MCP-Workspace",
        "MS_MCP_STRUCTURE_SOURCE_POLICY": "auto"
      }
    }
  }
}
```

Restart Codex after adding the server. You should then see `MS-MCP` in the MCP server list.

## Recommended workflow

### Standalone runner

1. Open Materials Studio manually.
2. Open or create your project manually.
3. Talk with Codex and ask it to use `MS-MCP`.
4. Codex calls MCP tools. MS-MCP writes MaterialsScript jobs inside `MS_MCP_WORK_ROOT`, then launches Materials Studio's `RunMatScript.bat`.
5. Inspect generated documents and output files in Materials Studio.

### GUI project loop

If you want Codex to put documents directly into the Materials Studio project that you opened by hand, start the loop from inside the Materials Studio GUI, not from `RunMatScript.bat`.

In Materials Studio:

1. Open your project.
2. Choose `User | Library... | User Menu`.
3. Add a command named `Start MS-MCP Loop`.
4. Set `Script` to:

```text
C:\Tools\MS-MCP 1.0\materialscript\mcp_loop_gui.pl
```

5. Set `Run on` to `Client`.
6. Set `Requires` to `Any document`.
7. Run `User | Start MS-MCP Loop`.

The GUI loop watches:

```text
C:\MS-MCP-Workspace\.mcp-queue
```

Scripts consumed by this loop run in the GUI scripting context, so `Documents->New(...)` and `Documents->Import(...)` target the project that is open in Materials Studio.

### Stateful GUI workflow

Use the `ms_gui_*` tools for normal interactive work. These tools maintain the current state file inside the active task/session folder:

```text
C:\MS-MCP-Workspace\YYYY-MM-DD-N\.ms-mcp-state.json
```

The state file records:

- `currentDocument`: the Materials Studio document that "this molecule" refers to.
- `currentExport`: an optional exported workspace copy of that document, only set when an explicit export is requested.
- `lastJob`: the last queued operation.
- `history`: recent operations.

MS-MCP keeps only the hidden queue/session pointer at the workspace root, and puts task outputs in a numbered session folder:

```text
C:\MS-MCP-Workspace
|-- .mcp-queue
|-- .ms-mcp-session.json
|-- YYYY-MM-DD-1
|   |-- .ms-mcp-state.json
|   |-- gui_loop_status.txt
|   |-- ms-mcp-trace.txt
|   |-- molecule.xsd
|   +-- calculation job folders
+-- YYYY-MM-DD-2
```

By default the first session for a day is named like `2026-05-22-1`. To start another task on the same day without mixing files, call `ms_gui_start_project_session` or use the Dashboard "new task session" button; it will choose the next folder, such as `2026-05-22-2`. The MCP server refreshes `.ms-mcp-session.json` before state reads, exports, CIF downloads, and GUI queueing, so a session selected in the Dashboard is adopted by later Codex tool calls instead of creating a second folder from stale startup state. You can also override the folder before starting Codex with:

Connecting the MCP server or opening the Dashboard should not create a numbered task folder by itself. At startup MS-MCP only prepares the workspace root and `.mcp-queue`. A numbered task folder is created when a real GUI modeling/calculation job is queued, when a state file must be written, or when `ms_gui_start_project_session` / the Dashboard "new task session" button is used.

```powershell
$env:MS_MCP_PROJECT_FOLDER = "my-project-name"
```

or point directly to a subfolder under the workspace:

```powershell
$env:MS_MCP_PROJECT_ROOT = "C:\MS-MCP-Workspace\2026-05-22-1"
```

GUI document targeting is deliberately strict once `currentDocument` is set. When a later operation says "this molecule", MS-MCP tries to resolve the target by exact document key, `name.xsd`, name without `.xsd`, and the visible document name in the open GUI project. It does not silently fall back to the active window or the most recent 3D document when a named target is missing, because that can edit the wrong structure and create confusing duplicate `.xsd` files. After a GUI operation succeeds, the loop writes the runtime `$doc->Name` back into the session `.ms-mcp-state.json`.

The intended GUI workflow is:

1. Create or import a primitive/base structure with `ms_gui_new_structure_current`.
   - For a new crystal, molecular crystal, 2D material, or known experimental structure, this unified tool first searches open CIF sources. If it finds an open and reliable CIF, it downloads that CIF and imports it as the initial `.xsd` / current GUI document.
   - If a likely source exists but is not open and needs ICSD/CSD/Materials Project API/OQMD credentials, it returns candidates and asks the user for existing access or a user-supplied CIF.
   - If no usable CIF source exists, it falls back to MCP GUI creation when manual atoms/cell data are provided.
   - Direct `ms_gui_find_cif_import_current`, `ms_gui_download_cif_import_current`, `ms_gui_create_crystal_current`, `ms_gui_create_current`, and `ms_gui_import_current` remain available as lower-level tools, but they should not be the first choice for normal new-structure requests.
   - Do not name the initial/base document after a planned supercell size. For example, create `graphene_primitive.xsd` or `graphene_unit_cell.xsd` first, then use `ms_gui_make_supercell_current` to expand the same current document.
2. Use `ms_gui_apply_current` for follow-up edits such as "add Br", "replace H by F", "add adsorbate", or "change display style".
3. Use `ms_gui_edit_current` or `ms_gui_model_current` for Materials Studio modeling-toolbar actions on the same current document:
   - `AddAtom`, `DeleteAtom`, `ChangeElement`, `RenameAtom`.
   - `AddBond`, `DeleteBond`, `SetBondType`.
   - `CalculateBonds`.
   - `Clean` maps to `$doc->Clean`.
   - `AdjustHydrogen` maps to `$doc->AdjustHydrogen`.
   - `CleanAndAdjustHydrogen` adjusts hydrogens, cleans, then adjusts hydrogens again.
4. Use the crystal/periodic tools for unit-cell work on the same current document:
   - `ms_gui_create_crystal_current`: create a periodic crystal/unit cell from lattice parameters and atoms.
   - `ms_gui_set_lattice_current`: change lattice lengths/angles in place.
   - `ms_gui_make_supercell_current`: build a supercell in place with Materials Studio `BuildSuperCell`.
   - `ms_gui_add_vacuum_current`: add vacuum only when the user explicitly asks for vacuum. For an already-built 3D cell, it can extend a lattice axis while preserving Cartesian atom positions. For an existing 2D surface, it can call CrystalBuilder `VacuumSlab`.
   - `ms_gui_cleave_surface_vacuum_current`: manual-style surface workflow: `Build | Surface | Cleave Surface`, then `CrystalBuilder | VacuumSlab`.
5. Use `ms_gui_dmol3_optimize_current` or related calculation tools on the same current document.
6. Only create a new document when the user explicitly asks for a new molecule, conformer, copy, or derivative.

This fixes the old behavior where every request generated a separate standalone document. In the stateful workflow, "on this molecule" means "modify `currentDocument` in place".

For crystal/surface workflows, CIF import is only an entry point. Import an existing CIF once with `ms_gui_import_current`; the `file` can be either under the MS-MCP workspace or an absolute path elsewhere on the computer. MS-MCP does not need to copy the CIF into the workspace first. After import, bonding, changing elements, building a supercell, adding vacuum, display changes, and clean/adjust operations must operate on the current `$doc` through `ms_gui_apply_current`, `ms_gui_edit_current`, `ms_gui_model_current`, `ms_gui_set_lattice_current`, `ms_gui_make_supercell_current`, or `ms_gui_add_vacuum_current`. Do not generate a new CIF and re-import it for each modeling step, because that creates extra project documents and makes the active target ambiguous.

If a reliable database CIF is available, prefer database/CIF import over manually reconstructing the same crystal. `ms_gui_find_cif_import_current` searches open COD records and imports only when one candidate clears the confidence threshold; otherwise it returns candidates and the reason it did not import. `ms_gui_download_cif_import_current` supports direct CIF URLs and COD numeric IDs when the source is already known. Both tools download the CIF once into the active task session under `cif/`, then import that CIF into the open GUI project and make it the current document. Subsequent modeling must continue on that current document; do not download or regenerate the CIF again for supercell, vacuum, substitution, display, or calculation steps.

Database access should respect each database's license and authentication model:

- COD: open CIFs can be downloaded by numeric COD id when available.
- Direct URL: any user-provided direct `.cif` link can be downloaded once and imported.
- Materials Project: use the official API with the user's API key, then save/export the returned structure as one CIF before importing. Do not require this for users without an API key.
- CCDC/CSD and ICSD: these are licensed databases. MS-MCP should only access them through the user's installed/licensed tools or official APIs/exports. It should not attempt to bypass authentication or redistribute downloaded structures.

MS-MCP must never create database accounts, create API keys, accept hidden credentials, scrape around a login wall, or bypass license restrictions. If a data source requires credentials and the user has not explicitly provided existing credentials/API configuration, stop and ask the user. If the user does not have access, use another open source or proceed with manual modeling instead.

The intended decision path is: search/identify a reliable structure source, download or receive one CIF, import it once, then keep all later edits in the same Materials Studio GUI document.

The source policy is controlled by `MS_MCP_STRUCTURE_SOURCE_POLICY`:

- `auto` (default): search open CIF sources for crystals/known structures, import a reliable result, otherwise use provided manual data or return a clear next step.
- `manual`: skip open CIF search and use manual modeling parameters.
- `require_cif_first`: do not fall back to manual modeling until a reliable CIF or user-provided credential/source is available.

For new periodic structures, prefer `ms_gui_create_crystal_current` instead of generating a temporary CIF. It wraps Materials Studio's CrystalBuilder workflow:

```text
Tools->CrystalBuilder->SetSpaceGroup(...)
Tools->CrystalBuilder->SetCellParameters(...)
Tools->CrystalBuilder->Build($doc)
```

Coordinates can be supplied as fractional or Cartesian positions. Fractional coordinates are converted against the requested lattice before the CrystalBuilder build step. This keeps the GUI workflow close to manual Materials Studio use while avoiding extra `name (2).xsd` documents.

For layered 2D crystals such as graphene, treat the first step as a real periodic crystal primitive cell, not as a finite molecule and not as a pre-named supercell. A graphene primitive cell should be built with a hexagonal in-plane lattice such as `a=b≈2.46 Å`, `gamma=120°`, and two carbon atoms in fractional coordinates, for example `(1/3, 2/3, z)` and `(2/3, 1/3, z)`. Use `ms_gui_new_structure_current` once to create/import `graphene_primitive.xsd` or `graphene_unit_cell.xsd`, then expand the same current document with `ms_gui_make_supercell_current` using `a=n`, `b=m`, `c=1` for a monolayer. Do not create an initial document named `graphene_3x3x2.xsd` and then also run a `3,3,2` supercell, because that doubles the intended expansion semantics and makes the project state ambiguous.

For periodic crystals and supercells, automatic bond calculation is disabled by default in MS-MCP. Materials Studio's general bond guessing can connect atoms incorrectly across periodic boundaries for 2D materials, especially after supercell expansion. If bonds are needed for display, use an explicit targeted bonding step or a material-specific builder rather than a broad `$doc->CalculateBonds` on the whole periodic supercell.

`ms_gui_edit_current` refuses broad `CalculateBonds` on periodic documents by default. Pass `allowPeriodicBondGuess=true` only when the user explicitly accepts the risk of periodic bond guessing; otherwise use explicit `AddBond` / `SetBondType` operations or leave bonding purely as a display concern.

For in-place modeling tools such as `ms_gui_make_supercell_current`, `documentName` is a selector for an existing GUI document, not an output name. To build a `3x3x1` graphene supercell, keep `documentName` omitted so the current graphene document is edited in place; do not set `documentName` to `Graphene_3x3x1_Supercell.xsd` before that document exists. If a workspace copy is needed for inspection, use `exportFile`, but do not feed that export back to `ms_gui_import_current`.

Create tools also respect the one-active-structure rule. If a session already has `currentDocument`, `ms_gui_create_current` and `ms_gui_create_crystal_current` may rebuild only that same named document unless `forceNew=true` is explicitly set. This prevents a repair attempt such as "make a honeycomb version" from accidentally clearing the old current document, exporting it under a new name, and then forcing Materials Studio to create `name (2).xsd` on the next rebuild.

Do not add vacuum during initial unit-cell construction unless the user's prompt explicitly asks for vacuum or gives a lattice parameter that already includes vacuum. Vacuum is a separate modeling instruction. MS-MCP exposes two explicit paths:

- Initial-cell path: choose a large lattice length, usually `c`, in `ms_gui_create_crystal_current` when the user asks for a slab/cell with vacuum from the start.
- Manual surface path: use `ms_gui_cleave_surface_vacuum_current` to cleave a surface with Miller indices and slab thickness, then build a vacuum slab with CrystalBuilder.

`ms_gui_add_vacuum_current` is a lighter in-place edit for an already-built periodic document. It is useful for simple slab models, but it is not a replacement for the full SurfaceBuilder cleave workflow when the user asks for the manual `Build | Surface | Cleave Surface` route.

`ms_gui_create_current` is also in-place by default. If a current document or same-name document exists, it clears and rebuilds that GUI document rather than creating `name (2).xsd`. Use `forceNew: true` only when the user explicitly asks for a separate new structure.

`ms_gui_apply_current` and `ms_gui_create_current` reject script bodies that call `Documents->New`, `Documents->Import`, `SaveAs`, or `Export`. Those operations are intentionally kept out of follow-up modeling steps so the MCP behaves like manual editing of one open structure.

For GUI modeling workflows, keep `exportFile` omitted. Modeling operations then only save the current GUI document and do not export a second workspace `.xsd` copy. This prevents Materials Studio from adding duplicate project documents such as `model (2).xsd` when a style/display update is applied. MS-MCP also normalizes accidental modeling work-copy names such as `graphene_current.xsd` back to `graphene.xsd`; `currentDocument` belongs in `.ms-mcp-state.json`, not in a second structure file.

`ms_gui_import_current` also checks the open GUI project before importing. If a 3D document with the requested name is already present, it reuses that document instead of importing a duplicate such as `model (2).xsd`. It refuses to import an `.xsd` that is merely the current document's workspace export or another `.xsd` already inside the active MS-MCP session folder; those files are work/output copies, not new GUI sources. On first import it avoids `SaveAs` and avoids a default workspace export, so importing a CIF should create only the Materials Studio document generated by the import itself. The legacy `ms_create_molecule` tool defaults to standalone file generation and should not be used as the first step for GUI-only modeling unless a later import is really needed.

Calculation workflows such as DMol3 and Forcite create a dedicated calculation folder under the active date folder. The folder name identifies the calculation; files inside the folder use simple module names so the Project Explorer stays close to a manual Materials Studio run. For example:

```text
C:\MS-MCP-Workspace\2026-05-21
`-- DMol3_Carbazole_COOH_Opt
    |-- DMol3_settings.json
    |-- DMol3_settings.txt
    |-- DMol3_summary.txt
    |-- DMol3.outmol
    `-- DMol3.xsd
```

Folder names are intentionally compact. MS-MCP normalizes long calculation labels to:

```text
Forcite_<short-subject>_geomopt
DMol3_<short-subject>_geomopt
```

Method and parameter words such as `Fine`, `Universal`, or `COMPASSIII` are not included in the folder name; they belong in the settings document.

For GUI calculations, MS-MCP requires the dedicated calculation folder to be created before the calculation runs. It no longer falls back to running on the root current document when `SaveAs("/Calculation/Module.xsd")` fails, because that fallback scatters convergence charts and `Status.txt` into the project root instead of behaving like a manual calculation folder.

Forcite, DMol3, and CASTEP result document names are normalized to `.xsd`. If a caller passes `Forcite_result` instead of `Forcite_result.xsd`, MS-MCP writes `Forcite_result.xsd` before submitting the Materials Studio job. This avoids failed first submissions caused only by a missing model-file extension. If a calculation fails while creating its GUI calculation folder, MS-MCP tries to delete that failed calculation folder and root-level orphan calculation charts such as `<source> Convergence.xcd`, `<source> Energies.xcd`, and `Status.txt`, so a corrected retry does not leave the Project Explorer cluttered with a known-bad first attempt.

MS-MCP also calls `SaveSettings(...)` where available so a Materials Studio settings document such as `DMol3 - Calculation` or `Forcite - Calculation` is placed into the GUI project calculation folder. The text/JSON copies are always written to the workspace calculation folder so the exact parameters can be inspected even if the GUI settings document is not imported by a particular Materials Studio version.

DMol3 and Forcite optimizations run on a calculation working copy named after the module, such as `DMol3.xsd` or `Forcite.xsd`. The optimized structure is exported back to that same workspace filename. This avoids the earlier `*_input.xsd` plus `*_opt.xsd` pair and better matches the manual calculation folder style where one structure document belongs to the calculation. Materials Studio may automatically import charts such as Energy and Convergence charts into the GUI project. The MCP no longer manually duplicates these charts under a second name.

CASTEP presets are mapped to Materials Studio's CASTEP scripting settings rather than invented task names. For example, `DensityOfStates` uses `CalculateDOS => "Full"`, `BandStructure` uses `CalculateBandStructure => "Dispersion"`, `BandStructureAndDOS` uses `CalculateBandStructure => "DispersionAndDos"` plus DOS, `Frequency` enables phonon DOS/dispersion settings, and `DensityDifference` uses `CalculateDensityDifference => "FieldAndIsosurface"`. You can override or extend any preset by passing `extraSettings` in GUI mode or `settings` in standalone mode.

When a `cores` value is passed to `ms_gui_dmol3_optimize_current`, MS-MCP sets `DSD_NumProc` for the queued GUI script before launching DMol3. This mirrors the processor count used by the DMol3 backend for managed tasks on the installed Materials Studio version.

The current GUI-loop DMol3 path uses the MaterialsScript `Run()` API. That API runs synchronously inside the Materials Studio script context, so it may not always appear in the `Jobs` panel the same way as a manually submitted Job Control task. Full `Jobs` panel integration should be implemented as a separate submitted-job path once the exact Materials Studio Job Control API for the installed version is mapped.

The GUI loop also writes a simple task log inside the active task/session folder. By default this is:

```text
C:\MS-MCP-Workspace\YYYY-MM-DD-N\gui_loop_status.txt
```

The loop reads `.ms-mcp-session.json` beside `.mcp-queue`, so if Codex starts a new session while the GUI loop is already running, later loop status entries move to the new session folder automatically.

To stop the loop, create this file:

```text
C:\MS-MCP-Workspace\.mcp-queue\stop
```

or close the running script.

For the closest-to-GUI behavior, enable queueing in the Codex MCP server environment:

```json
{
  "MS_MCP_ALLOW_ARBITRARY_SCRIPT": "1",
  "MS_MCP_QUEUE_DIR": "D:\\App\\MCP-MS\\workspace\\.mcp-queue"
}
```

With that enabled, Codex can call `ms_enqueue_materialscript` and the open Materials Studio session will pick up queued `.pl` jobs. Stop the loop with Ctrl+C or by closing the Script window.

## Safety model

- MS-MCP only reads and writes inside `MS_MCP_WORK_ROOT` for job files and output access.
- Paths passed to tools are checked to prevent `..` traversal outside the workspace.
- It does not delete files.
- It does not edit your Materials Studio installation.
- Custom arbitrary MaterialsScript is blocked by default. Enable it only for trusted local use:

```powershell
$env:MS_MCP_ALLOW_ARBITRARY_SCRIPT = "1"
```

MaterialsScript itself can modify documents and submit calculations, so treat enabled arbitrary scripting like giving a local expert access to Materials Studio.

## Notes on the GUI loop

Materials Studio does not expose a native Python-like `mcp_loop()` function in the inspected installation. MS-MCP uses `materialscript/mcp_loop_gui.pl` as the single supported polling loop for an already-open Materials Studio GUI project.
