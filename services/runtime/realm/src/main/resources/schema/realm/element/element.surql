DEFINE TABLE OVERWRITE element SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE element_type ON element TYPE string;

DEFINE FIELD OVERWRITE schema_revision ON element TYPE int
    ASSERT $value > 0;

DEFINE FIELD OVERWRITE value ON element TYPE object FLEXIBLE;

DEFINE FIELD OVERWRITE search ON element TYPE option<{
    name: { values: array<string> },
    policy_revision: string,
    summary: { values: array<string>, paths: array<string> },
    body: { values: array<string>, paths: array<string> },
    keyword: { values: array<string>, paths: array<string> }
}>
    ASSERT {
        RETURN array::len($value.name.values) = 1
            AND string::trim($value.name.values[0]) != ""
            AND string::trim($value.policy_revision) != ""
            AND array::len($value.summary.values) = array::len($value.summary.paths)
            AND array::len($value.body.values) = array::len($value.body.paths)
            AND array::len($value.keyword.values) = array::len($value.keyword.paths);
    };

DEFINE FIELD OVERWRITE page ON element
    COMPUTED array::first(<-contains_element<-page);

DEFINE FIELD OVERWRITE placement ON element TYPE
    {
        kind: "graph_v1",
        x: int,
        y: int,
        width: int,
        height: int
    }
    |
    {
        kind: "timeline_entry_v1",
        track_index: int
    }
    |
    {
        kind: "timeline_segment_v1",
        start_frame: int,
        end_frame: int
    }
    |
    {
        kind: "timeline_keyframe_v1",
        frame: int
    }
    ASSERT {
        IF $value.kind = "graph_v1" {
            RETURN $value.width > 0 AND $value.height > 0;
        };

        IF $value.kind = "timeline_entry_v1" {
            RETURN $value.track_index >= 0;
        };

        IF $value.kind = "timeline_segment_v1" {
            RETURN $value.start_frame >= 0
                AND $value.end_frame >= $value.start_frame;
        };

        IF $value.kind = "timeline_keyframe_v1" {
            RETURN $value.frame >= 0;
        };

        RETURN false;
    };

DEFINE INDEX OVERWRITE element_type ON element FIELDS element_type;

DEFINE INDEX OVERWRITE element_name_search ON element
    FIELDS search.name.values FULLTEXT ANALYZER authoring_text BM25 HIGHLIGHTS;
DEFINE INDEX OVERWRITE element_name_prefix ON element
    FIELDS search.name.values FULLTEXT ANALYZER authoring_prefix BM25 HIGHLIGHTS;
DEFINE INDEX OVERWRITE element_name_approximate ON element
    FIELDS search.name.values FULLTEXT ANALYZER authoring_approximate BM25 HIGHLIGHTS;

DEFINE INDEX OVERWRITE element_search_summary ON element
    FIELDS search.summary.values FULLTEXT ANALYZER authoring_text BM25 HIGHLIGHTS;
DEFINE INDEX OVERWRITE element_search_summary_approximate ON element
    FIELDS search.summary.values FULLTEXT ANALYZER authoring_approximate BM25 HIGHLIGHTS;

DEFINE INDEX OVERWRITE element_search_body ON element
    FIELDS search.body.values FULLTEXT ANALYZER authoring_text BM25 HIGHLIGHTS;
DEFINE INDEX OVERWRITE element_search_body_approximate ON element
    FIELDS search.body.values FULLTEXT ANALYZER authoring_approximate BM25 HIGHLIGHTS;

DEFINE INDEX OVERWRITE element_search_keyword ON element
    FIELDS search.keyword.values FULLTEXT ANALYZER authoring_text BM25 HIGHLIGHTS;
DEFINE INDEX OVERWRITE element_search_keyword_approximate ON element
    FIELDS search.keyword.values FULLTEXT ANALYZER authoring_approximate BM25 HIGHLIGHTS;
