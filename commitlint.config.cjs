const fs = require("node:fs");
const path = require("node:path");

const ROOT = __dirname;
const SCOPE_CONFIG_PATH = path.join(ROOT, "commit-scopes.json");

const ALLOWED_TYPES = [
    "feat",
    "fix",
    "docs",
    "style",
    "refactor",
    "perf",
    "test",
    "build",
    "ci",
    "chore",
    "revert",
];

function readScopeConfig() {
    const rawConfig = fs.readFileSync(SCOPE_CONFIG_PATH, "utf8");
    const config = JSON.parse(rawConfig);

    if (!Array.isArray(config.scopes)) {
        throw new Error("commit-scopes.json must contain a scopes array");
    }

    if (!Array.isArray(config.scopeRequiredForTypes)) {
        throw new Error("commit-scopes.json must contain a scopeRequiredForTypes array");
    }

    return config;
}

function normalizeScopeName(value) {
    return value.trim().toLowerCase().replace(/\s+/g, "-");
}

function normalizeConfigList(values, fieldName) {
    const normalized = values.map((value) => normalizeScopeName(String(value))).filter(Boolean);
    const duplicates = normalized.filter((value, index) => normalized.indexOf(value) !== index);

    if (duplicates.length > 0) {
        throw new Error(`${fieldName} contains duplicate value(s): ${Array.from(new Set(duplicates)).join(", ")}`);
    }

    return normalized;
}

function parseScopes(scopeText) {
    if (!scopeText) {
        return [];
    }

    return scopeText
        .split(",")
        .map((scope) => scope.trim())
        .filter(Boolean);
}

const scopeConfig = readScopeConfig();
const allowedScopes = normalizeConfigList(scopeConfig.scopes, "scopes").sort();
const allowedScopeSet = new Set(allowedScopes);
const requiredScopeTypes = new Set(normalizeConfigList(scopeConfig.scopeRequiredForTypes, "scopeRequiredForTypes"));

module.exports = {
    plugins: [
        {
            rules: {
                "scope-enum-dynamic": (parsed) => {
                    const scopes = parseScopes(parsed.scope);
                    if (scopes.length === 0) {
                        return [true];
                    }

                    const invalidScopes = scopes.filter((scope) => !allowedScopeSet.has(scope));
                    if (invalidScopes.length === 0) {
                        return [true];
                    }

                    return [
                        false,
                        `unknown scope(s): ${invalidScopes.join(", ")}. Allowed scopes: ${allowedScopes.join(", ")}`,
                    ];
                },
                "scope-required-for-type": (parsed) => {
                    if (!parsed.type || !requiredScopeTypes.has(parsed.type)) {
                        return [true];
                    }

                    if (parseScopes(parsed.scope).length > 0) {
                        return [true];
                    }

                    return [false, `scope is required for type ${parsed.type}`];
                },
            },
        },
    ],
    rules: {
        "type-empty": [2, "never"],
        "subject-empty": [2, "never"],
        "header-max-length": [2, "always", 120],
        "type-enum": [2, "always", ALLOWED_TYPES],
        "scope-enum": [0],
        "scope-empty": [0],
        "scope-enum-dynamic": [2, "always"],
        "scope-required-for-type": [2, "always"],
    },
};
