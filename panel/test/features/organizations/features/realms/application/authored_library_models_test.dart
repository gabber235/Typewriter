import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("book reads tagged visual values and relation items", () {
    final tag = skir.ResourceId(value: "tag:one");
    final book = Book.fromAuthoring(
      skir.AuthoringResource(
        id: skir.ResourceId(value: "book:one"),
        definition: skir.ResourceDefinitionId(value: "typewriter.book"),
        content: skir.AuthoringRecord(
          configuration: skir.TypeSelection.unknown,
          fields: [
            _field("title", skir.DataValue.wrapStringValue("Guide")),
            _field(
              "icon",
              _named(
                skir.DataValue.createRecord(
                  fields: [
                    _field(
                      "value",
                      skir.DataValue.wrapStringValue("material-symbols:book"),
                    ),
                  ],
                ),
                actualType: _iconifyType,
              ),
            ),
            _field("color", _named(skir.DataValue.wrapInteger("4281558681"))),
            _field(
              "tags",
              _named(
                skir.DataValue.createSetValue(
                  items: [
                    skir.ListItem(
                      id: skir.ItemId(value: "tag-item"),
                      value: _link(tag),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    expect(book.title, "Guide");
    expect(book.icon, "material-symbols:book");
    expect(book.color.toARGB32(), 0xff336699);
    expect(book.tagIds, [tag]);
  });

  test("book reads the generated SVG icon payload", () {
    const source = "<svg viewBox=\"0 0 1 1\"></svg>";
    final book = Book.fromAuthoring(
      skir.AuthoringResource(
        id: skir.ResourceId(value: "book:svg"),
        definition: skir.ResourceDefinitionId(value: "typewriter.book"),
        content: skir.AuthoringRecord(
          configuration: skir.TypeSelection.unknown,
          fields: [
            _field("title", skir.DataValue.wrapStringValue("SVG guide")),
            _field(
              "icon",
              _named(
                skir.DataValue.createRecord(
                  fields: [
                    _field("source", skir.DataValue.wrapStringValue(source)),
                  ],
                ),
                actualType: _svgType,
              ),
            ),
            _field("color", _named(skir.DataValue.wrapInteger("4281558681"))),
            _field("tags", _named(skir.DataValue.createSetValue(items: []))),
          ],
        ),
      ),
    );

    expect(book.icon, source);
  });

  test("tag reads tagged placement and parent links", () {
    final parent = skir.ResourceId(value: "tag:parent");
    final tag = Tag.fromAuthoring(
      skir.AuthoringResource(
        id: skir.ResourceId(value: "tag:child"),
        definition: skir.ResourceDefinitionId(value: "typewriter.tag"),
        content: skir.AuthoringRecord(
          configuration: skir.TypeSelection.unknown,
          fields: [
            _field("name", skir.DataValue.wrapStringValue("Child")),
            _field("color", _named(skir.DataValue.wrapInteger("4289449455"))),
            _field(
              "parents",
              _named(
                skir.DataValue.createSetValue(
                  items: [
                    skir.ListItem(
                      id: skir.ItemId(value: "parent-item"),
                      value: _link(parent),
                    ),
                  ],
                ),
              ),
            ),
            _field(
              "placement",
              _named(
                skir.DataValue.createRecord(
                  fields: [
                    _field("x", skir.DataValue.wrapInteger("2")),
                    _field("y", skir.DataValue.wrapInteger("3")),
                    _field("width", skir.DataValue.wrapInteger("4")),
                    _field("height", skir.DataValue.wrapInteger("1")),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    expect(tag.name, "Child");
    expect(tag.color.toARGB32(), 0xffabcdef);
    expect(tag.parentIds, [parent]);
    expect(
      (
        tag.placement.x,
        tag.placement.y,
        tag.placement.width,
        tag.placement.height,
      ),
      (2, 3, 4, 1),
    );
  });

  test("page retains pending configuration and ordered element links", () {
    final element = skir.ResourceId(value: "element:one");
    final configuration = skir.TypeSelection.createPending(
      definition: skir.TypeDefinitionId(
        typeId: skir.TypeId.createDeclared(
          value: "0123456789abcdef0123456789abcdef",
        ),
        revision: 1,
      ),
      arguments: const [skir.ArgumentSelection.unfilled],
    );
    final pageResource = skir.AuthoringResource(
      id: skir.ResourceId(value: "page:one"),
      definition: skir.ResourceDefinitionId(value: "typewriter.page"),
      content: skir.AuthoringRecord(
        configuration: configuration,
        fields: [
          _field("book", _link(skir.ResourceId(value: "book:one"))),
          _field("name", skir.DataValue.wrapStringValue("Opening")),
          _field("chapter", _named(skir.DataValue.wrapStringValue("intro"))),
          _field("priority", skir.DataValue.wrapInteger("4")),
          _field(
            "elements",
            _named(
              skir.DataValue.createListValue(
                items: [
                  skir.ListItem(
                    id: skir.ItemId(value: "element-item"),
                    value: _link(element),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    final page = Page.fromAuthoring(pageResource);

    expect(page.configuration, configuration);
    expect(page.bookId, skir.ResourceId(value: "book:one"));
    expect((page.name, page.chapter, page.priority), ("Opening", "intro", 4));
    final elementIds =
        (pageResource.content.authoredField("elements")?.authoredItems ??
                const <skir.ListItem>[])
            .map((item) => item.value.authoredLink?.target.resource)
            .nonNulls
            .toList(growable: false);
    expect(elementIds, [element]);
  });

  test("incomplete library resources coexist with complete projections", () {
    final retainedTag = skir.ResourceId(value: "tag:retained");
    final retainedElement = skir.ResourceId(value: "element:retained");
    final books = [
      Book.fromAuthoring(
        _resource("book:complete", "typewriter.book", [
          _field("title", skir.DataValue.wrapStringValue("Complete")),
          _field(
            "icon",
            _named(
              skir.DataValue.createRecord(
                fields: [
                  _field(
                    "value",
                    skir.DataValue.wrapStringValue("material-symbols:book"),
                  ),
                ],
              ),
              actualType: _iconifyType,
            ),
          ),
          _field("color", _named(skir.DataValue.wrapInteger("4281558681"))),
          _field("tags", _named(skir.DataValue.createSetValue(items: []))),
        ]),
      ),
      Book.fromAuthoring(
        _resource("book:incomplete", "typewriter.book", [
          _field("title", skir.DataValue.unfilled),
          _field("icon", skir.DataValue.unfilled),
          _field("color", skir.DataValue.unfilled),
          _field(
            "tags",
            _named(
              skir.DataValue.createSetValue(
                items: [
                  skir.ListItem(
                    id: skir.ItemId(value: "retained-tag"),
                    value: _link(retainedTag),
                  ),
                  skir.ListItem(
                    id: skir.ItemId(value: "unfinished-tag"),
                    value: skir.DataValue.unfilled,
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    ];
    final tags = [
      Tag.fromAuthoring(
        _resource("tag:complete", "typewriter.tag", [
          _field("name", skir.DataValue.wrapStringValue("Complete")),
          _field("color", _named(skir.DataValue.wrapInteger("4289449455"))),
          _field("parents", _named(skir.DataValue.createSetValue(items: []))),
          _field(
            "placement",
            _named(
              skir.DataValue.createRecord(
                fields: [
                  _field("x", skir.DataValue.wrapInteger("2")),
                  _field("y", skir.DataValue.wrapInteger("3")),
                  _field("width", skir.DataValue.wrapInteger("4")),
                  _field("height", skir.DataValue.wrapInteger("1")),
                ],
              ),
            ),
          ),
        ]),
      ),
      Tag.fromAuthoring(
        _resource("tag:incomplete", "typewriter.tag", [
          _field("name", skir.DataValue.unfilled),
          _field("color", skir.DataValue.unfilled),
          _field(
            "parents",
            _named(
              skir.DataValue.createSetValue(
                items: [
                  skir.ListItem(
                    id: skir.ItemId(value: "retained-parent"),
                    value: _link(retainedTag),
                  ),
                  skir.ListItem(
                    id: skir.ItemId(value: "unfinished-parent"),
                    value: skir.DataValue.unfilled,
                  ),
                ],
              ),
            ),
          ),
          _field(
            "placement",
            _named(
              skir.DataValue.createRecord(
                fields: [
                  _field("x", skir.DataValue.unfilled),
                  _field("y", skir.DataValue.wrapInteger("7")),
                  _field("width", skir.DataValue.wrapInteger("0")),
                  _field("height", skir.DataValue.unfilled),
                ],
              ),
            ),
          ),
        ]),
      ),
    ];
    final pageResources = [
      _resource("page:complete", "typewriter.page", [
        _field("book", _link(skir.ResourceId(value: "book:complete"))),
        _field("name", skir.DataValue.wrapStringValue("Complete")),
        _field("chapter", _named(skir.DataValue.wrapStringValue("one"))),
        _field("priority", skir.DataValue.wrapInteger("1")),
        _field("elements", _named(skir.DataValue.createListValue(items: []))),
      ]),
      _resource("page:incomplete", "typewriter.page", [
        _field("book", skir.DataValue.unfilled),
        _field("name", skir.DataValue.unfilled),
        _field("chapter", skir.DataValue.unfilled),
        _field("priority", skir.DataValue.unfilled),
        _field(
          "elements",
          _named(
            skir.DataValue.createListValue(
              items: [
                skir.ListItem(
                  id: skir.ItemId(value: "retained-element"),
                  value: _link(retainedElement),
                ),
                skir.ListItem(
                  id: skir.ItemId(value: "unfinished-element"),
                  value: skir.DataValue.unfilled,
                ),
              ],
            ),
          ),
        ),
      ]),
    ];
    final pages = pageResources.map(Page.fromAuthoring).toList();

    expect(books.map((value) => value.title), ["Complete", "Unnamed Book"]);
    expect(books.last.icon, "material-symbols:book");
    expect(books.last.color.toARGB32(), 0xff3f51b5);
    expect(books.last.tagIds, [retainedTag]);
    expect(tags.map((value) => value.name), ["Complete", "Unnamed Tag"]);
    expect(tags.last.color.toARGB32(), 0xff9e9e9e);
    expect(tags.last.parentIds, [retainedTag]);
    expect(
      (
        tags.last.placement.x,
        tags.last.placement.y,
        tags.last.placement.width,
        tags.last.placement.height,
      ),
      (0, 7, 1, 1),
    );
    expect(pages.map((value) => value.name), ["Complete", "Unnamed Page"]);
    expect(pages.last.bookId, isNull);
    expect((pages.last.chapter, pages.last.priority), ("", 0));
    final retainedElementIds =
        (pageResources.last.content.authoredField("elements")?.authoredItems ??
                const <skir.ListItem>[])
            .map((item) => item.value.authoredLink?.target.resource)
            .nonNulls
            .toList(growable: false);
    expect(retainedElementIds, [retainedElement]);
  });
}

skir.AuthoringResource _resource(
  String id,
  String definition,
  List<skir.FieldValue> fields,
) => skir.AuthoringResource(
  id: skir.ResourceId(value: id),
  definition: skir.ResourceDefinitionId(value: definition),
  content: skir.AuthoringRecord(
    configuration: skir.TypeSelection.unknown,
    fields: fields,
  ),
);

skir.FieldValue _field(String name, skir.DataValue value) =>
    skir.FieldValue(name: name, value: value);

skir.DataValue _named(
  skir.DataValue payload, {
  skir.NamedTypeUse? actualType,
}) => skir.DataValue.createNamed(
  actualType: actualType ?? skir.NamedTypeUse.defaultInstance,
  payload: payload,
);

skir.DataValue _link(skir.ResourceId target) => _named(
  skir.DataValue.createLink(
    endpoint: skir.EndpointId(value: "test.endpoint"),
    target: skir.LinkTarget(resource: target, opposite: null),
  ),
);

final _iconifyType = skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(
      value: "3845952a4d714e23ad55f07051669930",
    ),
    revision: 1,
  ),
  arguments: const [],
);

final _svgType = skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(
      value: "67ed1a5b0e534c05b8d233ef9783971b",
    ),
    revision: 1,
  ),
  arguments: const [],
);
