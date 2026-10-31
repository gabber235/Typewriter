#!/usr/bin/env bash
#
# Answers "what does this entity support, and what does Typewriter already cover?" from the EntityLib
# version Typewriter builds against, so nobody has to guess from EntityLib's master branch.
#
#   bash scripts/entity-info.sh BAT          everything needed to add or extend the bat entity
#   bash scripts/entity-info.sh armor_stand  type names are case-insensitive, '-' works as '_'
#   bash scripts/entity-info.sh AgeableMeta  a single EntityLib meta class and the data targeting it
#   bash scripts/entity-info.sh --missing    entity types EntityLib supports that have no entity file yet
#
# Reads the EntityLib sources jar from the Gradle cache. Without it, falls back to javap on the class jar.
# Both jars appear after one `./gradlew :EntityExtension:compileKotlin` from extensions/.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
EXT_DIR=$(dirname "$SCRIPT_DIR")
REPO_DIR=$(cd "$EXT_DIR/../.." && pwd)
ENTRIES_DIR="$EXT_DIR/src/main/kotlin/com/typewritermc/entity/entries"
MINECRAFT_DIR="$ENTRIES_DIR/entity/minecraft"
SIZE_TABLE="$ENTRIES_DIR/entity/custom/EntityTypeProperty.kt"
ENGINE_BUILD="$REPO_DIR/engine/engine-paper/build.gradle.kts"
CACHE_ROOT="$EXT_DIR/build/entity-info"

usage() {
    sed -n '3,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

die() {
    echo "entity-info: $*" >&2
    exit 1
}

entitylib_version() {
    local version
    version=$(grep -oE 'me\.tofaa2:spigot:[^"]+' "$ENGINE_BUILD" | head -1 | cut -d: -f3 || true)
    [[ -n "$version" ]] || die "could not read the EntityLib version from $ENGINE_BUILD"
    echo "$version"
}

gradle_modules_dir() {
    local home="${GRADLE_USER_HOME:-$HOME/.gradle}"
    if command -v cygpath >/dev/null 2>&1; then home=$(cygpath -u "$home"); fi
    echo "$home/caches/modules-2/files-2.1"
}

entitylib_cache_dir() {
    echo "$(gradle_modules_dir)/me.tofaa2/api/$1"
}

packetevents_jar() {
    local version
    version=$(grep -oE 'packetevents-api:[0-9][^"]*' "$ENGINE_BUILD" | head -1 | cut -d: -f2 || true)
    [[ -n "$version" ]] || return 0
    ls -t "$(gradle_modules_dir)/com.github.retrooper/packetevents-api/$version"/*/"packetevents-api-$version.jar" \
        2>/dev/null | head -1 || true
}

# Sets MODE to "sources" (SRC_ROOT holds the extracted .java files) or "classes" (CLASS_JAR is set).
prepare_entitylib() {
    VERSION=$(entitylib_version)
    local cache sources_jar
    cache=$(entitylib_cache_dir "$VERSION")
    sources_jar=$(ls -t "$cache"/*/api-*-sources.jar 2>/dev/null | head -1 || true)
    CLASS_JAR=$(ls -t "$cache"/*/api-*.jar 2>/dev/null | grep -v -- '-sources\.jar$' | head -1 || true)

    if [[ -n "$sources_jar" ]]; then
        MODE=sources
        SRC_ROOT="$CACHE_ROOT/$VERSION"
        if [[ ! -f "$SRC_ROOT/.jar" || "$(cat "$SRC_ROOT/.jar")" != "$sources_jar" ]]; then
            rm -rf "$SRC_ROOT"
            mkdir -p "$SRC_ROOT"
            unzip -q -o "$sources_jar" -d "$SRC_ROOT"
            index_sources
            echo "$sources_jar" > "$SRC_ROOT/.jar"
        fi
        SOURCE_LABEL="sources jar"
        return
    fi
    if [[ -n "$CLASS_JAR" ]] && command -v javap >/dev/null 2>&1; then
        MODE=classes
        SOURCE_LABEL="class jar via javap (no sources jar; registry and TODO notes unavailable)"
        return
    fi
    die "EntityLib $VERSION is not in $cache. Run ./gradlew :EntityExtension:compileKotlin from extensions/ first."
}

# Writes "<Class> <path>" to .files and "<Class> <Parent>" to .parents, so lookups never walk the tree again.
index_sources() {
    find "$SRC_ROOT/me" -name '*.java' | sed -E 's#^(.*/)([^/]+)\.java$#\2 \1\2.java#' > "$SRC_ROOT/.files"
    find "$SRC_ROOT/me" -name '*.java' -exec sed -nE \
        's/.*class ([A-Za-z0-9_]+)([^A-Za-z0-9_][^{]*)? extends ([A-Za-z0-9_]+).*/\1 \3/p' {} + > "$SRC_ROOT/.parents"
}

