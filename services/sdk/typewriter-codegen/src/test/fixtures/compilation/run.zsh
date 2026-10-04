#!/bin/zsh
set -euo pipefail

fixture_root=${0:A:h}
repository=$(git -C "$fixture_root" rev-parse --show-toplevel)
services_root=$repository/services
workspace=$(mktemp -d "${TMPDIR:-/private/tmp}/typewriter-ksp-compilation.XXXXXX")
results=$workspace/results
source_dir=$workspace/src/main/kotlin
mkdir -p "$results" "$source_dir"
cp "$fixture_root/build.gradle.kts.template" "$workspace/build.gradle.kts"
cp "$fixture_root/settings.gradle.kts.template" "$workspace/settings.gradle.kts"

"$services_root/gradlew" \
    -p "$services_root" \
    :protocol:jar \
    :imprint:imprint-model:jar \
    :typewriter-contracts:jar \
    :typewriter-codegen:jar \
    :typewriter-api:jar \
    --no-daemon \
    --console=plain

failures=0
while IFS=$'\t' read -r name source expected pattern; do
    cp "$fixture_root/$source/$name.kt" "$source_dir/Fixture.kt"
    set +e
    "$services_root/gradlew" \
        -p "$workspace" \
        -PtypewriterRepository="$repository" \
        clean \
        compileKotlin \
        --no-daemon \
        --console=plain \
        > "$results/$name.log" 2>&1
    result=$?
    set -e

    if [[ "$expected" == "accept" ]]; then
        if (( result != 0 )) || ! rg -q "$pattern" "$results/$name.log"; then
            print "$name failed acceptance"
            failures=$(( failures + 1 ))
        elif [[ "$name" == "generated_provider_roundtrip" ]]; then
            set +e
            "$services_root/gradlew" \
                -p "$workspace" \
                -PtypewriterRepository="$repository" \
                verifyFixture \
                --no-daemon \
                --console=plain \
                >> "$results/$name.log" 2>&1
            verification=$?
            set -e
            if (( verification != 0 )); then
                print "$name failed runtime verification"
                failures=$(( failures + 1 ))
            else
                print "$name accepted and executed"
            fi
        else
            print "$name accepted"
        fi
    elif (( result == 0 )) || ! rg -q "$pattern" "$results/$name.log"; then
        print "$name failed rejection"
        failures=$(( failures + 1 ))
    else
        print "$name rejected"
    fi
done < "$fixture_root/expectations.tsv"

print "Fixture logs: $results"
exit "$failures"
