const fs = require('fs');
const path = require('path');

const extensions = [
  { name: 'VaultExtension', namespace: 'vault' },
  { name: 'EntityExtension', namespace: 'entity' },
  { name: 'BasicExtension', namespace: 'basic' },
  { name: 'CitizensExtension', namespace: 'citizens' },
  { name: 'QuestExtension', namespace: 'quest' },
  { name: 'WorldGuardExtension', namespace: 'worldguard' },
  { name: 'SuperiorSkyblockExtension', namespace: 'superiorskyblock' },
  { name: 'RoadNetworkExtension', namespace: 'roadnetwork' },
  { name: 'RPGRegionsExtension', namespace: 'rpgregions' },
  { name: 'MythicMobsExtension', namespace: 'mythicmobs' },
  { name: '_DocsExtension', namespace: 'docs' }
];

console.log('Organizing localization files...\n');

let movedCount = 0;

extensions.forEach(ext => {
  const srcDir = path.join(process.cwd(), ext.name, 'src', 'main');
  const targetDir = path.join(process.cwd(), ext.name, 'src', 'main', 'resources', 'translations');
  
  // Create target directory if it doesn't exist
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
    console.log(`Created directory: ${ext.name}/src/main/resources/translations`);
  }
  
  // Move EN and RU files
  ['en', 'ru'].forEach(lang => {
    const srcFile = path.join(srcDir, `${ext.namespace}_l10n_${lang}.json`);
    const targetFile = path.join(targetDir, `${ext.namespace}_l10n_${lang}.json`);
    
    if (fs.existsSync(srcFile)) {
      try {
        fs.renameSync(srcFile, targetFile);
        console.log(`✓ Moved: ${ext.namespace}_l10n_${lang}.json`);
        movedCount++;
      } catch (err) {
        console.error(`✗ Error moving ${srcFile}: ${err.message}`);
      }
    }
  });
});

console.log(`\nTotal files moved: ${movedCount}`);

// Verification
console.log('\n=== Verification ===\n');
let verifiedCount = 0;

extensions.forEach(ext => {
  ['en', 'ru'].forEach(lang => {
    const targetFile = path.join(process.cwd(), ext.name, 'src', 'main', 'resources', 'translations', `${ext.namespace}_l10n_${lang}.json`);
    if (fs.existsSync(targetFile)) {
      console.log(`✓ ${ext.name}: ${ext.namespace}_l10n_${lang}.json`);
      verifiedCount++;
    } else {
      console.log(`✗ ${ext.name}: ${ext.namespace}_l10n_${lang}.json - NOT FOUND`);
    }
  });
});

console.log(`\nTotal files verified: ${verifiedCount}`);
