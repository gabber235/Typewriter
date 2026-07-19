import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

const joinCodeUrlPrefix = "https://panel.typewritermc.com/join/";

String joinCodeUrl(skir.RecordId code) => "$joinCodeUrlPrefix${code.id}";
