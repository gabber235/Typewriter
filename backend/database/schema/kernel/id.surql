DEFINE FUNCTION OVERWRITE fn::is_id($id: string) -> bool {
    RETURN string::len($id) >= 3
        AND string::matches($id, '^[a-z0-9]+(_[a-z0-9]+)*$');
};

DEFINE FUNCTION OVERWRITE fn::is_artifact_id($id: string) -> bool {
    RETURN string::matches($id, '^[A-Za-z0-9][A-Za-z0-9_.-]*(:[A-Za-z0-9][A-Za-z0-9_.-]*)*$');
};
