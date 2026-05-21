const fs = require('fs');
const path = require('path');

const basePath = "c:\\Users\\Ося\\Documents\\Dev\\Minecraft\\plugins\\Typewriter\\extensions";

const extensions = [
    { name: "VaultExtension", files: ["vault_l10n_en.json", "vault_l10n_ru.json"] },
    { name: "EntityExtension", files: ["entity_l10n_en.json", "entity_l10n_ru.json"] },
    { name: "BasicExtension", files: ["basic_l10n_en.json", "basic_l10n_ru.json"] },
    { name: "CitizensExtension", files: ["citizens_l10n_en.json", "citizens_l10n_ru.json"] },
    { name: "QuestExtension", files: ["quest_l10n_en.json", "quest_l10n_ru.json"] },
    { name: "WorldGuardExtension", files: ["worldguard_l10n_en.json", "worldguard_l10n_ru.json"] },
    { name: "SuperiorSkyblockExtension", files: ["superiorskyblock_l10n_en.json", "superiorskyblock_l10n_ru.json"] },
    { name: "RoadNetworkExtension", files: ["roadnetwork_l10n_en.json", "roadnetwork_l10n_ru.json"] },
    { name: "RPGRegionsExtension", files: ["rpgregions_l10n_en.json", "rpgregions_l10n_ru.json"] },
    { name: "MythicMobsExtension", files: ["mythicmobs_l10n_en.json", "mythicmobs_l10n_ru.json"] },
    { name: "_DocsExtension", files: ["docs_l10n_en.json", "docs_l10n_ru.json"] }
];

console.log("Step 1: Creating directories...");
let dirsCreated = 0;

for (const ext of extensions) {
    const targetDir = path.join(basePath, ext.name, "src", "main", "resources", "translations");
    if (!fs.existsSync(targetDir)) {
        fs.mkdirSync(targetDir, { recursive: true });
        dirsCreated++;
        console.log(`  Created: ${targetDir}`);
    } else {
        console.log(`  Already exists: ${targetDir}`);
    }
}

console.log(`\nDirectories created/verified: ${dirsCreated}\n`);

console.log("Step 2: Copying files...");
let filesCopied = 0;
const copyErrors = [];

for (const ext of extensions) {
    const sourceDir = path.join(basePath, ext.name, "src", "main");
    const targetDir = path.join(basePath, ext.name, "src", "main", "resources", "translations");
    
    for (const file of ext.files) {
        const sourcePath = path.join(sourceDir, file);
        const targetPath = path.join(targetDir, file);
        
        if (fs.existsSync(sourcePath)) {
            fs.copyFileSync(sourcePath, targetPath);
            filesCopied++;
            console.log(`  [OK] Copied: ${ext.name}/${file}`);
        } else {
            copyErrors.push(`  [MISSING] Source not found: ${ext.name}/src/main/${file}`);
            console.log(`  [MISSING] Source not found: ${ext.name}/src/main/${file}`);
        }
    }
}

console.log(`\nFiles copied: ${filesCopied}\n`);

console.log("Step 3: Verifying files...");
let filesVerified = 0;
const verifyErrors = [];

for (const ext of extensions) {
    const targetDir = path.join(basePath, ext.name, "src", "main", "resources", "translations");
    
    for (const file of ext.files) {
        const targetPath = path.join(targetDir, file);
        
        if (fs.existsSync(targetPath)) {
            filesVerified++;
            console.log(`  [VERIFIED] ${ext.name}/${file}`);
        } else {
            verifyErrors.push(`  [MISSING] ${ext.name}/${file}`);
            console.log(`  [MISSING] ${ext.name}/${file}`);
        }
    }
}

console.log("\n" + "=".repeat(60));
console.log("SUMMARY:");
console.log("=".repeat(60));
console.log(`Total extensions: ${extensions.length}`);
console.log(`Total files expected: 22`);
console.log(`Files copied: ${filesCopied}`);
console.log(`Files verified: ${filesVerified}`);

if (filesVerified === 22 && copyErrors.length === 0 && verifyErrors.length === 0) {
    console.log("\nSUCCESS: All 22 files successfully copied and verified!");
} else {
    console.log("\nISSUES FOUND:");
    if (copyErrors.length > 0) {
        console.log(`Copy errors: ${copyErrors.length}`);
        copyErrors.forEach(err => console.log(err));
    }
    if (verifyErrors.length > 0) {
        console.log(`Verification errors: ${verifyErrors.length}`);
        verifyErrors.forEach(err => console.log(err));
    }
}
