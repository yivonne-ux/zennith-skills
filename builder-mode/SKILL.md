# Builder Mode Skill

## Concept
An overlay layer that lets users annotate, doodle, and command directly on any live page — replacing the screenshot-and-describe workflow.

## How It Works
1. User toggles Builder Mode (keyboard shortcut or floating button)
2. A transparent overlay appears over the current page
3. User can:
   - **Draw/Doodle** — freehand annotations (circles, arrows, underlines) in red/yellow
   - **Type commands** — click anywhere to drop a text annotation
   - **Select elements** — click to highlight a DOM element with a bounding box
   - **Screenshot** — captures the page + all annotations as a single image
4. User hits "Submit" → everything gets packaged:
   - Base screenshot of the page
   - Annotation layer (SVG/canvas overlay)
   - Text commands extracted
   - DOM element selectors for highlighted items
5. Package sent to the agent (via OpenClaw message or API)

## Technical Implementation
- **Overlay**: Absolute-positioned canvas element (z-index: 99999)
- **Drawing**: HTML5 Canvas with brush/line/arrow/circle tools
- **Text**: Floating input that creates positioned text nodes
- **Element Selection**: `document.elementFromPoint()` + bounding box overlay
- **Capture**: `html2canvas` or `dom-to-image` for combined screenshot
- **Submission**: POST to OpenClaw API or WebSocket message

## Integration Points
- Works on any GAIA OS app (Creative Studio, Landing Page, etc.)
- Can be injected as a bookmarklet or browser extension
- Or built as a React component for GAIA apps

## Phase 1 (MVP)
- Toggle overlay on/off
- Freehand drawing (pen tool)
- Text annotations (click to place)
- Screenshot + submit to clipboard/file

## Phase 2
- Arrow/circle/rectangle shape tools
- DOM element highlighting
- Direct WebSocket to OpenClaw agent
- Voice commands (Whisper integration)
- History of annotations

## Keyboard Shortcuts
- `Ctrl+Shift+B` — Toggle builder mode
- `P` — Pen tool
- `T` — Text tool
- `A` — Arrow tool
- `Esc` — Cancel current tool
- `Enter` — Submit annotations
