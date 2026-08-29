-- Color stored as ARGB uint32.

DEFINE FUNCTION OVERWRITE fn::is_color($color: int) -> bool {
    RETURN $color >= 0 AND $color <= 4294967295;
};

-- Convert a single hexadecimal character to its integer value.
DEFINE FUNCTION OVERWRITE fn::hex_digit($char: string) -> int {
    LET $digits = {
        "0": 0,
        "1": 1,
        "2": 2,
        "3": 3,
        "4": 4,
        "5": 5,
        "6": 6,
        "7": 7,
        "8": 8,
        "9": 9,
        "A": 10,
        "B": 11,
        "C": 12,
        "D": 13,
        "E": 14,
        "F": 15,
    };

    LET $c = string::uppercase($char);
    LET $value = $digits[$c];

    IF $value = NONE {
        THROW "Invalid hex character: " + $char;
    };

    RETURN $value;
};

-- Parse RGB or ARGB hex strings to an integer.
-- Accepted forms: 9E9E9E, #9E9E9E, 0x9E9E9E, FF9E9E9E, #FF9E9E9E, 0xFF9E9E9E.
-- RGB values are treated as fully opaque ARGB by prepending FF.
DEFINE FUNCTION OVERWRITE fn::color($argb: string) -> int {
    LET $without_hash = IF string::starts_with($argb, "#") {
        string::slice($argb, 1)
    } ELSE {
        $argb
    };

    LET $cleaned = IF string::starts_with($without_hash, "0x") {
        string::slice($without_hash, 2)
    } ELSE IF string::starts_with($without_hash, "0X") {
        string::slice($without_hash, 2)
    } ELSE {
        $without_hash
    };

    LET $len = string::len($cleaned);

    IF $len != 8 AND $len != 6 {
        THROW "Invalid ARGB hex string: expected 8 or 6 characters, got " + <string>$len;
    };

    LET $hex = IF $len = 6 {
        "FF" + $cleaned
    } ELSE {
        $cleaned
    };

    RETURN fn::hex_digit(string::slice($hex, 0, 1)) * 268435456
        + fn::hex_digit(string::slice($hex, 1, 2)) * 16777216
        + fn::hex_digit(string::slice($hex, 2, 3)) * 1048576
        + fn::hex_digit(string::slice($hex, 3, 4)) * 65536
        + fn::hex_digit(string::slice($hex, 4, 5)) * 4096
        + fn::hex_digit(string::slice($hex, 5, 6)) * 256
        + fn::hex_digit(string::slice($hex, 6, 7)) * 16
        + fn::hex_digit(string::slice($hex, 7, 8));
};

DEFINE PARAM OVERWRITE $gray VALUE fn::color("FF9E9E9E");
DEFINE PARAM OVERWRITE $white VALUE fn::color("FFFFFFFF");
