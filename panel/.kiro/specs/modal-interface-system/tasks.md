# Implementation Plan

- [x] 1. Create core InteractionMode system foundation
  - Create base InteractionMode abstract class with minimal interface
  - Create ModeDisplay and ModeShortcut mixins for composition
  - Set up proper file structure for the mode system
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2. Implement Riverpod state management for modes
  - Create CurrentInteractionMode Riverpod notifier with generator
  - Implement setMode() method for mode transitions
  - Add getCurrentModeAs<T>() method for type-safe mode access
  - _Requirements: 2.1, 2.6_

- [x] 3. Create shared ModeDisplayChip widget
  - Implement ModeDisplayChip widget with label and color parameters
  - Add consistent styling with opacity, border radius, and text formatting
  - Write widget tests for ModeDisplayChip rendering
  - _Requirements: 2.2, 2.3_

- [x] 4. Implement NormalMode with navigation shortcuts
  - Create NormalMode class extending InteractionMode with both mixins
  - Implement buildDisplay() method using ModeDisplayChip
  - Add navigation shortcuts (hjkl and arrow keys) with focus movement logic
  - Remove existing navigation shortcuts from main.dart
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 5. Create InsertMode for text editing
  - Implement InsertMode class with ModeDisplay mixin only
  - Add buildDisplay() method with green-colored chip
  - _Requirements: 5.5, 5.6_

- [x] 6. Build GlobalModeShortcutWidget bridge
  - Create GlobalModeShortcutWidget that watches current mode
  - Implement logic to extract shortcuts from ModeShortcut modes
  - Integrate with existing ManagedActionSet system
  - Write widget tests for shortcut bridge functionality
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 7. Create ModeDisplayWidget for app bar integration
  - Implement ModeDisplayWidget that watches current mode
  - Add logic to show/hide display based on ModeDisplay interface
  - Write widget tests for display widget behavior
  - _Requirements: 2.4, 2.5_

- [x] 8. Implement escape-to-normal utility function
  - Create escapeToNormalAction() helper function
  - Return ActionShortcut with escape key and mode transition logic
  - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 9. Create graph manipulation modes
- [x] 9.1 Implement GraphMoveMode
  - Create GraphMoveMode with both display and shortcut mixins
  - Add movement shortcuts (hjkl/arrows) for node manipulation
  - Include escape-to-normal functionality
  - _Requirements: 4.2, 4.4_

- [x] 9.2 Implement GraphResizeMode
  - Create GraphResizeMode with both display and shortcut mixins
  - Add resize shortcuts (hjkl/arrows) for node size manipulation
  - Include escape-to-normal functionality
  - _Requirements: 4.3, 4.5_

- [ ] 10. Enhance InputFieldContainer with mode integration
  - Convert InputFieldContainer to HookConsumerWidget
  - Implement bidirectional focus/mode synchronization using hooks
  - Add loop prevention mechanism for focus/mode changes
  - Remove existing manual escape handling in favor of mode system
  - Make sure the current tests stay passing!
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.7, 7.5_

- [x] 11. Integrate graph widget with managed actions
  - Wrap graph widget with ManagedActionSet
  - Add 'm' and 'r' shortcuts for entering graph manipulation modes
  - Implement mode-aware shortcut activation (only in normal mode)
  - _Requirements: 4.1, 4.6, 4.7_

- [x] 12. Wire up app bar with mode display
  - Integrate ModeDisplayWidget into existing custom app bar
  - Ensure proper positioning and styling within app bar layout
  - _Requirements: 2.4, 2.5_