//! The entity index the change report and the review tools share: the functions, types and tests
//! of the Rust, Kotlin and Dart sources at one snapshot, parsed with tree-sitter, with the names
//! each one references. References are names, not resolved symbols, narrowed by imports (see
//! [`Snapshot::callers_of`]), so a caller can be a false one; output says so.

use std::collections::hash_map::DefaultHasher;
use std::collections::{BTreeMap, HashMap, HashSet};
use std::hash::{Hash, Hasher};
use std::path::{Path, PathBuf};
use std::sync::Mutex;
use std::thread;

use anyhow::Result;
use serde::Serialize;
use tree_sitter::{Node, Parser};

use super::change;
use crate::Context;

#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
pub enum Language {
    Rust,
    Kotlin,
    Dart,
}

impl Language {
    pub fn of(path: &Path) -> Option<Self> {
        match path.extension()?.to_str()? {
            "rs" => Some(Self::Rust),
            "kt" | "kts" => Some(Self::Kotlin),
            "dart" => Some(Self::Dart),
            _ => None,
        }
    }

    fn grammar(self) -> tree_sitter::Language {
        match self {
            Self::Rust => tree_sitter_rust::LANGUAGE.into(),
            Self::Kotlin => tree_sitter_kotlin_ng::LANGUAGE.into(),
            Self::Dart => tree_sitter_dart::LANGUAGE.into(),
        }
    }

    fn separator(self) -> &'static str {
        match self {
            Self::Rust => "::",
            Self::Kotlin | Self::Dart => ".",
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Serialize, Debug)]
#[serde(rename_all = "lowercase")]
pub enum EntityKind {
    Function,
    Type,
    Test,
}

impl EntityKind {
    pub fn label(self) -> &'static str {
        match self {
            Self::Function => "fn",
            Self::Type => "type",
            Self::Test => "test",
        }
    }
}

/// A name used inside an entity: a call, a macro, a type, or a function used as a value.
pub struct Reference {
    pub name: String,
    pub line: u32,
    /// Called on a receiver (`value.name()`), so the caller needs no import that names the
    /// receiver's type.
    pub method: bool,
}

pub struct Entity {
    pub name: String,
    /// The name with its owners (`Type::method`, `Suite.case`); unique enough within a file.
    pub qualified: String,
    pub kind: EntityKind,
    pub file: PathBuf,
    pub language: Language,
    /// First and last line, 1 based.
    pub start: u32,
    pub end: u32,
    /// Line the declaration ends on, where the body opens; `end` without a body.
    pub signature_end: u32,
    bytes: (usize, usize),
    /// Part of the module's interface: `pub` in Rust, not private or internal in Kotlin, no
    /// leading underscore in Dart.
    pub public: bool,
    /// Implements a trait method, overrides a member or overloads an operator, so callers reach
    /// it through the parent or through syntax rather than by name.
    pub overrides: bool,
    /// A test marked to be skipped.
    pub disabled: bool,
    /// The declaration up to its body, whitespace collapsed.
    pub signature: String,
    /// The entity's own text without nested entities, whitespace insensitive.
    pub fingerprint: u64,
    pub references: Vec<Reference>,
    /// Calls, by callee name, in source order.
    pub calls: Vec<String>,
    /// Top level statements of the body.
    pub statements: usize,
    /// Conditional arms: `if`, `else if`, match and `when` arms, `case`, ternaries.
    pub branches: usize,
    /// Assertions of a test, whitespace collapsed.
    pub assertions: Vec<String>,
}

impl Entity {
    pub fn location(&self) -> String {
        format!("{}:{}", self.file.display(), self.start)
    }
}

pub struct SourceFile {
    pub text: String,
    /// Import and `use` paths, as written.
    pub imports: Vec<String>,
    /// The Kotlin package or the Rust crate directory, so same module references need no import.
    pub module: Option<String>,
    /// Names used outside any entity, including every word of the imports.
    pub mentions: HashSet<String>,
}

/// Every entity of one snapshot of the repository.
pub struct Snapshot {
    pub files: BTreeMap<PathBuf, SourceFile>,
    pub entities: Vec<Entity>,
    /// Entity indexes that reference a name, once per entity.
    referrers: HashMap<String, Vec<usize>>,
    /// The index range of each file's entities; entities are stored grouped by file.
    by_file: HashMap<PathBuf, std::ops::Range<usize>>,
}

impl Snapshot {
    /// The working tree.
    pub fn head(ctx: &Context) -> Result<Self> {
        Ok(Self::build(change::working_files(ctx, |path| {
            Language::of(path).is_some()
        })?))
    }

    /// The tree of `commit`.
    pub fn at(ctx: &Context, commit: &str) -> Result<Self> {
        Ok(Self::build(change::files_at(ctx, commit, |path| {
            Language::of(path).is_some()
        })?))
    }

