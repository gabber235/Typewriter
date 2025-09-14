# Requirements Document

## Introduction

This feature introduces a vim-inspired InteractionMode system that allows users to interact with the application through different modes, each providing specific functionality and keyboard shortcuts. The system is designed to be highly extensible, allowing for easy creation of custom interaction modes while providing a clean composition-based architecture. 

## Requirements

### Requirement 1

**User Story:** As a developer, I want a flexible InteractionMode system architecture, so that I can easily create and extend different interaction modes without modifying core system code.

#### Acceptance Criteria

1. WHEN the system is initialized THEN a base InteractionMode class SHALL be available that provides minimal core functionality
2. WHEN creating a new mode THEN the developer SHALL be able to extend the base InteractionMode class with custom behavior
3. WHEN implementing mode features THEN the system SHALL support composition through interfaces, mixins, and abstract classes
4. WHEN a mode needs display information THEN it SHALL implement a display interface for app bar integration
5. WHEN a mode needs keyboard shortcuts THEN it SHALL implement a shortcut interface for action registration

### Requirement 2

**User Story:** As a user, I want to see which mode is currently active in the app bar, so that I understand the current interaction context and available actions.

#### Acceptance Criteria

1. WHEN any mode is active THEN the current mode SHALL be tracked using Riverpod state management
2. WHEN a mode implements the display interface THEN it SHALL provide a method to build a display widget
3. WHEN the current mode has display capabilities THEN a mode display widget in the app bar SHALL show the mode's custom widget
4. WHEN the mode changes to one with display interface THEN the app bar SHALL update to show the new mode's display widget
5. WHEN the mode changes to one without display interface THEN the app bar mode display SHALL be hidden or show a default state
6. WHEN accessing mode data THEN the system SHALL provide a way to retrieve the current active mode and its properties

### Requirement 3

**User Story:** As a user, I want a normal mode that serves as the default interaction state, so that I have a consistent baseline experience with standard navigation shortcuts.

#### Acceptance Criteria

1. WHEN the application starts THEN the normal mode SHALL be the default active mode
2. WHEN in normal mode THEN standard navigation shortcuts (hjkl, arrow keys) SHALL be available for focus movement
3. WHEN normal mode is active THEN it SHALL implement both display and shortcut interfaces
4. WHEN normal mode provides shortcuts THEN they SHALL be passed through the global mode bridge to managed action sets

### Requirement 4

**User Story:** As a user, I want to enter graph manipulation modes using keyboard shortcuts, so that I can efficiently move and resize graph nodes without using the mouse.

#### Acceptance Criteria

1. WHEN the graph widget is active THEN it SHALL register a managed action set with 'm' and 'r' shortcuts
2. WHEN in normal mode and the graph has focus and pressing 'm' THEN the system SHALL enter graph move mode
3. WHEN in normal mode and the graph has focus and pressing 'r' THEN the system SHALL enter graph resize mode
4. WHEN in move mode and a graph node is focused THEN hjkl/arrow keys SHALL move the selected node
5. WHEN in resize mode and a graph node is focused THEN hjkl/arrow keys SHALL resize the selected node
6. WHEN in graph manipulation modes THEN the user SHALL be able to exit back to normal mode using escape key
7. WHEN not in normal mode THEN the graph's 'm' and 'r' shortcuts SHALL be inactive/disabled

### Requirement 5

**User Story:** As a user, I want text editing to automatically enter insert mode with proper focus management, so that keyboard shortcuts don't interfere with text input and focus changes are handled bidirectionally.

#### Acceptance Criteria

1. WHEN the InputFieldContainer's inner focus gains focus THEN the system SHALL switch to insert mode (unless already in insert mode)
2. WHEN the InputFieldContainer's surrounding focus loses all focus THEN the system SHALL switch to normal mode (if currently in insert mode)
3. WHEN the mode changes to insert AND the surrounding focus has primary focus THEN the inner text field SHALL be focused
4. WHEN the mode changes away from insert AND the inner text field has primary focus THEN the surrounding focus node SHALL be focused
5. WHEN in insert mode THEN navigation shortcuts SHALL not be registered, allowing normal text input
6. WHEN in insert mode AND it implements display interface THEN the app bar SHALL show the insert mode display
7. WHEN focus changes occur THEN the system SHALL prevent infinite loops between mode changes and focus changes

### Requirement 6

**User Story:** As a developer, I want modes to integrate with the existing managed action system through a global bridge widget, so that mode-specific shortcuts are automatically passed to the managed action set for registration and display.

#### Acceptance Criteria

1. WHEN the application initializes THEN a global mode shortcut widget SHALL be created that bridges modes and managed action sets
2. WHEN the current mode changes THEN the global widget SHALL automatically pass the new mode's shortcuts to the managed action set
3. WHEN a mode implements the action interface THEN its shortcuts SHALL be automatically available through the existing managed action set system
4. WHEN the managed action set receives mode shortcuts THEN it SHALL handle registration and action row display using existing functionality
5. WHEN mode transitions occur THEN the global widget SHALL ensure smooth handoff of shortcuts without manual registration/unregistration

### Requirement 7

**User Story:** As a developer, I want an easy way to provide escape-to-normal functionality in modes, so that I can optionally include this common behavior without implementing it from scratch.

#### Acceptance Criteria

1. WHEN creating a mode THEN a top-level escape handler SHALL be available that transitions to normal mode
2. WHEN a mode includes the escape handler THEN pressing escape SHALL trigger the transition to normal mode
3. WHEN a mode does not include the escape handler THEN escape key behavior SHALL be determined by the mode itself
4. WHEN the escape handler is triggered THEN any mode-specific cleanup SHALL be performed before transition
5. WHEN the InputFieldContainer integrates with the mode system THEN its manual escape handling SHALL be removed in favor of the mode-based approach
