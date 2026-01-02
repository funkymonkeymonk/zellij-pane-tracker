# Design: Fix run_in_pane Bugs

## Context

The `run_in_pane` MCP tool is designed to execute shell commands in specific Zellij panes and automatically return focus to the original pane. Current implementation has two bugs:

1. **Command execution failure**: Commands fail with exit code 2, no visible output
2. **Return navigation failure**: Focus does not return to original pane after execution

## Goals

- Fix command execution so simple commands like `pwd` work reliably
- Fix return navigation so focus returns to original pane after command completes
- Maintain backward compatibility with existing pane resolution logic
- Keep performance acceptable (minimize unnecessary pane cycling)

## Non-Goals

- Rewrite the entire pane navigation system
- Add new features beyond bug fixes
- Change the tool's API or behavior (except fixing bugs)

## Current Implementation Analysis

### Command Execution (lines 755-758)
```typescript
const bytes = [...command].map(c => c.charCodeAt(0));
await $`zellij -s ${sessionName} action write ${bytes.join(' ')}`.quiet();
await $`zellij -s ${sessionName} action write 10`.quiet(); // Enter
```

**Potential Issues:**
- Byte conversion may fail for special characters
- No verification that command was written successfully
- No delay to ensure command completes before returning
- Error handling doesn't distinguish between write failures and navigation failures

### Return Navigation (lines 760-763)
```typescript
if (originPaneId && originPaneId !== targetPaneId) {
  await returnToOrigin(sessionName, originPaneId, originTabName);
}
```

**Potential Issues:**
- `returnToOrigin` may fail silently
- No verification that we actually returned to origin
- `originTabName` might be null, making navigation slower
- No fallback if direct navigation fails

## Decisions

### Decision 1: Add Command Execution Verification

**Approach:** After writing command bytes, add a small delay and check if the command actually executed.

**Options Considered:**
1. ✅ **Add delay after command write** - Simple, works for most cases
2. ❌ Poll pane output to detect command completion - Too complex, unreliable
3. ❌ Use Zellij's command execution API - Doesn't exist

**Rationale:** A small delay (100-200ms) ensures the command is processed before we navigate away. This is the simplest solution that covers 95% of use cases.

### Decision 2: Fix Byte Code Conversion

**Approach:** Test if byte code conversion is causing issues, consider using `write-chars` with proper escaping.

**Options Considered:**
1. ✅ **Test current byte approach with debug logging** - Understand root cause first
2. **Switch to write-chars with escaping** - Fallback if bytes don't work
3. ❌ Use Zellij plugin API - Requires Rust rewrite

**Rationale:** Current byte approach should work; need to debug why it's failing before changing approach.

### Decision 3: Verify Return Navigation

**Approach:** After `returnToOrigin`, verify we're actually on the origin pane. If not, retry with full navigation.

**Implementation:**
```typescript
await returnToOrigin(sessionName, originPaneId, originTabName);

// Verify we returned successfully
const currentPaneAfterReturn = await getCurrentPaneId(sessionName);
if (currentPaneAfterReturn !== originPaneId) {
  // Fallback: full navigation scan
  await navigateToTargetPane(sessionName, originPaneId);
}
```

**Rationale:** Defensive programming - verify assumptions before returning success.

### Decision 4: Improve Error Messages

**Approach:** Return detailed error information including:
- Which pane we tried to target
- Whether navigation succeeded
- Whether command write succeeded
- Current pane location vs expected

**Rationale:** Helps users debug issues and provides actionable feedback.

## Risks / Trade-offs

### Risk: Performance degradation from delays
- **Mitigation:** Keep delay minimal (100-200ms), make it configurable if needed
- **Trade-off:** Slight latency increase vs reliability

### Risk: Return verification adds complexity
- **Mitigation:** Only verify once, fallback is rare edge case
- **Trade-off:** More code vs guaranteed correctness

### Risk: Breaking existing users who expect fast execution
- **Mitigation:** Delays are minimal, existing behavior is broken anyway
- **Trade-off:** N/A - this is a bug fix

## Migration Plan

1. **Phase 1**: Add debug logging, identify root cause
2. **Phase 2**: Implement fixes with verification
3. **Phase 3**: Test thoroughly with various scenarios
4. **Phase 4**: Deploy and monitor for issues

**Rollback:** If fixes cause new problems, revert to v0.7.0 and investigate further.

## Open Questions

1. Is 200ms delay sufficient for command execution across all systems?
2. Should we expose delay as a configurable parameter?
3. Do we need to handle multi-line commands differently?
4. Should we add a "wait for prompt" mechanism for long-running commands?

**Answers needed before implementation.**
