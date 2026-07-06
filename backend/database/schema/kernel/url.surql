DEFINE FUNCTION OVERWRITE fn::is_http_url($url: string) -> bool {
    RETURN string::is_url($url)
        AND (string::starts_with($url, "http://") OR string::starts_with($url, "https://"));
};
