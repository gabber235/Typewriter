part of "../../content_renderer.dart";

extension MarkdownElementRendering on MarkdownElement {
  Widget render(PresentationRenderScope scope) => Builder(
    builder: (context) {
      final resolved = resolvePresentationColor(color, scope);
      if (resolved case TypeFailure(:final diagnostics)) {
        return presentationDiagnostic(context, diagnostics);
      }
      final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
      final textColor = resolved.valueOrNull;
      return MarkdownBody(
        data: scope.expressionText(value),
        selectable: true,
        styleSheet: textColor == null
            ? base
            : base.copyWith(
                a: base.a?.copyWith(color: textColor),
                p: base.p?.copyWith(color: textColor),
                code: base.code?.copyWith(color: textColor),
                h1: base.h1?.copyWith(color: textColor),
                h2: base.h2?.copyWith(color: textColor),
                h3: base.h3?.copyWith(color: textColor),
                h4: base.h4?.copyWith(color: textColor),
                h5: base.h5?.copyWith(color: textColor),
                h6: base.h6?.copyWith(color: textColor),
                em: base.em?.copyWith(color: textColor),
                strong: base.strong?.copyWith(color: textColor),
                del: base.del?.copyWith(color: textColor),
                blockquote: base.blockquote?.copyWith(color: textColor),
                img: base.img?.copyWith(color: textColor),
                checkbox: base.checkbox?.copyWith(color: textColor),
                listBullet: base.listBullet?.copyWith(color: textColor),
                tableHead: base.tableHead?.copyWith(color: textColor),
                tableBody: base.tableBody?.copyWith(color: textColor),
              ),
      );
    },
  );
}