# --- EntityLib lookups -------------------------------------------------------------------------------------

meta_source() {
    awk -v name="$1" '$1 == name { sub(/^[^ ]+ /, ""); print; exit }' "$SRC_ROOT/.files"
}

meta_class_entry() {
    unzip -Z1 "$CLASS_JAR" | grep -E "/$1\.class$" | head -1 || true
}

meta_exists() {
    if [[ $MODE == sources ]]; then
        [[ -n "$(meta_source "$1")" ]]
    else
        [[ -n "$(meta_class_entry "$1")" ]]
    fi
}

meta_location() {
    if [[ $MODE == sources ]]; then
        local file
        file=$(meta_source "$1")
        echo "${file#"$SRC_ROOT"/me/tofaa/entitylib/meta/}"
    else
        meta_class_entry "$1"
    fi
}

javap_meta() {
    local entry
    entry=$(meta_class_entry "$1")
    [[ -n "$entry" ]] || return 0
    entry=${entry%.class}
    javap -public -cp "$CLASS_JAR" "${entry//\//.}" 2>/dev/null || true
}

meta_parent() {
    if [[ $MODE == sources ]]; then
        awk -v name="$1" '$1 == name { print $2; exit }' "$SRC_ROOT/.parents"
    else
        javap_meta "$1" | sed -nE 's/.* extends ([A-Za-z0-9_.$]+).*/\1/p' | head -1 | sed 's/.*\.//'
    fi
}

meta_setters() {
    if [[ $MODE == sources ]]; then
        local file
        file=$(meta_source "$1")
        [[ -n "$file" ]] || return 0
        grep -E '^[[:space:]]*public [^=(]*[[:space:]]set[A-Z][A-Za-z0-9_]*\(' "$file" \
            | sed -E 's/.*[[:space:]](set[A-Z][A-Za-z0-9_]*\([^)]*\)).*/\1/' || true
    else
        javap_meta "$1" | grep -oE ' set[A-Z][A-Za-z0-9_]*\([^)]*\)' | sed 's/^ //' || true
    fi
}

enum_constants_in_source() {
    awk -v type="$2" '
        $0 ~ "enum[[:space:]]+" type "([^A-Za-z0-9_]|$)" { inside = 1; next }
        inside {
            if (match($0, /^[[:space:]]*[A-Z][A-Z0-9_]*[[:space:]]*[,(;]/)) {
                name = substr($0, RSTART, RLENGTH); gsub(/[^A-Z0-9_]/, "", name)
                out = out (out == "" ? "" : ", ") name
            }
            if ($0 ~ /;/ || $0 ~ /^[[:space:]]*}/) exit
        }
        END { print out }' "$1"
}

# What a setter's parameter can be: the constants of an enum, or the full name of any other non-primitive type.
setter_value_hint() {
    local meta=$1 setter=$2 file type outer import source constants jar
    [[ $MODE == sources ]] || return 0
    type=$(sed -E 's/^[^(]*\(//; s/@[A-Za-z]+ //g; s/[<[ ].*//; s/\)$//' <<< "$setter")
    case "$type" in
        ""|boolean|byte|short|int|long|float|double|char|String|Integer|Float|Boolean) return 0 ;;
    esac
    file=$(meta_source "$meta")
    if [[ $type == *.* ]]; then
        outer=${type%.*}
        type=${type##*.}
        source=$(meta_source "$outer")
        [[ -n "$source" ]] && enum_constants_in_source "$source" "$type"
        return 0
    fi
    import=$(sed -nE "s/^import ([A-Za-z0-9_.]+\.$type);.*/\1/p" "$file" | head -1)
    if [[ -z "$import" ]]; then
        enum_constants_in_source "$file" "$type"
        return 0
    fi
    if [[ $import == me.tofaa.entitylib.* ]]; then
        source=$(meta_source "$type")
        constants=""
        [[ -n "$source" ]] && constants=$(enum_constants_in_source "$source" "$type")
        echo "${constants:-$import}"
        return 0
    fi
    jar=$(packetevents_jar)
    if [[ $import == com.github.retrooper.* && -n "$jar" ]]; then
        constants=$(javap -public -cp "$jar" "$import" 2>/dev/null \
            | sed -nE "s/^[[:space:]]*public static final ${import//./\\.} ([A-Z0-9_]+);/\1/p" | paste -sd, - \
            | sed 's/,/, /g' || true)
        echo "${constants:-$import}"
        return 0
    fi
    echo "$import"
}

