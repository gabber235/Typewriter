DEFINE FUNCTION OVERWRITE fn::is_id($id: string) -> bool {
    RETURN string::matches($id, '^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$');
};