    /// Indexes `files`, parsing on every core.
    pub fn build(files: BTreeMap<PathBuf, String>) -> Self {
        let queue = Mutex::new(files.into_iter());
        let parsed = Mutex::new(Vec::new());
        let workers = thread::available_parallelism().map_or(4, usize::from);
        thread::scope(|scope| {
            for _ in 0..workers {
                scope.spawn(|| {
                    let mut parsers = HashMap::new();
                    loop {
                        let Some((path, text)) = queue.lock().unwrap().next() else {
                            break;
                        };
                        let Some(language) = Language::of(&path) else {
                            continue;
                        };
                        let parser = parsers.entry(language).or_insert_with(|| {
                            let mut parser = Parser::new();
                            parser
                                .set_language(&language.grammar())
                                .expect("the grammar matches the tree-sitter version");
                            parser
                        });
                        let (source, entities) = index_file(parser, language, &path, text);
                        parsed.lock().unwrap().push((path, source, entities));
                    }
                });
            }
        });
        let mut parsed = parsed.into_inner().unwrap();
        parsed.sort_by(|a, b| a.0.cmp(&b.0));
        let mut files = BTreeMap::new();
        let mut entities = Vec::new();
        let mut by_file = HashMap::new();
        for (path, source, file_entities) in parsed {
            let start = entities.len();
            entities.extend(file_entities);
            by_file.insert(path.clone(), start..entities.len());
            files.insert(path, source);
        }
        let mut referrers: HashMap<String, Vec<usize>> = HashMap::new();
        for (index, entity) in entities.iter().enumerate() {
            for reference in &entity.references {
                let list = referrers.entry(reference.name.clone()).or_default();
                if list.last() != Some(&index) {
                    list.push(index);
                }
            }
        }
        Self {
            files,
            entities,
            referrers,
            by_file,
        }
    }

    /// Whether any file names `name` outside an entity: in an import, a constant or a top level
    /// property.
    pub fn is_mentioned(&self, name: &str) -> bool {
        self.files.values().any(|file| file.mentions.contains(name))
    }

    /// The positions in [`Self::entities`] of the entities of `file`, in source order.
    pub fn file_range(&self, file: &Path) -> std::ops::Range<usize> {
        self.by_file.get(file).map_or(0..0, Clone::clone)
    }

    /// The entities of `file`, in source order.
    pub fn in_file(&self, file: &Path) -> &[Entity] {
        &self.entities[self.file_range(file)]
    }

    /// The position of `entity` in [`Self::entities`], when it belongs to this snapshot.
    pub fn index_of(&self, entity: &Entity) -> Option<usize> {
        let range = self.by_file.get(&entity.file)?;
        self.entities[range.clone()]
            .iter()
            .position(|candidate| std::ptr::eq(candidate, entity))
            .map(|offset| range.start + offset)
    }

    /// The entity of `file` named `symbol`: its qualified name, or its plain name when that is
    /// unambiguous in the file.
    pub fn find(&self, file: &Path, symbol: &str) -> Option<&Entity> {
        let in_file = self.in_file(file);
        in_file
            .iter()
            .find(|entity| entity.qualified == symbol)
            .or_else(|| {
                let mut named = in_file.iter().filter(|entity| entity.name == symbol);
                let first = named.next()?;
                // Prefer the type over its constructor or a same named function.
                Some(
                    std::iter::once(first)
                        .chain(named)
                        .find(|entity| entity.kind == EntityKind::Type)
                        .unwrap_or(first),
                )
            })
    }

    /// The same entity in this snapshot: same file, qualified name and kind.
    pub fn counterpart(&self, entity: &Entity) -> Option<&Entity> {
        self.counterpart_in(&entity.file, entity)
    }

    /// The entity of `file` with the qualified name and kind of `entity`, for a file that moved.
    pub fn counterpart_in(&self, file: &Path, entity: &Entity) -> Option<&Entity> {
        self.in_file(file).iter().find(|candidate| {
            candidate.qualified == entity.qualified && candidate.kind == entity.kind
        })
    }

    /// The entities that reference `target` by name, each with the first line that does, minus
    /// those outside the target's module that import nothing that could name it.
    pub fn callers_of(&self, target: &Entity) -> Vec<(&Entity, u32)> {
        let Some(referrers) = self.referrers.get(&target.name) else {
            return Vec::new();
        };
        referrers
            .iter()
            .map(|&index| &self.entities[index])
            .filter(|caller| {
                caller.language == target.language
                    && !(caller.file == target.file
                        && caller.start >= target.start
                        && caller.end <= target.end)
            })
            .filter_map(|caller| {
                let mut named = caller
                    .references
                    .iter()
                    .filter(|reference| reference.name == target.name);
                let first = named.next()?;
                let reachable = self.can_name(caller, target)
                    || (std::iter::once(first)
                        .chain(named)
                        .any(|reference| reference.method)
                        && self.can_reach_module(caller, target));
                reachable.then_some((caller, first.line))
            })
            .collect()
    }

