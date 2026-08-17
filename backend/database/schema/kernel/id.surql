DEFINE FUNCTION OVERWRITE fn::is_id($id: string) -> bool {
    RETURN string::len($id) >= 3
        AND string::matches($id, '^[a-z0-9]+(_[a-z0-9]+)*$');
};