meta_chain() {
    local name=$1 guard=0
    while [[ -n "$name" && $guard -lt 20 ]]; do
        echo "$name"
        [[ $name == EntityMeta ]] && return
        name=$(meta_parent "$name")
        guard=$((guard + 1))
    done
}

registry_line() {
    local registry="$SRC_ROOT/me/tofaa/entitylib/meta/MetaConverterRegistry.java"
    grep -E "put\([[:space:]]*$1[[:space:]]*," "$registry" | head -1 || true
}

registry_meta() {
    registry_line "$1" | sed -nE 's/.*put\([^,]+,[[:space:]]*([A-Za-z0-9_]+)\.class.*/\1/p'
}

pascal_meta_name() {
    local result="" part
    IFS=_ read -ra parts <<< "$1"
    for part in "${parts[@]}"; do
        result+="${part:0:1}$(tr '[:upper:]' '[:lower:]' <<< "${part:1}")"
    done
    echo "${result}Meta"
}

# --- Typewriter lookups ------------------------------------------------------------------------------------

relative() {
    echo "${1#"$ENTRIES_DIR"/}"
}

implemented_files() {
    grep -rlE "EntityTypes\.$1([^A-Za-z0-9_]|$)" "$MINECRAFT_DIR" 2>/dev/null || true
}

size_row_line() {
    grep -nE "EntityDataMatcher\(EntityTypes\.$1[,)]" "$SIZE_TABLE" | head -1 | cut -d: -f1 || true
}

files_targeting_meta() {
    grep -rlE "meta<$1>" "$ENTRIES_DIR/data" "$ENTRIES_DIR/entity" 2>/dev/null || true
}

entry_ids() {
    grep -oE '@Entry\("[a-z0-9_]+"' "$1" | cut -d'"' -f2 | paste -sd, - || true
}

entry_tags() {
    grep -oE '@Tags\([^)]*\)' "$1" | sed -E 's/@Tags\((.*)\)/\1/; s/"//g' | paste -sd'|' - || true
}

