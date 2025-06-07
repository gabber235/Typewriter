// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:widgetbook/widgetbook.dart' as _i1;
import 'package:widgetbook_workspace/stories/components/auto_scroller.stories.dart'
    as _i6;
import 'package:widgetbook_workspace/stories/components/book.stories.dart'
    as _i7;
import 'package:widgetbook_workspace/stories/components/color_swatch.dart'
    as _i5;
import 'package:widgetbook_workspace/stories/components/input_field.stories.dart'
    as _i2;
import 'package:widgetbook_workspace/stories/components/labeled_divider.stories.dart'
    as _i8;
import 'package:widgetbook_workspace/stories/components/loading_indicator.stories.dart'
    as _i9;
import 'package:widgetbook_workspace/stories/components/organization_icon.stories.dart'
    as _i10;
import 'package:widgetbook_workspace/stories/components/organization_selector.stories.dart'
    as _i11;
import 'package:widgetbook_workspace/stories/components/page_heading.stories.dart'
    as _i12;
import 'package:widgetbook_workspace/stories/components/retry_indicator.stories.dart'
    as _i13;
import 'package:widgetbook_workspace/stories/components/section.stories.dart'
    as _i14;
import 'package:widgetbook_workspace/stories/components/sidebar.stories.dart'
    as _i15;
import 'package:widgetbook_workspace/stories/components/tag.stories.dart'
    as _i16;
import 'package:widgetbook_workspace/stories/components/text_scroller.stories.dart'
    as _i17;
import 'package:widgetbook_workspace/stories/routes/organizations/library/route.dart'
    as _i4;
import 'package:widgetbook_workspace/stories/routes/route.dart' as _i3;
import 'package:widgetbook_workspace/stories/screens/error_screen.stories.dart'
    as _i18;

final directories = <_i1.WidgetbookNode>[
  _i1.WidgetbookFolder(
    name: 'material',
    children: [
      _i1.WidgetbookComponent(
        name: 'TextField',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i2.inputFieldUseCase,
          ),
          _i1.WidgetbookUseCase(
            name: 'Error',
            builder: _i2.inputFieldErrorUseCase,
          ),
          _i1.WidgetbookUseCase(
            name: 'With Prefix Icon',
            builder: _i2.inputFieldWithPrefixIconUseCase,
          ),
        ],
      ),
    ],
  ),
  _i1.WidgetbookFolder(
    name: 'routes',
    children: [
      _i1.WidgetbookLeafComponent(
        name: 'IndexPage',
        useCase: _i1.WidgetbookUseCase(
          name: 'IndexPage',
          builder: _i3.indexPageUseCase,
        ),
      ),
      _i1.WidgetbookFolder(
        name: 'organization',
        children: [
          _i1.WidgetbookFolder(
            name: 'library',
            children: [
              _i1.WidgetbookLeafComponent(
                name: 'LibraryPage',
                useCase: _i1.WidgetbookUseCase(
                  name: 'LibraryPage',
                  builder: _i4.libraryPageUseCase,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  _i1.WidgetbookFolder(
    name: 'stories',
    children: [
      _i1.WidgetbookFolder(
        name: 'components',
        children: [
          _i1.WidgetbookLeafComponent(
            name: 'ColorSwatchWidget',
            useCase: _i1.WidgetbookUseCase(
              name: 'Default',
              builder: _i5.colorSwatchUseCase,
            ),
          ),
        ],
      ),
    ],
  ),
  _i1.WidgetbookFolder(
    name: 'widgets',
    children: [
      _i1.WidgetbookFolder(
        name: 'generic',
        children: [
          _i1.WidgetbookFolder(
            name: 'components',
            children: [
              _i1.WidgetbookLeafComponent(
                name: 'AutoScroller',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Default',
                  builder: _i6.autoScrollerUseCase,
                ),
              ),
              _i1.WidgetbookLeafComponent(
                name: 'BookWidget',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Default',
                  builder: _i7.bookUseCase,
                ),
              ),
              _i1.WidgetbookLeafComponent(
                name: 'LabeledDivider',
                useCase: _i1.WidgetbookUseCase(
                  name: 'LabeledDivider',
                  builder: _i8.labeledDividerUseCase,
                ),
              ),
              _i1.WidgetbookLeafComponent(
                name: 'LoadingIndicator',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Default',
                  builder: _i9.loadingIndicatorUseCase,
                ),
              ),
              _i1.WidgetbookComponent(
                name: 'OrganizationIcon',
                useCases: [
                  _i1.WidgetbookUseCase(
                    name: 'Default',
                    builder: _i10.organizationIconUseCase,
                  ),
                  _i1.WidgetbookUseCase(
                    name: 'Placeholder',
                    builder: _i10.organizationIconPlaceholderUseCase,
                  ),
                ],
              ),
              _i1.WidgetbookLeafComponent(
                name: 'OrganizationSelector',
                useCase: _i1.WidgetbookUseCase(
                  name: 'OrganizationSelector',
                  builder: _i11.organizationSelectorUseCase,
                ),
              ),
              _i1.WidgetbookLeafComponent(
                name: 'PageHeading',
                useCase: _i1.WidgetbookUseCase(
                  name: 'PageHeading',
                  builder: _i12.pageHeadingUseCase,
                ),
              ),
              _i1.WidgetbookLeafComponent(
                name: 'RetryIndicator',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Default',
                  builder: _i13.retryIndicatorUseCase,
                ),
              ),
              _i1.WidgetbookLeafComponent(
                name: 'Section',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Default',
                  builder: _i14.sectionUseCase,
                ),
              ),
              _i1.WidgetbookLeafComponent(
                name: 'Sidebar',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Default',
                  builder: _i15.sidebarUseCase,
                ),
              ),
              _i1.WidgetbookLeafComponent(
                name: 'TagWidget',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Default',
                  builder: _i16.tagUseCase,
                ),
              ),
              _i1.WidgetbookLeafComponent(
                name: 'TextScroller',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Default',
                  builder: _i17.textScrollerUseCase,
                ),
              ),
            ],
          ),
          _i1.WidgetbookFolder(
            name: 'screens',
            children: [
              _i1.WidgetbookLeafComponent(
                name: 'ErrorScreen',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Default',
                  builder: _i18.errorScreenUseCase,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
