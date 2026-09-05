DEFINE TABLE OVERWRITE element SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE element_type ON element TYPE string;

DEFINE FIELD OVERWRITE schema_revision ON element TYPE int
    ASSERT $value > 0;

DEFINE FIELD OVERWRITE name ON element TYPE string
    ASSERT string::trim($value) != "";

DEFINE FIELD OVERWRITE value ON element TYPE object FLEXIBLE;

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
