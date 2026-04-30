# Input Field Controller Plan

## Context

- `InputFieldContainer` currently accepts an `inputFocusNode` plus an optional `surroundingFocusNode`, and manages the relationship between the inner input focus and the surrounding container focus.
- `QueryBar` currently exposes `focusNode` directly and uses it as the inner `DecoratedTextField` focus node.
- `SearchModalBody` creates a local focus node, passes it into `QueryBar`, and uses it to return focus from search results back to the query input. A TODO notes this should request the surrounding focus instead.
- `DecoratedTextField` and `Dropdown` each create their own local surrounding focus node and pass both focus nodes into `InputFieldContainer`; `MultiselectDropdown` follows the same pattern and uses `surroundingFocusNode.requestFocus` on menu close.
- `QueryBar` is only used by `SearchModalBody`, so the `QueryBar.focusNode` API change currently has a narrow call-site impact.

## Approach

- Introduce an `InputFieldController` that owns both the inner input `FocusNode` and the surrounding container `FocusNode`, exposed as `inputFocusNode` and `surroundingFocusNode`.
- Add a `useInputFieldController()` hook that creates and disposes the controller, following the existing `useLoadingButtonController()` / custom hook patterns.
- Make `InputFieldContainer` require an `InputFieldController` instead of separate `inputFocusNode` / `surroundingFocusNode` parameters.
- Let higher-level input widgets such as `DecoratedTextField` create a controller by default or reuse one passed from a parent.
- Update `QueryBar` to accept this controller instead of a raw `FocusNode` option.
- Update `SearchModalBody` to use the controller to request surrounding focus from results instead of requesting focus on the inner query text field.

## Files to modify

- `lib/widgets/app/components/input_field_container.dart`
- New hook file, likely `lib/hooks/input_field_controller.dart`, unless colocating the hook with the controller is preferred.
- `lib/widgets/app/components/decorated_text_field.dart`
- `lib/widgets/app/components/dropdown.dart`
- `lib/widgets/generic/components/multiselect_dropdown.dart`
- `lib/widgets/generic/components/query_bar.dart`
- `lib/widgets/generic/components/search/search_modal_body.dart`

## Reuse

- Reuse the existing focus-management behavior in `InputFieldContainer` rather than duplicating focus logic in `QueryBar`.
- Reuse the established `surroundingFocusNode.requestFocus` pattern visible in `multiselect_dropdown.dart`.
- Reuse the project’s hook style from `lib/hooks/loading_button_controller.dart` for `useInputFieldController()` lifecycle management.
- Reuse custom hook patterns from `TimelineController` and `_MultiSelectTextEditingController` where debug labels / keys are useful.

## Steps

- [x] Confirm controller ownership/lifecycle with the user: controller should own both focus nodes, with a hook to handle disposal.
- [x] Confirm public API names: expose public `inputFocusNode` / `surroundingFocusNode` getters and `requestInputFocus()` / `requestSurroundingFocus()` methods.
- [x] Search all `QueryBar` call sites and any existing controller patterns before implementation.
- [x] Add `InputFieldController` with owned public `inputFocusNode` / `surroundingFocusNode` and methods `requestInputFocus()` / `requestSurroundingFocus()`.
- [x] Add `useInputFieldController()` to create/dispose the controller.
- [x] Refactor `InputFieldContainer` to require the controller and read both focus nodes from it.
- [x] Refactor `DecoratedTextField`, `Dropdown`, and `MultiselectDropdown` to accept an optional `InputFieldController` and create one via hook when absent.
- [x] Refactor `QueryBar` to accept/pass an optional `InputFieldController` instead of the raw `focusNode` parameter.
- [x] Refactor `SearchModalBody` to instantiate/pass the controller and request surrounding focus for search-results dismiss.
- [x] Update remaining compile errors/call sites from the `InputFieldContainer` API change.

## Verification

- [x] Run Dart analyzer or project lint command (`dart analyze`; only pre-existing warning/info remain).
- [ ] Manually verify search modal keyboard focus: entering the query field, dismissing results, returning to surrounding query-bar focus via `requestSurroundingFocus()`, and re-entering the input via `requestInputFocus()` / activation.
- [ ] Manually verify query suggestions still open/navigate/dismiss correctly.
