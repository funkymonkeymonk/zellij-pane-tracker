# Change: Fix run_in_pane Return Navigation and Command Execution

## Why

The `zellij_run_in_pane` tool currently has two critical bugs:

1. **Return navigation fails** - After running a command in a target pane, the tool does not properly return focus to the original pane. User reports that "it never cycled back correctly."

2. **Command execution fails** - Commands like `pwd` fail to execute with exit code 2, and no output appears in the target pane. User reports "nothing happened in that pane."

These bugs make the tool unreliable for basic operations, preventing users from automating terminal commands across Zellij panes.

## What Changes

- Fix the `returnToOrigin` function to correctly restore focus to the original pane after command execution
- Debug and fix the command execution mechanism to ensure commands actually run in the target pane
- Add error handling and verification that commands execute successfully
- Improve error messages to help diagnose failures
- Add delay/wait mechanism if needed to ensure commands complete before returning

## Impact

- **Affected specs:** `command-execution` (MCP tool behavior)
- **Affected code:** 
  - `mcp-server/index.ts:707-770` (run_in_pane tool)
  - `mcp-server/index.ts:436-474` (returnToOrigin function)
- **Breaking changes:** None - this is a bug fix
- **User benefit:** Users will be able to reliably execute commands in any Zellij pane and have focus automatically return to their working pane