    /// The entities `entity` calls or names, resolved by name like [`Self::callers_of`].
    pub fn callees_of(&self, entity: &Entity) -> Vec<&Entity> {
        let mut names: Vec<&str> = entity
            .references
            .iter()
            .map(|reference| reference.name.as_str())
            .collect();
        names.sort_unstable();
        names.dedup();
        self.entities
            .iter()
            .filter(|candidate| {
                candidate.language == entity.language
                    && candidate.kind != EntityKind::Test
                    && names.binary_search(&candidate.name.as_str()).is_ok()
                    && !std::ptr::eq(*candidate, entity)
                    && self.can_name(entity, candidate)
            })
            .collect()
    }

    /// The entities named `name` in `language` that `from` could mean.
    pub fn resolve<'a>(&'a self, from: &Entity, name: &str) -> Vec<&'a Entity> {
        self.entities
            .iter()
            .filter(|candidate| {
                candidate.language == from.language
                    && candidate.name == name
                    && candidate.kind != EntityKind::Test
                    && self.can_name(from, candidate)
            })
            .collect()
    }

    /// The source text of `entity`, which must belong to this snapshot.
    pub fn text(&self, entity: &Entity) -> &str {
        &self.files[&entity.file].text[entity.bytes.0..entity.bytes.1]
    }

    /// Whether code in `from` can call the method `target` on a value: a value's type needs no
    /// import, only access to the module that defines it. A Rust caller imports from the target's
    /// crate, a Kotlin caller from its package; Dart values reach any library.
    fn can_reach_module(&self, from: &Entity, target: &Entity) -> bool {
        if !target.qualified.contains(target.language.separator()) {
            return false;
        }
        let Some(source) = self.files.get(&from.file) else {
            return false;
        };
        let target_module = self.module_of(target);
        match target.language {
            Language::Kotlin => target_module.is_some_and(|package| {
                source
                    .imports
                    .iter()
                    .any(|import| import.starts_with(&format!("{package}.")))
            }),
            Language::Rust => crate_name(target_module.as_deref())
                .is_some_and(|krate| source.imports.iter().any(|import| import.contains(&krate))),
            Language::Dart => true,
        }
    }

    /// The Kotlin package or Rust crate directory of `target`, which may belong to another
    /// snapshot (an entity the change removed) and then has only its path.
    fn module_of(&self, target: &Entity) -> Option<String> {
        match self.files.get(&target.file) {
            Some(file) => file.module.clone(),
            None => rust_crate(target.language, &target.file),
        }
    }

    /// Whether code in `from` can name `target`: same file, same module (Kotlin package, Rust
    /// crate), or an import that can bring it in. Kotlin imports are exact (`package.Name`,
    /// `package.Owner`, `package.*`); a Rust import from another crate names that crate; a Dart
    /// import mentions the target, its owner or its file, since barrels re-export.
    fn can_name(&self, from: &Entity, target: &Entity) -> bool {
        if from.file == target.file {
            return true;
        }
        let Some(source) = self.files.get(&from.file) else {
            return false;
        };
        let target_module = self.module_of(target);
        if source.module.is_some() && source.module == target_module {
            return true;
        }
        let separator = target.language.separator();
        let owner = target
            .qualified
            .split(separator)
            .next()
            .filter(|owner| *owner != target.name);
        let names = || std::iter::once(target.name.as_str()).chain(owner);
        match target.language {
            Language::Kotlin => {
                let Some(package) = target_module else {
                    return false;
                };
                source.imports.iter().any(|import| {
                    import == &format!("{package}.*")
                        || names().any(|name| {
                            import == &format!("{package}.{name}")
                                || import.starts_with(&format!("{package}.{name} as "))
                        })
                })
            }
            Language::Rust => {
                let krate = crate_name(target_module.as_deref());
                source.imports.iter().any(|import| {
                    krate.as_deref().is_some_and(|krate| import.contains(krate))
                        && (names().any(|name| import.contains(name)) || import.contains('*'))
                })
            }
            Language::Dart => {
                let stem = target.file.file_stem().map(|stem| stem.to_string_lossy());
                source.imports.iter().any(|import| {
                    names().any(|name| import.contains(name))
                        || stem.as_deref().is_some_and(|stem| import.contains(stem))
                })
            }
        }
    }
}

