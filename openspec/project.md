# Project Context

## Purpose

Zellij Pane Tracker is an MCP (Model Context Protocol) server that provides tools for managing and interacting with Zellij terminal panes programmatically.

**Goals:**
- Enable AI assistants to read pane content, execute commands, and manage pane layout
- Provide reliable pane identification using display names (e.g., "Pane #1") or terminal IDs
- Support tab-scoped queries for multi-tab Zellij sessions
- Maintain fast performance by minimizing unnecessary pane cycling

## Tech Stack

- **Runtime:** Bun (JavaScript/TypeScript)
- **MCP SDK:** @modelcontextprotocol/sdk
- **Terminal Multiplexer:** Zellij
- **Pane Metadata:** JSON file updated by Zellij plugin (`/tmp/zj-pane-names.json`)

## Project Conventions

### Code Style
- TypeScript with strict typing
- Async/await for all Zellij command execution
- Use `$` template literal from Bun for shell commands
- Descriptive function names for navigation logic

### Architecture Patterns

**Three-Layer Architecture:**
1. **MCP Tools Layer** - Exposed tools: `get_panes`, `dump_pane`, `run_in_pane`, `new_pane`, `rename_session`
2. **Navigation Layer** - Pane resolution, tab navigation, focus management
3. **Zellij Command Layer** - Direct `zellij` CLI invocations via Bun shell

**Pane Resolution Priority:**
1. Display name match (e.g., "Pane #1", "opencode")
2. Terminal ID match (e.g., "terminal_2", "2")
3. Partial/fuzzy name match (fallback)

### Testing Strategy
- Manual testing with real Zellij sessions
- Test various pane identifier formats
- Test cross-tab navigation scenarios
- Verify return-to-origin behavior

### Git Workflow
- Use OpenSpec for change management
- Conventional commits: `fix:`, `feat:`, `refactor:`
- Version bumps follow semantic versioning
- Update version notes in source code comments

## Domain Context

**User:** Nakul Tiruviluamala (professor using OpenCode + Zellij for terminal automation)

**System Components:**
- **Rust Plugin:** `zellij-pane-tracker` (updates JSON metadata)
- **MCP Server:** `mcp-server/index.ts` (provides tools to AI)
- **OpenCode Integration:** Configured in `~/.config/opencode/opencode.json`

**Key Files:**
- `mcp-server/index.ts` - Main MCP server implementation
- `src/main.rs` - Zellij plugin (Rust)
- `README.md` - Usage documentation

## Important Constraints

- **Current tab preference:** "Pane 1" searches current tab only (v0.7.0 behavior)
- **No breaking changes:** Must maintain backward compatibility with existing users
- **Performance:** Minimize pane cycling (max 10 panes per tab default)
- **Error handling:** Always attempt to return to origin, even on failure

## External Dependencies

- **Zellij CLI** - Must be available in PATH
- **Bun runtime** - For executing TypeScript MCP server
- **OpenCode** - AI assistant that consumes MCP tools
- **Pane metadata file** - `/tmp/zj-pane-names.json` updated by plugin
