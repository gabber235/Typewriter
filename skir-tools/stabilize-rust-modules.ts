import { Glob } from "bun";

const root = "backend/wasmcloud-utils/src/skirout";
const modules = new Glob("**/*.rs");

for await (const path of modules.scan({ cwd: root, onlyFiles: true })) {
  const file = Bun.file(`${root}/${path}`);
  const source = await file.text();
  const stable = source.replace(
    /(?:^pub mod [a-zA-Z0-9_]+;\n)+/gm,
    (block) => block.trimEnd().split("\n").sort().join("\n") + "\n",
  );
  if (stable !== source) {
    await Bun.write(file, stable);
  }
}