/// Parses one file into its source record and entities.
fn index_file(
    parser: &mut Parser,
    language: Language,
    path: &Path,
    text: String,
) -> (SourceFile, Vec<Entity>) {
    let mut source = SourceFile {
        imports: Vec::new(),
        mentions: HashSet::new(),
        module: rust_crate(language, path),
        text: String::new(),
    };
    let Some(tree) = parser.parse(&text, None) else {
        source.text = text;
        return (source, Vec::new());
    };
    let mut walker = Walker {
        language,
        path,
        text: text.as_bytes(),
        entities: Vec::new(),
        open: Vec::new(),
        owners: Vec::new(),
        trait_impl: 0,
        source: &mut source,
    };
    walker.visit(tree.root_node());
    let mut entities = walker.entities;
    let words: Vec<String> = source
        .imports
        .iter()
        .flat_map(|import| import.split(|c: char| !c.is_alphanumeric() && c != '_'))
        .filter(|word| !word.is_empty())
        .map(str::to_string)
        .collect();
    source.mentions.extend(words);
    fingerprint(&mut entities, &text);
    source.text = text;
    (source, entities)
}

/// The directory of the nearest `Cargo.toml` package root (`src`'s parent) of a Rust file.
fn rust_crate(language: Language, path: &Path) -> Option<String> {
    if language != Language::Rust {
        return None;
    }
    let mut ancestors = path.ancestors();
    ancestors
        .find(|dir| {
            dir.file_name()
                .is_some_and(|name| name == "src" || name == "tests")
        })
        .and_then(Path::parent)
        .map(|dir| dir.to_string_lossy().into_owned())
}

/// The name code imports the crate in directory `dir` by: its directory name, `-` as `_`.
fn crate_name(dir: Option<&str>) -> Option<String> {
    Path::new(dir?)
        .file_name()
        .map(|name| name.to_string_lossy().replace('-', "_"))
}

/// Hashes each entity's text with its nested entities cut out, ignoring whitespace, so a type
/// counts as changed only when its own declaration changed, not one of its methods.
fn fingerprint(entities: &mut [Entity], text: &str) {
    let spans: Vec<(usize, usize)> = entities.iter().map(|entity| entity.bytes).collect();
    for entity in entities.iter_mut() {
        let (start, end) = entity.bytes;
        let mut nested: Vec<(usize, usize)> = spans
            .iter()
            .copied()
            .filter(|&(from, to)| from >= start && to <= end && (from, to) != (start, end))
            .collect();
        nested.sort_unstable();
        let mut hasher = DefaultHasher::new();
        let mut cursor = start;
        for (from, to) in nested {
            if from >= cursor {
                text[cursor..from]
                    .split_whitespace()
                    .for_each(|word| word.hash(&mut hasher));
                cursor = to;
            }
        }
        text[cursor..end]
            .split_whitespace()
            .for_each(|word| word.hash(&mut hasher));
        entity.fingerprint = hasher.finish();
    }
}

/// A definition found at a node.
struct Definition<'t> {
    name: String,
    kind: EntityKind,
    body: Option<Node<'t>>,
    public: bool,
    overrides: bool,
    disabled: bool,
}

struct Walker<'a> {
    language: Language,
    path: &'a Path,
    text: &'a [u8],
    entities: Vec<Entity>,
    /// Indexes of the entities enclosing the current node, innermost last.
    open: Vec<usize>,
    owners: Vec<String>,
    /// Depth of `impl Trait for Type` blocks around the current node.
    trait_impl: usize,
    source: &'a mut SourceFile,
}

impl<'a> Walker<'a> {
    fn visit(&mut self, node: Node<'a>) {
        let mut pushed_owner = false;
        let mut opened = false;
        let mut in_trait_impl = false;
        match self.language {
            Language::Rust => {
                if node.kind() == "use_declaration" {
                    self.source.imports.push(self.collapse(node));
                }
                if node.kind() == "impl_item" {
                    if let Some(owner) = node
                        .child_by_field_name("type")
                        .map(|ty| self.base_type(ty))
                    {
                        self.owners.push(owner);
                        pushed_owner = true;
                    }
                    if node.child_by_field_name("trait").is_some() {
                        self.trait_impl += 1;
                        in_trait_impl = true;
                    }
                }
            }
            Language::Kotlin => match node.kind() {
                "import" => {
                    // `import a.b.C` and `import a.b.C as D`, without the keyword.
                    let text = self.collapse(node);
                    self.source
                        .imports
                        .push(text.trim_start_matches("import").trim().to_string());
                }
                "package_header" => {
                    self.source.module =
                        child_of_kind(node, "qualified_identifier").map(|name| self.collapse(name));
                }
                _ => {}
            },
            Language::Dart => {
                // A `part of` file shares its library's scope, so it may name the library's
                // declarations as if imported.
                if matches!(node.kind(), "import_or_export" | "part_of_directive") {
                    self.source.imports.push(self.collapse(node));
                }
            }
        }
        if let Some(definition) = self.definition(node) {
            self.open(node, definition);
            opened = true;
        } else if let Some(owner) = self.suite(node) {
            self.owners.push(owner);
            pushed_owner = true;
        }
        self.observe(node);
        let mut cursor = node.walk();
        let children: Vec<Node<'a>> = node.named_children(&mut cursor).collect();
        for child in children {
            self.visit(child);
        }
        if opened {
            self.open.pop();
            self.owners.pop();
        }
        if pushed_owner {
            self.owners.pop();
        }
        if in_trait_impl {
            self.trait_impl -= 1;
        }
    }

