import sqlParser from "node-sql-parser";

const parser = new sqlParser.Parser();
const identifier = '(?:[a-zA-Z_][a-zA-Z0-9_]*|"(?:[^"]|"")+")';
const describe = new RegExp(`^DESCRIBE\\s+${identifier}(?:\\.${identifier})?\\s*;?\\s*$`, "i");

/** Accept one parsed read statement. Unsupported dialect forms fail closed. */
export function assertReadOnly(sql: string): void {
    if (!sql.trim() || sql.length > 32_000) throw new Error("SQL must contain 1 to 32000 characters.");
    if (describe.test(sql.trim()) || /^SHOW\s+(TABLES|DATABASES)\s*;?\s*$/i.test(sql.trim())) return;
    const query = sql.trim().replace(/^EXPLAIN\s+/i, "");
    let ast: unknown;
    try {
        ast = parser.astify(query, { database: "Postgresql" });
    } catch {
        throw new Error("Unsupported SQL. Use one SELECT, read CTE, EXPLAIN SELECT, SHOW TABLES, SHOW DATABASES, or DESCRIBE table.");
    }
    const statements = Array.isArray(ast) ? ast : [ast];
    if (statements.length !== 1 || statements[0]?.type !== "select") throw new Error("Only one read query is allowed.");
    inspect(statements[0]);
}

function inspect(value: unknown): void {
    if (!value || typeof value !== "object") return;
    const node = value as Record<string, unknown>;
    if (typeof node.type === "string" && /^(insert|update|delete|replace|merge|create|drop|alter|truncate|call|copy|grant|revoke|execute|set|transaction)$/i.test(node.type)) {
        throw new Error("Mutating SQL is forbidden, including inside CTEs.");
    }
    if (node.type === "select" && node.into && Object.values(node.into as object).some(v => v !== null)) {
        throw new Error("SELECT INTO is forbidden.");
    }
    for (const child of Object.values(node)) inspect(child);
}

export const quoteIdentifier = (value: string): string => `"${value.replaceAll('"', '""')}"`;
export const quoteString = (value: string): string => `'${value.replaceAll("'", "''")}'`;
