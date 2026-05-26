# MS-MCP GUI Dashboard

The dashboard is a lightweight local control panel for the MS-MCP workspace and GUI queue.
It does not replace Materials Studio. It shows the active session, current document state,
queue status, calculation folders, and a simple structure preview.

## Start

```powershell
cd C:\path\to\MS-MCP 1.0
npm run dashboard
```

Open:

```text
http://127.0.0.1:4877
```

## Session Rules

- The dashboard writes the selected task session to `workspace\.ms-mcp-session.json`.
- MCP tools refresh that session file before state reads, exports, CIF downloads, and GUI queueing.
- Use the dashboard "new task session" button only when starting a separate task.
- Normal modeling should reuse the current dashboard/session folder.

## Modeling Rules

- Dashboard actions require `currentDocument`; they do not fall back to the active Materials Studio window.
- Broad `CalculateBonds` is refused for periodic documents from the dashboard.
- Structure preview writes `dashboard_structure_snapshot.json`; it does not export another `.xsd`.
- For robust structure creation, prefer the MCP tool `ms_gui_new_structure_current`.