    fn open(&mut self, node: Node<'a>, definition: Definition<'a>) {
        let qualified = self
            .owners
            .iter()
            .map(String::as_str)
            .chain([definition.name.as_str()])
            .collect::<Vec<_>>()
            .join(self.language.separator());
        let (signature_end, signature_line) = definition
            .body
            .map_or((node.end_byte(), node.end_position().row), |body| {
                (body.start_byte(), body.start_position().row)
            });
        let statements = definition.body.map_or(0, |body| statements(body));
        // Everything nested is qualified by the entity it sits in.
        self.owners.push(definition.name.clone());
        self.entities.push(Entity {
            name: definition.name,
            qualified,
            kind: definition.kind,
            file: self.path.to_path_buf(),
            language: self.language,
            start: node.start_position().row as u32 + 1,
            end: node.end_position().row as u32 + 1,
            signature_end: signature_line as u32 + 1,
            bytes: (node.start_byte(), node.end_byte()),
            public: definition.public,
            overrides: definition.overrides || self.trait_impl > 0,
            disabled: definition.disabled,
            signature: collapse(&self.text[node.start_byte()..signature_end]),
            fingerprint: 0,
            references: Vec::new(),
            calls: Vec::new(),
            statements,
            branches: 0,
            assertions: Vec::new(),
        });
        self.open.push(self.entities.len() - 1);
    }

    /// Records what `node` contributes to the innermost open entity, or to the file when no
    /// entity encloses it (constants, top level properties).
    fn observe(&mut self, node: Node<'a>) {
        let line = node.start_position().row as u32 + 1;
        let callee = self.callee(node);
        let method = callee.is_some() && self.is_method_call(node);
        let mut names = self.type_references(node);
        names.extend(self.value_references(node));
        let Some(&current) = self.open.last() else {
            self.source.mentions.extend(names);
            self.source.mentions.extend(callee);
            return;
        };
        if BRANCHES.contains(&(self.language, node.kind())) {
            self.entities[current].branches += 1;
        }
        for name in names {
            self.entities[current].references.push(Reference {
                name,
                line,
                method: false,
            });
        }
        if let Some(callee) = callee {
            if is_assertion(&callee) {
                let assertion = self.collapse(node);
                if let Some(test) = self.innermost_test() {
                    test.assertions.push(assertion);
                }
            }
            let entity = &mut self.entities[current];
            entity.calls.push(callee.clone());
            entity.references.push(Reference {
                name: callee,
                line,
                method,
            });
        }
        if self.language == Language::Kotlin && node.kind() == "infix_expression" {
            // kotest matchers: `actual shouldBe expected`.
            let mut cursor = node.walk();
            let operator = node
                .named_children(&mut cursor)
                .nth(1)
                .map(|op| self.slice(op));
            if operator.is_some_and(|op| op.starts_with("should")) {
                let assertion = self.collapse(node);
                if let Some(test) = self.innermost_test() {
                    test.assertions.push(assertion);
                }
            }
        }
    }

    /// Functions used as values (`map(parse)`, `run: rules`, `Self::build`, `handler as usize`,
    /// `retry: panelRetry`, `::parse`) and names inside Rust macro arguments, which tree-sitter
    /// leaves as unparsed tokens.
    fn value_references(&self, node: Node<'a>) -> Vec<String> {
        let Some(parent) = node.parent() else {
            return Vec::new();
        };
        // `let x = name`, `x = name`, `name as T`, `&name`, `field: name`; not the receiver of
        // `name.field`.
        let assigned = parent.kind() != "field_expression"
            && (parent.child_by_field_name("value") == Some(node)
                || parent.child_by_field_name("right") == Some(node));
        match self.language {
            Language::Kotlin => {
                return if node.kind() == "identifier" && parent.kind() == "callable_reference" {
                    vec![self.slice(node)]
                } else {
                    Vec::new()
                };
            }
            Language::Dart => {
                let value_position = assigned
                    || matches!(
                        parent.kind(),
                        "arguments"
                            | "named_argument"
                            | "annotation_arguments"
                            | "list_literal"
                            | "return_statement"
                    );
                return if node.kind() == "identifier" && value_position {
                    vec![self.slice(node)]
                } else {
                    Vec::new()
                };
            }
            Language::Rust => {}
        }
        let value_position = assigned
            || matches!(
                parent.kind(),
                "arguments"
                    | "array_expression"
                    | "tuple_expression"
                    | "return_expression"
                    | "token_tree"
            )
            || (parent.kind() == "call_expression"
                && parent.child_by_field_name("function") != Some(node));
        match node.kind() {
            "identifier" if value_position => vec![self.slice(node)],
            "scoped_identifier" => {
                let is_callee = node.parent().is_some_and(|parent| {
                    parent.kind() == "call_expression"
                        && parent.child_by_field_name("function") == Some(node)
                });
                if is_callee {
                    Vec::new()
                } else {
                    self.last_name(node).into_iter().collect()
                }
            }
            _ => Vec::new(),
        }
    }

