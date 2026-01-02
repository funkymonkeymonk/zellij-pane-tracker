# Spec: Command Execution

## Requirements

### Requirement: Command Execution in Target Pane

The `run_in_pane` tool SHALL execute shell commands in the specified target pane.

#### Scenario: Simple command execution
- **WHEN** user calls `run_in_pane` with pane_id and command
- **THEN** the command SHALL execute in the target pane
- **AND** the tool SHALL return success status

#### Scenario: Return to origin
- **WHEN** command execution completes
- **THEN** focus SHALL return to the original calling pane
