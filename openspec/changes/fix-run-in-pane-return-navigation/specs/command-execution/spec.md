# Spec Delta: Command Execution

## MODIFIED Requirements

### Requirement: Command Execution in Target Pane

The `run_in_pane` tool SHALL execute shell commands in the specified target pane and return focus to the original pane after completion.

#### Scenario: Simple command execution
- **WHEN** user calls `run_in_pane` with pane_id="Pane #1" and command="pwd"
- **THEN** the command SHALL execute in Pane #1
- **AND** the command output SHALL appear in Pane #1's terminal
- **AND** focus SHALL return to the original calling pane
- **AND** the tool SHALL return success status with confirmation message

#### Scenario: Command execution with delay
- **WHEN** a command is written to the target pane
- **THEN** the tool SHALL wait for the command to complete before returning focus
- **AND** the delay SHALL be sufficient for simple commands (100-200ms minimum)

#### Scenario: Return navigation verification
- **WHEN** the tool attempts to return to the origin pane
- **THEN** it SHALL verify that focus actually returned to the correct pane
- **AND** if verification fails, it SHALL attempt fallback navigation
- **AND** it SHALL not return success until focus is confirmed on origin pane

#### Scenario: Failed command write
- **WHEN** writing the command to the target pane fails
- **THEN** the tool SHALL return an error with details about the failure
- **AND** it SHALL still attempt to return focus to the origin pane
- **AND** the error message SHALL include the pane identifier that was targeted

#### Scenario: Failed return navigation
- **WHEN** returning to the origin pane fails after command execution
- **THEN** the tool SHALL attempt fallback navigation through all tabs
- **AND** if fallback also fails, it SHALL return an error indicating the current pane location
- **AND** the error SHALL include both the target pane and origin pane identifiers

## ADDED Requirements

### Requirement: Command Execution Verification

The `run_in_pane` tool SHALL verify that commands are successfully written to the target pane before attempting to return.

#### Scenario: Successful command write
- **WHEN** command bytes are written to Zellij using the write action
- **THEN** the tool SHALL verify the write command completed without errors
- **AND** it SHALL add a delay to allow command processing
- **AND** it SHALL log any write failures for debugging

### Requirement: Enhanced Error Reporting

The `run_in_pane` tool SHALL provide detailed error messages that help users diagnose issues.

#### Scenario: Pane resolution failure
- **WHEN** the target pane cannot be found or resolved
- **THEN** the error message SHALL include the pane identifier provided
- **AND** it SHALL list available panes for reference
- **AND** it SHALL indicate which tab was searched (if applicable)

#### Scenario: Navigation state mismatch
- **WHEN** actual pane location differs from expected after navigation
- **THEN** the error message SHALL include both expected and actual pane IDs
- **AND** it SHALL indicate which tab contains each pane
- **AND** it SHALL suggest corrective actions if possible