    fn innermost_test(&mut self) -> Option<&mut Entity> {
        let index = self
            .open
            .iter()
            .rev()
            .copied()
            .find(|&index| self.entities[index].kind == EntityKind::Test)?;
        Some(&mut self.entities[index])
    }

    /// The function, type or test defined at `node`.
    fn definition(&self, node: Node<'a>) -> Option<Definition<'a>> {
        let name_of = |node: Node<'a>| {
            node.child_by_field_name("name")
                .map(|name| self.slice(name))
        };
        let definition = |name: String, kind, body| Definition {
            public: false,
            overrides: false,
            disabled: false,
            name,
            kind,
            body,
        };
        match (self.language, node.kind()) {
            (Language::Rust, "function_item" | "function_signature_item") => {
                let attributes = self.rust_attributes(node);
                let test = attributes.iter().any(|attribute| {
                    attribute == "test" || attribute.ends_with("::test") || attribute == "rstest"
                });
                Some(Definition {
                    public: self.rust_public(node),
                    disabled: attributes
                        .iter()
                        .any(|attribute| attribute.starts_with("ignore")),
                    ..definition(
                        name_of(node)?,
                        if test {
                            EntityKind::Test
                        } else {
                            EntityKind::Function
                        },
                        node.child_by_field_name("body"),
                    )
                })
            }
            (
                Language::Rust,
                "struct_item" | "enum_item" | "trait_item" | "union_item" | "type_item",
            ) => Some(Definition {
                public: self.rust_public(node),
                ..definition(name_of(node)?, EntityKind::Type, None)
            }),
            (Language::Kotlin, "function_declaration") => {
                let modifiers = self.modifiers(node);
                Some(Definition {
                    public: !kotlin_hidden(modifiers.as_deref()),
                    overrides: modifiers
                        .as_deref()
                        .is_some_and(|m| m.contains("override") || m.contains("operator")),
                    ..definition(
                        name_of(node)?,
                        EntityKind::Function,
                        node.child_by_field_name("body")
                            .or_else(|| child_of_kind(node, "function_body")),
                    )
                })
            }
            (Language::Kotlin, "class_declaration" | "object_declaration") => Some(Definition {
                public: !kotlin_hidden(self.modifiers(node).as_deref()),
                ..definition(name_of(node)?, EntityKind::Type, None)
            }),
            (Language::Dart, "function_declaration" | "method_declaration") => {
                let signature = node.child_by_field_name("signature")?;
                let named = if signature.child_by_field_name("name").is_some() {
                    signature
                } else {
                    signature.named_child(0)?
                };
                let name = name_of(named)?;
                let mut cursor = node.walk();
                let overrides = node.named_children(&mut cursor).any(|child| {
                    child.kind() == "annotation" && name_of(child).as_deref() == Some("override")
                });
                Some(Definition {
                    public: !name.starts_with('_'),
                    overrides,
                    ..definition(name, EntityKind::Function, node.child_by_field_name("body"))
                })
            }
            (
                Language::Dart,
                "class_declaration"
                | "enum_declaration"
                | "mixin_declaration"
                | "extension_declaration",
            ) => {
                let name = name_of(node).or_else(|| {
                    let mut cursor = node.walk();
                    node.named_children(&mut cursor)
                        .find(|child| child.kind() == "identifier")
                        .map(|child| self.slice(child))
                })?;
                Some(Definition {
                    public: !name.starts_with('_'),
                    ..definition(name, EntityKind::Type, None)
                })
            }
            (Language::Kotlin | Language::Dart, "call_expression") => {
                let (callee, arguments) = self.test_call(node)?;
                if !matches!(callee.as_str(), "test" | "testWidgets") {
                    return None;
                }
                let name = self.first_string(arguments)?;
                let arguments_text = self.slice(arguments);
                let disabled = match self.language {
                    Language::Kotlin => arguments_text.contains("disable()"),
                    _ => {
                        arguments_text.contains("skip:") && !arguments_text.contains("skip: false")
                    }
                };
                Some(Definition {
                    public: false,
                    disabled,
                    ..definition(name, EntityKind::Test, None)
                })
            }
            _ => None,
        }
    }

