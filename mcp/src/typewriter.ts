/**
 * Helpers for working with Typewriter plugin data.
 *
 * Typewriter stores story content in "pages" — JSON files located in
 * plugins/Typewriter/pages/. Each page has a list of "entries"
 * (dialogue, events, facts, cinematics, etc).
 *
 * Page file shape (simplified):
 * {
 *   "id": "someId",
 *   "name": "my_page",
 *   "type": "sequence" | "static" | "cinematic" | "manifest",
 *   "entries": [ { "id": "...", "type": "...", "name": "...", ...fields } ],
 *   ...
 * }
 */
import { promises as fs } from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

export interface TypewriterEntry {
  id: string;
  name: string;
  type: string;
  [key: string]: unknown;
}

export interface TypewriterPage {
  id: string;
  name: string;
  type: string;
  entries: TypewriterEntry[];
  [key: string]: unknown;
}

export class TypewriterStore {
  constructor(public readonly pagesDir: string) {}

  private pagePath(pageName: string): string {
    // Guard against path traversal
    const safe = pageName.replace(/[^a-zA-Z0-9_\-]/g, "_");
    return path.join(this.pagesDir, `${safe}.json`);
  }

  /** Typewriter uses short random alphanumeric ids. */
  static newId(): string {
    return crypto.randomBytes(12).toString("base64url").replace(/[-_]/g, "").slice(0, 16);
  }

  async ensureDir(): Promise<void> {
    await fs.mkdir(this.pagesDir, { recursive: true });
  }

  async listPages(): Promise<{ name: string; type: string; entryCount: number }[]> {
    await this.ensureDir();
    const files = await fs.readdir(this.pagesDir);
    const result: { name: string; type: string; entryCount: number }[] = [];
    for (const f of files) {
      if (!f.endsWith(".json")) continue;
      try {
        const page = JSON.parse(
          await fs.readFile(path.join(this.pagesDir, f), "utf8")
        ) as TypewriterPage;
        result.push({
          name: page.name ?? f.replace(/\.json$/, ""),
          type: page.type ?? "unknown",
          entryCount: Array.isArray(page.entries) ? page.entries.length : 0,
        });
      } catch {
        result.push({ name: f.replace(/\.json$/, ""), type: "unreadable", entryCount: 0 });
      }
    }
    return result;
  }

  async readPage(pageName: string): Promise<TypewriterPage> {
    const raw = await fs.readFile(this.pagePath(pageName), "utf8");
    return JSON.parse(raw) as TypewriterPage;
  }

  async writePage(page: TypewriterPage): Promise<void> {
    await this.ensureDir();
    await fs.writeFile(this.pagePath(page.name), JSON.stringify(page, null, 2), "utf8");
  }

  async pageExists(pageName: string): Promise<boolean> {
    try {
      await fs.access(this.pagePath(pageName));
      return true;
    } catch {
      return false;
    }
  }

  async createPage(name: string, type: string): Promise<TypewriterPage> {
    if (await this.pageExists(name)) {
      throw new Error(`Page "${name}" already exists`);
    }
    const page: TypewriterPage = {
      id: TypewriterStore.newId(),
      name,
      type,
      entries: [],
    };
    await this.writePage(page);
    return page;
  }

  async deletePage(pageName: string): Promise<void> {
    await fs.unlink(this.pagePath(pageName));
  }

  async renamePage(oldName: string, newName: string): Promise<void> {
    if (await this.pageExists(newName)) {
      throw new Error(`Page "${newName}" already exists`);
    }
    const page = await this.readPage(oldName);
    page.name = newName;
    await this.writePage(page);
    await fs.unlink(this.pagePath(oldName));
  }

  async addEntry(
    pageName: string,
    entry: Omit<TypewriterEntry, "id"> & { id?: string }
  ): Promise<TypewriterEntry> {
    const page = await this.readPage(pageName);
    const full: TypewriterEntry = {
      id: entry.id ?? TypewriterStore.newId(),
      ...entry,
    } as TypewriterEntry;
    if (page.entries.some((e) => e.id === full.id)) {
      throw new Error(`Entry with id "${full.id}" already exists on page "${pageName}"`);
    }
    page.entries.push(full);
    await this.writePage(page);
    return full;
  }

  async updateEntry(
    pageName: string,
    entryId: string,
    patch: Record<string, unknown>
  ): Promise<TypewriterEntry> {
    const page = await this.readPage(pageName);
    const idx = page.entries.findIndex((e) => e.id === entryId);
    if (idx === -1) throw new Error(`Entry "${entryId}" not found on page "${pageName}"`);
    const updated = { ...page.entries[idx], ...patch, id: entryId } as TypewriterEntry;
    page.entries[idx] = updated;
    await this.writePage(page);
    return updated;
  }

  async deleteEntry(pageName: string, entryId: string): Promise<void> {
    const page = await this.readPage(pageName);
    const before = page.entries.length;
    page.entries = page.entries.filter((e) => e.id !== entryId);
    if (page.entries.length === before) {
      throw new Error(`Entry "${entryId}" not found on page "${pageName}"`);
    }
    await this.writePage(page);
  }

  /** Search entries across all pages by name/type/text content. */
  async searchEntries(query: string): Promise<
    { page: string; entry: TypewriterEntry }[]
  > {
    const q = query.toLowerCase();
    const hits: { page: string; entry: TypewriterEntry }[] = [];
    for (const info of await this.listPages()) {
      let page: TypewriterPage;
      try {
        page = await this.readPage(info.name);
      } catch {
        continue;
      }
      for (const entry of page.entries ?? []) {
        const hay = JSON.stringify(entry).toLowerCase();
        if (hay.includes(q)) hits.push({ page: page.name, entry });
      }
    }
    return hits;
  }

  /**
   * Validate cross-references: every "triggers"/"triggeredBy"/"criteria"/"modifiers"
   * entry id should exist somewhere.
   */
  async validate(): Promise<string[]> {
    const problems: string[] = [];
    const allIds = new Set<string>();
    const pages: TypewriterPage[] = [];
    for (const info of await this.listPages()) {
      try {
        const page = await this.readPage(info.name);
        pages.push(page);
        for (const e of page.entries ?? []) allIds.add(e.id);
      } catch (err) {
        problems.push(`Page "${info.name}" is not valid JSON: ${(err as Error).message}`);
      }
    }
    const refFields = ["triggers", "triggeredBy"];
    for (const page of pages) {
      for (const e of page.entries ?? []) {
        for (const field of refFields) {
          const val = e[field];
          if (Array.isArray(val)) {
            for (const ref of val) {
              if (typeof ref === "string" && ref && !allIds.has(ref)) {
                problems.push(
                  `Entry "${e.name ?? e.id}" (page "${page.name}") references missing id "${ref}" in "${field}"`
                );
              }
            }
          }
        }
        const crit = e["criteria"];
        if (Array.isArray(crit)) {
          for (const c of crit as { fact?: string }[]) {
            if (c && typeof c.fact === "string" && c.fact && !allIds.has(c.fact)) {
              problems.push(
                `Entry "${e.name ?? e.id}" (page "${page.name}") criteria references missing fact "${c.fact}"`
              );
            }
          }
        }
        const mods = e["modifiers"];
        if (Array.isArray(mods)) {
          for (const m of mods as { fact?: string }[]) {
            if (m && typeof m.fact === "string" && m.fact && !allIds.has(m.fact)) {
              problems.push(
                `Entry "${e.name ?? e.id}" (page "${page.name}") modifier references missing fact "${m.fact}"`
              );
            }
          }
        }
      }
    }
    return problems;
  }
}
