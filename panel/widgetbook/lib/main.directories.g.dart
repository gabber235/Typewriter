// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:widgetbook/widgetbook.dart' as _widgetbook;
import 'package:widgetbook_workspace/stories/components/auto_scroller.stories.dart'
    as _widgetbook_workspace_stories_components_auto_scroller_stories;
import 'package:widgetbook_workspace/stories/components/book.stories.dart'
    as _widgetbook_workspace_stories_components_book_stories;
import 'package:widgetbook_workspace/stories/components/color_swatch.dart'
    as _widgetbook_workspace_stories_components_color_swatch;
import 'package:widgetbook_workspace/stories/components/custom_appbar.stories.dart'
    as _widgetbook_workspace_stories_components_custom_appbar_stories;
import 'package:widgetbook_workspace/stories/components/editors/boolean_editor.stories.dart'
    as _widgetbook_workspace_stories_components_editors_boolean_editor_stories;
import 'package:widgetbook_workspace/stories/components/editors/editors.stories.dart'
    as _widgetbook_workspace_stories_components_editors_editors_stories;
import 'package:widgetbook_workspace/stories/components/editors/list_editor.stories.dart'
    as _widgetbook_workspace_stories_components_editors_list_editor_stories;
import 'package:widgetbook_workspace/stories/components/editors/number_editor.stories.dart'
    as _widgetbook_workspace_stories_components_editors_number_editor_stories;
import 'package:widgetbook_workspace/stories/components/editors/string_editor.stories.dart'
    as _widgetbook_workspace_stories_components_editors_string_editor_stories;
import 'package:widgetbook_workspace/stories/components/input_field.stories.dart'
    as _widgetbook_workspace_stories_components_input_field_stories;
import 'package:widgetbook_workspace/stories/components/labeled_divider.stories.dart'
    as _widgetbook_workspace_stories_components_labeled_divider_stories;
import 'package:widgetbook_workspace/stories/components/loading_indicator.stories.dart'
    as _widgetbook_workspace_stories_components_loading_indicator_stories;
import 'package:widgetbook_workspace/stories/components/organization_icon.stories.dart'
    as _widgetbook_workspace_stories_components_organization_icon_stories;
import 'package:widgetbook_workspace/stories/components/organization_selector.stories.dart'
    as _widgetbook_workspace_stories_components_organization_selector_stories;
import 'package:widgetbook_workspace/stories/components/page_heading.stories.dart'
    as _widgetbook_workspace_stories_components_page_heading_stories;
import 'package:widgetbook_workspace/stories/components/retry_indicator.stories.dart'
    as _widgetbook_workspace_stories_components_retry_indicator_stories;
import 'package:widgetbook_workspace/stories/components/section.stories.dart'
    as _widgetbook_workspace_stories_components_section_stories;
import 'package:widgetbook_workspace/stories/components/selectable.stories.dart'
    as _widgetbook_workspace_stories_components_selectable_stories;
import 'package:widgetbook_workspace/stories/components/sidebar.stories.dart'
    as _widgetbook_workspace_stories_components_sidebar_stories;
import 'package:widgetbook_workspace/stories/components/tag.stories.dart'
    as _widgetbook_workspace_stories_components_tag_stories;
import 'package:widgetbook_workspace/stories/components/text_scroller.stories.dart'
    as _widgetbook_workspace_stories_components_text_scroller_stories;
import 'package:widgetbook_workspace/stories/routes/organizations/library/route.dart'
    as _widgetbook_workspace_stories_routes_organizations_library_route;
import 'package:widgetbook_workspace/stories/routes/route.dart'
    as _widgetbook_workspace_stories_routes_route;