    /// The name of a test suite or group opened at `node`, which owns the tests inside it.
    fn suite(&self, node: Node<'a>) -> Option<String> {
        match (self.language, node.kind()) {
            (Language::Kotlin, "property_declaration") => {
                let mut cursor = node.walk();
                let delegate = node
                    .named_children(&mut cursor)
                    .find(|child| child.kind() == "property_delegate")?;
                if !self
                    .slice(delegate)
                    .trim_start_matches("by")
                    .trim()
                    .starts_with("testSuite")
                {
                    return None;
                }
                let variable = child_of_kind(node, "variable_declaration")?;
                child_of_kind(variable, "identifier").map(|name| self.slice(name))
            }
            (Language::Kotlin | Language::Dart, "call_expression") => {
                let (callee, arguments) = self.test_call(node)?;
                if !matches!(callee.as_str(), "group" | "testSuite") {
                    return None;
                }
                self.first_string(arguments)
            }
            _ => None,
        }
    }

    /// For a call that is a statement of its own (the outermost of Kotlin's trailing lambda
    /// nesting), its callee and argument list.
    fn test_call(&self, node: Node<'a>) -> Option<(String, Node<'a>)> {
        if self.language == Language::Kotlin
            && node.parent().is_some_and(|parent| {
                parent.kind() == "call_expression" && parent.named_child(0) == Some(node)
            })
        {
            return None;
        }
        let mut call = node;
        loop {
            let first = call.named_child(0)?;
            if first.kind() == "call_expression" {
                call = first;
                continue;
            }
            let arguments = match self.language {
                Language::Dart => call.child_by_field_name("arguments")?,
                _ => child_of_kind(call, "value_arguments")?,
            };
            return (first.kind() == "identifier").then(|| (self.slice(first), arguments));
        }
    }

    /// The callee name of a call or macro at `node`.
    fn callee(&self, node: Node<'a>) -> Option<String> {
        let function = match (self.language, node.kind()) {
            (Language::Rust, "call_expression") => node.child_by_field_name("function")?,
            (Language::Rust, "macro_invocation") => node.child_by_field_name("macro")?,
            (Language::Kotlin, "call_expression") => {
                let first = node.named_child(0)?;
                // The inner call of a trailing lambda is recorded on its own.
                if first.kind() == "call_expression" {
                    return None;
                }
                first
            }
            (Language::Dart, "call_expression") => node.child_by_field_name("function")?,
            _ => return None,
        };
        self.last_name(function)
    }

    /// Whether the call at `node` names its function through a receiver: `value.name()`.
    fn is_method_call(&self, node: Node<'a>) -> bool {
        let function = match self.language {
            Language::Kotlin => node.named_child(0),
            Language::Rust | Language::Dart => node.child_by_field_name("function"),
        };
        function.is_some_and(|function| {
            matches!(
                function.kind(),
                "field_expression" | "member_expression" | "navigation_expression"
            )
        })
    }

    /// The rightmost plain name of a callee expression: `a.b.c` and `a::b::c` give `c`.
    fn last_name(&self, node: Node<'a>) -> Option<String> {
        match node.kind() {
            "identifier" | "field_identifier" | "type_identifier" => Some(self.slice(node)),
            "scoped_identifier" => node
                .child_by_field_name("name")
                .map(|name| self.slice(name)),
            "field_expression" => node
                .child_by_field_name("field")
                .map(|name| self.slice(name)),
            "generic_function" => self.last_name(node.child_by_field_name("function")?),
            "member_expression" => self.last_name(node.child_by_field_name("property")?),
            "navigation_expression" => {
                let count = node.named_child_count();
                self.last_name(node.named_child(count.checked_sub(1)? as u32)?)
            }
            _ => None,
        }
    }

    /// Type names used at `node`: type positions, plus `Type::item` and `Type.item` qualifiers.
    fn type_references(&self, node: Node<'a>) -> Vec<String> {
        let capitalised = |name: &String| name.chars().next().is_some_and(char::is_uppercase);
        match (self.language, node.kind()) {
            (Language::Rust | Language::Dart, "type_identifier") => {
                // A definition's own name is not a use of it.
                let defines = node.parent().is_some_and(|parent| {
                    parent.child_by_field_name("name") == Some(node)
                        && self.definition(parent).is_some()
                });
                if defines {
                    Vec::new()
                } else {
                    vec![self.slice(node)]
                }
            }
            (Language::Rust, "scoped_identifier" | "scoped_type_identifier") => node
                .child_by_field_name("path")
                .and_then(|path| self.last_name(path))
                .filter(capitalised)
                .into_iter()
                .collect(),
            (Language::Kotlin, "user_type") => child_of_kind(node, "identifier")
                .map(|name| self.slice(name))
                .into_iter()
                .collect(),
            (Language::Kotlin, "navigation_expression") => node
                .named_child(0)
                .filter(|first| first.kind() == "identifier")
                .map(|first| self.slice(first))
                .filter(capitalised)
                .into_iter()
                .collect(),
            (Language::Dart, "member_expression") => node
                .child_by_field_name("object")
                .filter(|object| object.kind() == "identifier")
                .map(|object| self.slice(object))
                .filter(capitalised)
                .into_iter()
                .collect(),
            _ => Vec::new(),
        }
    }

