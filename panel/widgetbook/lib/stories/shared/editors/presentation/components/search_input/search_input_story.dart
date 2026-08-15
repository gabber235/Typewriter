import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const searchStoryRootBinding = BindingReference(bindingId: BindingId(0));

class SearchInputStory extends StatefulWidget {
  const SearchInputStory({
    required this.element,
    required this.type,
    required this.initialValue,
    required this.width,
    this.sourceBuilder,
    this.enabled = true,
    this.readOnly = false,
    super.key,
  });

  final SearchInputElement element;
  final TypeExpression type;
  final DataValue initialValue;
  final double width;
  final PresentationSearchSourceBuilder? sourceBuilder;
  final bool enabled;
  final bool readOnly;

  @override
  State<SearchInputStory> createState() => _SearchInputStoryState();
}

class _SearchInputStoryState extends State<SearchInputStory> {
  late DataValue _value = widget.initialValue;
  var _revision = 0;
  final _expansionStore = HeaderExpansionStore();

  @override
  void didUpdateWidget(SearchInputStory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue ||
        oldWidget.type != widget.type) {
      _value = widget.initialValue;
      _revision = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final registry = TypeRegistry(const TypeCatalog([]));
    final snapshot = BindingSnapshot(
      type: widget.type,
      value: _value,
      revision: _revision,
      writable: !widget.readOnly,
    );
    final environment = BindingEnvironment({const BindingId(0): snapshot});
    final scope = PresentationRenderScope(
      expressions: ExpressionContext(bindings: environment),
      registry: registry,
      budget: const ExpressionBudget(),
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      setBinding: (reference, value, context, aliases) {
        if (reference.bindingId != const BindingId(0)) return;
        setState(() {
          _value = value;
          _revision++;
        });
      },
      executeAction: (_, _, _) {},
      resolvePresentation: (_, _) => null,
      expansionStore: _expansionStore,
    );
    final binding = environment.resolve(searchStoryRootBinding).valueOrNull!;
    return FakeApp(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.width),
        child: Section(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LabeledControl(
              control: widget.element.control,
              scope: scope,
              child: PresentationSearchInput(
                element: widget.element,
                binding: binding,
                scope: scope,
                maximumExtent: _maximumExtent(scope),
                sourceBuilder: widget.sourceBuilder,
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _maximumExtent(PresentationRenderScope scope) {
    final value = scope.evaluate(widget.element.maximumExtent).valueOrNull;
    return switch (value) {
      FloatValue(:final value) => value,
      IntegerValue(:final value) => value.toDouble(),
      _ => 280,
    };
  }
}