import 'package:widgetbook_workspace/stories/screens/error_screen.stories.dart'
    as _widgetbook_workspace_stories_screens_error_screen_stories;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'material',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'TextField',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder:
                _widgetbook_workspace_stories_components_input_field_stories
                    .inputFieldUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Error',
            builder:
                _widgetbook_workspace_stories_components_input_field_stories
                    .inputFieldErrorUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'With Prefix Icon',
            builder:
                _widgetbook_workspace_stories_components_input_field_stories
                    .inputFieldWithPrefixIconUseCase,
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookFolder(
    name: 'routes',
    children: [
      _widgetbook.WidgetbookLeafComponent(
        name: 'IndexPage',
        useCase: _widgetbook.WidgetbookUseCase(
          name: 'IndexPage',
          builder: _widgetbook_workspace_stories_routes_route.indexPageUseCase,
        ),
      ),
      _widgetbook.WidgetbookFolder(
        name: 'organization',
        children: [
          _widgetbook.WidgetbookFolder(
            name: 'library',
            children: [
              _widgetbook.WidgetbookLeafComponent(
                name: 'LibraryPage',
                useCase: _widgetbook.WidgetbookUseCase(
                  name: 'LibraryPage',
                  builder:
                      _widgetbook_workspace_stories_routes_organizations_library_route
                          .libraryPageUseCase,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookFolder(
    name: 'stories',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'components',
        children: [
          _widgetbook.WidgetbookLeafComponent(
            name: 'ColorSwatchWidget',
            useCase: _widgetbook.WidgetbookUseCase(
              name: 'Default',
              builder:
                  _widgetbook_workspace_stories_components_color_swatch
                      .colorSwatchUseCase,
            ),
          ),
          _widgetbook.WidgetbookLeafComponent(
            name: 'SelectableBox',
            useCase: _widgetbook.WidgetbookUseCase(
              name: 'Selectable Boxes',
              builder:
                  _widgetbook_workspace_stories_components_selectable_stories
                      .selectableUseCase,
            ),
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookFolder(
    name: 'widgets',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'app',
        children: [
          _widgetbook.WidgetbookFolder(
            name: 'components',
            children: [
              _widgetbook.WidgetbookFolder(
                name: 'inspector',
                children: [
                  _widgetbook.WidgetbookFolder(
                    name: 'editors',
                    children: [
                      _widgetbook.WidgetbookLeafComponent(
                        name: 'BooleanEditor',
                        useCase: _widgetbook.WidgetbookUseCase(
                          name: 'Default',
                          builder:
                              _widgetbook_workspace_stories_components_editors_boolean_editor_stories
                                  .booleanEditorUseCase,
                        ),
                      ),
                      _widgetbook.WidgetbookComponent(
                        name: 'FieldValueEditor',
                        useCases: [
                          _widgetbook.WidgetbookUseCase(
                            name: 'Conflict',
                            builder:
                                _widgetbook_workspace_stories_components_editors_editors_stories
                                    .conflictValueEditorUseCase,
                          ),
                          _widgetbook.WidgetbookUseCase(
                            name: 'Loading',
                            builder:
                                _widgetbook_workspace_stories_components_editors_editors_stories
                                    .loadingEditorUseCase,
                          ),
                          _widgetbook.WidgetbookUseCase(
                            name: 'None',
                            builder:
                                _widgetbook_workspace_stories_components_editors_editors_stories
                                    .noneValueEditorUseCase,
                          ),
                          _widgetbook.WidgetbookUseCase(
                            name: 'Value',
                            builder:
                                _widgetbook_workspace_stories_components_editors_editors_stories
                                    .valueEditorUseCase,
                          ),
                        ],
                      ),
                      _widgetbook.WidgetbookLeafComponent(
                        name: 'ListEditor',
                        useCase: _widgetbook.WidgetbookUseCase(
                          name: 'Default',
                          builder:
                              _widgetbook_workspace_stories_components_editors_list_editor_stories
                                  .listEditorUseCase,
                        ),
                      ),
                      _widgetbook.WidgetbookLeafComponent(
                        name: 'NumberEditor',
                        useCase: _widgetbook.WidgetbookUseCase(
                          name: 'Default',
                          builder:
                              _widgetbook_workspace_stories_components_editors_number_editor_stories
                                  .numberEditorUseCase,
                        ),
                      ),
                      _widgetbook.WidgetbookLeafComponent(
                        name: 'StringEditor',
                        useCase: _widgetbook.WidgetbookUseCase(
                          name: 'Default',
                          builder:
                              _widgetbook_workspace_stories_components_editors_string_editor_stories
                                  .stringEditorUseCase,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'generic',
        children: [
          _widgetbook.WidgetbookFolder(
            name: 'components',
            children: [
              _widgetbook.WidgetbookLeafComponent(
                name: 'AutoScroller',
                useCase: _widgetbook.WidgetbookUseCase(
                  name: 'Default',
                  builder:
                      _widgetbook_workspace_stories_components_auto_scroller_stories
                          .autoScrollerUseCase,
                ),
              ),
              _widgetbook.WidgetbookLeafComponent(
                name: 'BookWidget',
                useCase: _widgetbook.WidgetbookUseCase(
                  name: 'Default',
                  builder:
                      _widgetbook_workspace_stories_components_book_stories
                          .bookUseCase,
                ),
              ),
              _widgetbook.WidgetbookLeafComponent(
                name: 'CustomAppBar',
                useCase: _widgetbook.WidgetbookUseCase(
                  name: 'Default',
                  builder:
                      _widgetbook_workspace_stories_components_custom_appbar_stories
                          .customAppBarUseCase,
                ),
              ),
              _widgetbook.WidgetbookLeafComponent(
                name: 'LabeledDivider',
                useCase: _widgetbook.WidgetbookUseCase(
                  name: 'LabeledDivider',
                  builder:
                      _widgetbook_workspace_stories_components_labeled_divider_stories
                          .labeledDividerUseCase,
                ),
              ),
              _widgetbook.WidgetbookLeafComponent(
                name: 'LoadingIndicator',
                useCase: _widgetbook.WidgetbookUseCase(
                  name: 'Default',
                  builder:
                      _widgetbook_workspace_stories_components_loading_indicator_stories
                          .loadingIndicatorUseCase,
                ),
              ),
              _widgetbook.WidgetbookComponent(
                name: 'OrganizationIcon',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Default',
                    builder:
                        _widgetbook_workspace_stories_components_organization_icon_stories
                            .organizationIconUseCase,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Placeholder',
                    builder:
                        _widgetbook_workspace_stories_components_organization_icon_stories
                            .organizationIconPlaceholderUseCase,
                  ),
                ],
              ),
              _widgetbook.WidgetbookLeafComponent(
                name: 'OrganizationSelector',
                useCase: _widgetbook.WidgetbookUseCase(
                  name: 'OrganizationSelector',
                  builder:
                      _widgetbook_workspace_stories_components_organization_selector_stories
                          .organizationSelectorUseCase,
                ),
              ),
              _widgetbook.WidgetbookLeafComponent(
                name: 'PageHeading',
                useCase: _widgetbook.WidgetbookUseCase(
                  name: 'PageHeading',
                  builder:
                      _widgetbook_workspace_stories_components_page_heading_stories
                          .pageHeadingUseCase,
                ),
              ),
              _widgetbook.WidgetbookLeafComponent(
                name: 'RetryIndicator',
                useCase: _widgetbook.WidgetbookUseCase(
                  name: 'Default',
                  builder:
                      _widgetbook_workspace_stories_components_retry_indicator_stories
                          .retryIndicatorUseCase,
                ),
              ),
              _widgetbook.WidgetbookLeafComponent(
                name: 'Section',
                useCase: _widgetbook.WidgetbookUseCase(
                  name: 'Default',
                  builder:
                      _widgetbook_workspace_stories_components_section_stories
                          .sectionUseCase,
                ),
              ),
              _widgetbook.WidgetbookLeafComponent(
                name: 'Sidebar',
                useCase: _widgetbook.WidgetbookUseCase(
                  name: 'Default',
                  builder:
                      _widgetbook_workspace_stories_components_sidebar_stories
                          .sidebarUseCase,
                ),
              ),
              _widgetbook.WidgetbookLeafComponent(
                name: 'TagWidget',
                useCase: _widgetbook.WidgetbookUseCase(
                  name: 'Default',
                  builder:
                      _widgetbook_workspace_stories_components_tag_stories
                          .tagUseCase,
                ),
              ),
              _widgetbook.WidgetbookLeafComponent(
                name: 'TextScroller',
                useCase: _widgetbook.WidgetbookUseCase(
                  name: 'Default',
                  builder:
                      _widgetbook_workspace_stories_components_text_scroller_stories
                          .textScrollerUseCase,
                ),
              ),
            ],
          ),
          _widgetbook.WidgetbookFolder(
            name: 'screens',
            children: [
              _widgetbook.WidgetbookLeafComponent(
                name: 'ErrorScreen',
                useCase: _widgetbook.WidgetbookUseCase(
                  name: 'Default',
                  builder:
                      _widgetbook_workspace_stories_screens_error_screen_stories
                          .errorScreenUseCase,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