    /// The attributes directly above a Rust item, as written inside `#[...]`.
    fn rust_attributes(&self, node: Node<'a>) -> Vec<String> {
        let mut attributes = Vec::new();
        let mut sibling = node.prev_named_sibling();
        while let Some(attribute) = sibling.filter(|sibling| {
            sibling.kind() == "attribute_item" || sibling.kind().ends_with("comment")
        }) {
            if attribute.kind() == "attribute_item" {
                let text = self.slice(attribute);
                attributes.push(
                    text.trim_start_matches("#[")
                        .trim_end_matches(']')
                        .trim()
                        .to_string(),
                );
            }
            sibling = attribute.prev_named_sibling();
        }
        attributes
    }

    fn rust_public(&self, node: Node<'a>) -> bool {
        child_of_kind(node, "visibility_modifier")
            .is_some_and(|modifier| self.slice(modifier) == "pub")
    }

    fn modifiers(&self, node: Node<'a>) -> Option<String> {
        child_of_kind(node, "modifiers").map(|modifiers| self.slice(modifiers))
    }

    /// The first string literal argument's content.
    fn first_string(&self, arguments: Node<'a>) -> Option<String> {
        let mut stack = vec![arguments];
        while let Some(node) = stack.pop() {
            if node.kind() == "string_literal" {
                let text = self.slice(node);
                return Some(text.trim_matches(|c| c == '"' || c == '\'').to_string());
            }
            let mut cursor = node.walk();
            let children: Vec<_> = node.named_children(&mut cursor).collect();
            // Depth first, leftmost child first.
            stack.extend(children.into_iter().rev());
        }
        None
    }

    /// The type an `impl` is for, without generics or references.
    fn base_type(&self, node: Node<'a>) -> String {
        match node.kind() {
            "generic_type" => node
                .child_by_field_name("type")
                .map_or_else(|| self.slice(node), |inner| self.base_type(inner)),
            "reference_type" => node
                .child_by_field_name("type")
                .map_or_else(|| self.slice(node), |inner| self.base_type(inner)),
            "scoped_type_identifier" => node
                .child_by_field_name("name")
                .map_or_else(|| self.slice(node), |name| self.slice(name)),
            _ => self.slice(node),
        }
    }

    fn slice(&self, node: Node<'a>) -> String {
        String::from_utf8_lossy(&self.text[node.start_byte()..node.end_byte()]).into_owned()
    }

    fn collapse(&self, node: Node<'a>) -> String {
        collapse(&self.text[node.start_byte()..node.end_byte()])
    }
}

/// Node kinds that add a conditional arm.
const BRANCHES: &[(Language, &str)] = &[
    (Language::Rust, "if_expression"),
    (Language::Rust, "match_arm"),
    (Language::Kotlin, "if_expression"),
    (Language::Kotlin, "when_entry"),
    (Language::Dart, "if_statement"),
    (Language::Dart, "if_element"),
    (Language::Dart, "switch_statement_case"),
    (Language::Dart, "switch_expression_case"),
    (Language::Dart, "conditional_expression"),
];

fn is_assertion(callee: &str) -> bool {
    callee.starts_with("assert")
        || callee.starts_with("expect")
        || callee.starts_with("should")
        || callee == "verify"
}

/// Whether Kotlin modifiers hide a declaration from other modules.
fn kotlin_hidden(modifiers: Option<&str>) -> bool {
    modifiers.is_some_and(|modifiers| {
        modifiers
            .split_whitespace()
            .any(|word| matches!(word, "private" | "internal" | "protected"))
    })
}

/// Statements directly in a body block; an expression body counts as one.
fn statements(body: Node) -> usize {
    let block = if body.kind() == "function_body" {
        body.named_child(0).unwrap_or(body)
    } else {
        body
    };
    if block.kind() != "block" {
        return 1;
    }
    let mut cursor = block.walk();
    let count = block
        .named_children(&mut cursor)
        .filter(|child| !child.kind().ends_with("comment"))
        .count();
    // Kotlin wraps the statements of a block in one `statements` node.
    if count == 1
        && block
            .named_child(0)
            .is_some_and(|child| child.kind() == "statements")
    {
        return statements(block.named_child(0).unwrap_or(block));
    }
    count
}

fn child_of_kind<'t>(node: Node<'t>, kind: &str) -> Option<Node<'t>> {
    let mut cursor = node.walk();
    node.named_children(&mut cursor)
        .find(|child| child.kind() == kind)
}

fn collapse(text: &[u8]) -> String {
    String::from_utf8_lossy(text)
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ")
}
