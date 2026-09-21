part of "authoring_session.dart";

Set<skir.ResourceId> _operationResources(skir.AuthoringOperation operation) =>
    switch (operation) {
      skir.AuthoringOperation_createWrapper(:final value) => {
        value.resource.id,
      },
      skir.AuthoringOperation_commitWrapper(:final value) => {value.id},
      skir.AuthoringOperation_deleteWrapper(:final value) => {value.id},
      skir.AuthoringOperation_unknown() => throw ArgumentError(
        "Unknown authoring operation",
      ),
    };
