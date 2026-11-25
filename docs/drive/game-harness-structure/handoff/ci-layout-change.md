# Intended `.github/workflows/ci.yml` change (blocked by the permission classifier, not applied)

## plan job

```yaml
    outputs:
      areas: ${{ steps.plan.outputs.areas }}
      suites: ${{ steps.plan.outputs.suites }}
...
      - id: plan
        run: |
          echo "areas=$(devenv shell -- cargo xtask check --list --base "$BASE_SHA" | tail -n 1)" >> "$GITHUB_OUTPUT"
          echo "suites=$(devenv shell -- cargo xtask check --list --suites --base "$BASE_SHA" | tail -n 1)" >> "$GITHUB_OUTPUT"
```

## e2e job

```yaml
  e2e:
    name: e2e (${{ matrix.suite }})
    needs: plan
    if: needs.plan.outputs.suites != '[]'
    ...
    strategy:
      fail-fast: false
      matrix:
        suite: ${{ fromJSON(needs.plan.outputs.suites) }}
    env:
      GAME_SUITE: ${{ (matrix.suite == 'game' || matrix.suite == 'playtest') && '1' || '' }}
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: ${{ env.GAME_SUITE && '0' || '1' }}
      - uses: ./.github/actions/devenv
        with:
          caches: >-
            ${{ matrix.suite == 'game' && 'gradle flutter frame-vectors gradle-outputs game'
            || matrix.suite == 'playtest' && 'gradle gradle-outputs game'
            || 'gradle flutter frame-vectors' }}
          profile: e2e
          cache-scope: e2e-${{ matrix.suite }}
      - run: devenv --profile e2e shell -- cargo xtask e2e ${{ matrix.suite }} --base "$BASE_SHA"
        env:
          GH_TOKEN: ${{ github.token }}
          PLAYTEST_PINNED_RUNNER: ${{ env.GAME_SUITE }}
      # Evidence after the verdict, never part of it.
      - if: always() && env.GAME_SUITE
        run: devenv --profile e2e shell -- cargo xtask e2e ${{ matrix.suite }} --demos --base "$BASE_SHA"
        env:
          GH_TOKEN: ${{ github.token }}
          PLAYTEST_PINNED_RUNNER: ${{ env.GAME_SUITE }}
      # stage, upload (results-e2e-<suite>) and devenv-save unchanged
```

## gate job

```yaml
          AREAS: ${{ needs.plan.outputs.areas == '[]' && 'skipped' || 'success' }}
          SUITES: ${{ needs.plan.outputs.suites == '[]' && 'skipped' || 'success' }}
        run: >-
          test "$PLAN" = success && test "$COMMITS" = "$COMMITS_EXPECTED"
          && test "$CHECK" = "$AREAS" && test "$E2E" = "$SUITES" && test "$REPORT" = "$AREAS"
```

`report` keeps `needs: [plan, check, e2e]`; it already downloads every `results-*` artifact.