# A setter counts as covered when a file that targets its meta names it the way Kotlin would.
setter_coverage() {
    local setter=$1 files=$2 field file hits=""
    field=${setter%%(*}
    field=${field#set}
    local lower
    lower="$(tr '[:upper:]' '[:lower:]' <<< "${field:0:1}")${field:1}"
    [[ -n "$files" ]] || return 0
    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        if grep -qE "([^A-Za-z0-9_]|^)(set$field|is$field|$lower)([^A-Za-z0-9_]|$)" "$file"; then
            hits+="${hits:+, }$(basename "$file" .kt)"
        fi
    done <<< "$files"
    echo "$hits"
}

# --- Reports -----------------------------------------------------------------------------------------------

print_header() {
    echo "EntityLib $VERSION, read from the $SOURCE_LABEL"
    echo
}

print_meta_report() {
    local meta=$1 shared=$2 files setter covered
    echo "  $meta  ($(meta_location "$meta"))"
    if [[ $shared == yes ]]; then
        echo "      shared metadata: handled by the generic/living routers, setters not listed"
        return
    fi
    files=$(files_targeting_meta "$meta")
    local setters
    setters=$(meta_setters "$meta")
    if [[ -z "$setters" ]]; then
        echo "      (no setters of its own)"
    fi
    while IFS= read -r setter; do
        [[ -n "$setter" ]] || continue
        covered=$(setter_coverage "$setter" "$files")
        if [[ -n "$covered" ]]; then
            covered="covered by $covered"
        else
            local hint
            hint=$(setter_value_hint "$meta" "$setter")
            covered="NOT COVERED${hint:+  [$hint]}"
        fi
        printf '      %-48s %s\n' "$setter" "$covered"
    done <<< "$setters"
    if [[ -n "$files" ]]; then
        echo "      typewriter files targeting $meta:"
        while IFS= read -r file; do
            [[ -n "$file" ]] || continue
            local ids tags
            ids=$(entry_ids "$file")
            tags=$(entry_tags "$file")
            echo "        $(relative "$file")${ids:+  ids: $ids}${tags:+  tags: $tags}"
        done <<< "$files"
    fi
}

snake_tag() {
    tr '[:upper:]' '[:lower:]' <<< "$1"
}

print_wiring() {
    local type=$1 chain=$2
    local tags=("generic_entity_data") routers=("applyGenericEntityData") branches=()
    grep -qx LivingEntityMeta <<< "$chain" && { tags+=("living_entity_data"); routers+=("applyLivingEntityData"); }
    grep -qx MobMeta <<< "$chain" && tags+=("mob_data")
    if grep -qx AgeableMeta <<< "$chain"; then
        tags+=("ageable_data")
        branches+=("is AgeableProperty -> applyAgeableData(entity, property)")
    fi
    grep -qx TameableMeta <<< "$chain" && { tags+=("tameable_data"); routers+=("applyTameableData"); }
    if grep -qx RaiderMeta <<< "$chain"; then
        tags+=("raider_data")
        branches+=("is CelebratingProperty -> applyCelebratingData(entity, property)")
    fi
    if grep -qx HorseMeta <<< "$chain"; then
        tags+=("horse_data")
    elif grep -qx BaseHorseMeta <<< "$chain"; then
        tags+=("saddled_data" "eating_data" "tamed_data" "rearing_data")
        branches+=(
            "is SaddledProperty -> applySaddledData(entity, property)"
            "is EatingProperty -> applyHorseEatingData(entity, property)"
            "is TamedProperty -> applyTamedData(entity, property)"
            "is RearingProperty -> applyRearingData(entity, property)"
        )
    fi
    grep -qx AbstractDisplayMeta <<< "$chain" && { tags+=("display_data"); routers+=("applyDisplayEntityData"); }
    local own_tag own_note=""
    own_tag="$(snake_tag "$type")_data"
    if grep -rqE "@Tags\([^)]*\"$own_tag\"" "$ENTRIES_DIR/data"; then
        tags+=("$own_tag")
    else
        own_note="Add \"$own_tag\" once a data entry carries it; the guard test fails on tags no data carries."
    fi

    local joined
    joined=$(printf '"%s", ' "${tags[@]}")
    echo "Suggested wiring (check each group tag's data really applies before keeping it):"
    echo "  @OnlyTags(${joined%, })    <- identical on the definition and the instance"
    [[ -z "$own_note" ]] || echo "  $own_note"
    echo "  override fun applyProperty(property: EntityProperty) {"
    echo "      when (property) {"
    local branch
    for branch in "${branches[@]+"${branches[@]}"}"; do echo "          $branch"; done
    echo "          <one branch per <entity>_data property>"
    echo "          else -> {}"
    echo "      }"
    local router
    for router in "${routers[@]}"; do echo "      if ($router(entity, property)) return"; done
    echo "  }"
    if grep -qx HorseMeta <<< "$chain"; then
        echo "  horse_data has no router: add a when branch for every horse_data property the entity takes."
    elif grep -qx BaseHorseMeta <<< "$chain"; then
        echo "  Not horse_data: it also offers HorseVariantData, which only a HorseMeta takes."
    fi
}

report_type() {
    local type=$1 meta registry files row chain
    if [[ $MODE == sources && -z "$(registry_line "$type")" ]]; then
        die "EntityLib $VERSION registers no meta for $type. Use the EntityTypes constant name, e.g. ARMOR_STAND."
    fi
    echo "== EntityTypes.$type =="

    files=$(implemented_files "$type")
    if [[ -n "$files" ]]; then
        echo "Implemented:  yes, $(relative "$(head -1 <<< "$files")")"
    else
        echo "Implemented:  no"
    fi

    row=$(size_row_line "$type")
    if [[ -n "$row" ]]; then
        echo "Size row:     yes, entity/custom/EntityTypeProperty.kt:$row"
    else
        echo "Size row:     MISSING. Add one to manualEntityData in entity/custom/EntityTypeProperty.kt,"
        echo "              or every state() lookup for this type throws."
    fi

    if [[ $MODE == sources ]]; then
        registry=$(registry_line "$type")
        meta=$(registry_meta "$type")
        echo "Registry:     $(sed -E 's/^[[:space:]]+//' <<< "$registry")"
        if grep -q 'TODO' <<< "$registry"; then
            echo "              EntityLib marks this mapping TODO: its metadata may be incomplete or wrong."
        fi
    else
        meta=$(pascal_meta_name "$type")
        meta_exists "$meta" || die "no $meta in the EntityLib class jar; pass the meta class name instead"
        echo "Registry:     unavailable without sources, guessed $meta"
    fi

    chain=$(meta_chain "$meta")
    if grep -qx LivingEntityMeta <<< "$chain"; then
        echo "Living:       yes, living_entity_data applies"
    else
        echo "Living:       no, the entity is not a WrapperLivingEntity and living data is dropped"
    fi
    echo
    echo "Meta chain, most specific first:"
    local each
    while IFS= read -r each; do
        [[ -n "$each" ]] || continue
        if [[ $each == EntityMeta || $each == LivingEntityMeta ]]; then
            print_meta_report "$each" yes
        else
            print_meta_report "$each" no
        fi
    done <<< "$chain"
    echo
    print_wiring "$type" "$chain"
}

report_meta() {
    local meta=$1 chain
    meta_exists "$meta" || die "EntityLib $VERSION has no class named $meta"
    echo "== $meta =="
    chain=$(meta_chain "$meta")
    echo "Chain: $(paste -sd'>' - <<< "$chain" | sed 's/>/ -> /g')"
    echo
    print_meta_report "$meta" no
}

report_missing() {
    [[ $MODE == sources ]] || die "--missing needs the EntityLib sources jar"
    local registry="$SRC_ROOT/me/tofaa/entitylib/meta/MetaConverterRegistry.java"
    local implemented sizes
    implemented=$(grep -rhoE 'EntityTypes\.[A-Z0-9_]+' "$MINECRAFT_DIR" | sed 's/EntityTypes\.//' \
        | sort -u | tr '\n' ' ')
    sizes=$(grep -oE 'EntityDataMatcher\(EntityTypes\.[A-Z0-9_]+' "$SIZE_TABLE" | sed 's/.*\.//' \
        | sort -u | tr '\n' ' ')

    echo "Living types first. A type without a size row needs one before it can be added."
    echo
    printf '%-24s %-28s %-7s %-9s %s\n' "TYPE" "META" "LIVING" "SIZE ROW" "NOTE"
    local put='^[[:space:]]*put\([[:space:]]*([A-Z0-9_]+)[[:space:]]*,[[:space:]]*([A-Za-z0-9_]+)\.class.*'
    sed -nE "s/$put/\\1 \\2 &/p" "$registry" \
        | awk -v implemented="$implemented" -v sizes="$sizes" -v parents="$SRC_ROOT/.parents" '
            BEGIN {
                split(implemented, list, " "); for (i in list) done[list[i]] = 1
                split(sizes, list, " "); for (i in list) sized[list[i]] = 1
                while ((getline line < parents) > 0) {
                    split(line, pair, " ")
                    if (!(pair[1] in parent)) parent[pair[1]] = pair[2]
                }
            }
            function living(meta,   guard) {
                for (guard = 0; meta != "" && guard < 20; guard++) {
                    if (meta == "LivingEntityMeta") return "yes"
                    meta = parent[meta]
                }
                return "no"
            }
            ($1 in done) || ($1 in seen) { next }
            {
                seen[$1] = 1
                note = index($0, "TODO") ? "EntityLib TODO" : ""
                printf "%-24s %-28s %-7s %-9s %s\n", $1, $2, living($2), ($1 in sized) ? "yes" : "no", note
            }' \
        | sort -k3b,3r -k1,1
}

main() {
    [[ $# -eq 1 ]] || usage 1
    case "$1" in
        -h|--help) usage 0 ;;
    esac
    prepare_entitylib
    print_header
    case "$1" in
        --missing) report_missing ;;
        *Meta) report_meta "$1" ;;
        *) report_type "$(tr '[:lower:]-' '[:upper:]_' <<< "$1")" ;;
    esac
}

main "$@"
