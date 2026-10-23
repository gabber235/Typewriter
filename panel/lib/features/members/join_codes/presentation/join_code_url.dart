import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// Public URL prefix used when presenting an invitation code to a collaborator.
const joinCodeUrlPrefix = "https://panel.typewritermc.com/join/";

/// Builds the shareable URL for the typed code identifier.
String joinCodeUrl(skir.RecordId code) => "$joinCodeUrlPrefix${code.id}";
