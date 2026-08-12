part of "../../composite_input_renderer.dart";

class _CollectionEmptyState extends StatelessWidget {
  const _CollectionEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: context.spacing.space2),
    child: SizedBox(
      width: double.infinity,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );
}

TypedExpression _collectionIntegerExpression(int value) => TypedExpression(
  resultType: const IntegerType(width: IntegerWidth.signed64),
  expression: LiteralExpression(IntegerValue(BigInt.from(value))),
);

TypedExpression _collectionIconExpression(String value) => TypedExpression(
  resultType: NamedType(standardTypeRefs.icon),
  expression: LiteralExpression(IconValue.from(value).typedValue),
);
