const fs = require("node:fs");
const path = require("node:path");

const ROOT = __dirname;

const TOP_LEVEL_SCOPES = [
    "backend",
    "panel",
    "engine",
    "extensions",
    "services",
    "proto",
    "documentation",
    "module-plugin",
    "marketplace",
    "discord_bot",
    "code_generator",
];

const PATH_SCOPE_ROOTS = ["backend", "services", "extensions"];
const STATIC_SCOPES = ["repo", "ci", "deps"];

const EXCLUDED_DIRECTORIES = new Set([
    ".git",
    ".idea",
    ".vscode",
    "node_modules",
    "build",
    "dist",
    "target",
    ".dart_tool",
    ".gradle",
    "out",
    "tmp",
    "temp",
    "coverage",
]);

const REQUIRED_SCOPE_TYPES = new Set(["feat", "fix", "refactor", "perf"]);

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

function normalizeScopeName(value) {
    return value.trim().toLowerCase().replace(/\s+/g, "-");
}

function isAllowedDirectoryEntry(entry) {
    return entry.isDirectory() && !entry.name.startsWith(".") && !EXCLUDED_DIRECTORIES.has(entry.name);
}

function readChildDirectories(relativeDirectory) {
    const absoluteDirectory = path.join(ROOT, relativeDirectory);
    if (!fs.existsSync(absoluteDirectory)) {
        return [];
    }
    return fs
        .readdirSync(absoluteDirectory, { withFileTypes: true })
        .filter(isAllowedDirectoryEntry)
        .map((entry) => entry.name);
}

function discoverScopes() {
    const discovered = new Set(STATIC_SCOPES.map(normalizeScopeName));

    for (const scope of TOP_LEVEL_SCOPES) {
        const normalizedScope = normalizeScopeName(scope);
        if (fs.existsSync(path.join(ROOT, scope))) {
            discovered.add(normalizedScope);
        }
    }

    for (const root of PATH_SCOPE_ROOTS) {
        const normalizedRoot = normalizeScopeName(root);
        for (const child of readChildDirectories(root)) {
            const normalizedChild = normalizeScopeName(child);
            discovered.add(`${normalizedRoot}/${normalizedChild}`);
        }
    }

    return Array.from(discovered).sort();
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

const allowedScopes = discoverScopes();
const allowedScopeSet = new Set(allowedScopes);

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
                    if (!parsed.type || !REQUIRED_SCOPE_TYPES.has(parsed.type)) {
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
