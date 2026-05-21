const fs = require('fs');
const path = require('path');

const extensionsData = {
  'VaultExtension': {
    'vault_l10n_en.json': {"vault.balance_audience.description":"Audiences grouped by balance","vault.balance_audience.title":"Audiences grouped by balance","vault.balance_fact.description":"A fact that represents a player's balance.","vault.balance_fact.title":"The balance of a player's account","vault.deposit_balance.description":"The `Deposit Balance Action` is used to deposit money into a user's balance.","vault.deposit_balance.fields.amount.help":"The amount of money to deposit.","vault.deposit_balance.fields.amount.label":"Amount","vault.deposit_balance.title":"Deposit Balance","vault.permission_audience.description":"Filters an audience based on if they have a specific permission.","vault.permission_audience.fields.permission.help":"The permission to check for.","vault.permission_audience.fields.permission.label":"Permission","vault.permission_audience.title":"Filters an audience based on if they have a specific permission","vault.permission_fact.description":"A fact that checks if the player has a certain permission.","vault.permission_fact.fields.permission.help":"The permission to check for","vault.permission_fact.fields.permission.label":"Permission","vault.permission_fact.title":"If the player has a permission","vault.permission_group.description":"A group for which a player has a certain permission.","vault.permission_group.title":"Groups grouped by permission","vault.set_prefix.description":"The `Set Prefix Action` action sets the prefix of a player's message","vault.set_prefix.fields.prefix.help":"The prefix to set.","vault.set_prefix.fields.prefix.label":"Prefix","vault.set_prefix.title":"Set Prefix","vault.withdraw_balance.description":"The `Withdraw Balance Action` is used to withdraw money from a user's balance.","vault.withdraw_balance.fields.amount.help":"The amount of money to withdraw.","vault.withdraw_balance.fields.amount.label":"Amount","vault.withdraw_balance.title":"Withdraw Balance"},
    'vault_l10n_ru.json': {"vault.balance_audience.description":"Аудитории, сгруппированные по балансу","vault.balance_audience.title":"Аудитории, сгруппированные по балансу","vault.balance_fact.description":"Факт, представляющий баланс игрока.","vault.balance_fact.title":"Баланс счета игрока","vault.deposit_balance.description":"Действие пополнения баланса используется для пополнения денег на счет пользователя.","vault.deposit_balance.fields.amount.help":"Сумма денег для пополнения.","vault.deposit_balance.fields.amount.label":"Сумма","vault.deposit_balance.title":"Пополнить баланс","vault.permission_audience.description":"Фильтрует аудиторию на основе определенного разрешения.","vault.permission_audience.fields.permission.help":"Разрешение для проверки.","vault.permission_audience.fields.permission.label":"Разрешение","vault.permission_audience.title":"Фильтрует аудиторию на основе определенного разрешения","vault.permission_fact.description":"Факт, который проверяет, есть ли у игрока определенное разрешение.","vault.permission_fact.fields.permission.help":"Разрешение для проверки","vault.permission_fact.fields.permission.label":"Разрешение","vault.permission_fact.title":"Есть ли у игрока разрешение","vault.permission_group.description":"Группа разрешений - это группа, для которой игрок имеет определенное разрешение.","vault.permission_group.title":"Группы, сгруппированные по разрешениям","vault.set_prefix.description":"Действие установления префикса устанавливает префикс сообщения игрока","vault.set_prefix.fields.prefix.help":"Префикс для установки.","vault.set_prefix.fields.prefix.label":"Префикс","vault.set_prefix.title":"Установить префикс","vault.withdraw_balance.description":"Действие вывода баланса используется для вывода денег со счета пользователя.","vault.withdraw_balance.fields.amount.help":"Сумма денег для вывода.","vault.withdraw_balance.fields.amount.label":"Сумма","vault.withdraw_balance.title":"Вывести баланс"}
  },
  'EntityExtension': {
    'entity_l10n_en.json': {"entity.comment":"English translations for EntityExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."},
    'entity_l10n_ru.json': {"entity.comment":"Russian translations for EntityExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."}
  },
  'BasicExtension': {
    'basic_l10n_en.json': {"basic.comment":"English translations for BasicExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."},
    'basic_l10n_ru.json': {"basic.comment":"Russian translations for BasicExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."}
  },
  'CitizensExtension': {
    'citizens_l10n_en.json': {"citizens.comment":"English translations for CitizensExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."},
    'citizens_l10n_ru.json': {"citizens.comment":"Russian translations for CitizensExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."}
  },
  'QuestExtension': {
    'quest_l10n_en.json': {"quest.comment":"English translations for QuestExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."},
    'quest_l10n_ru.json': {"quest.comment":"Russian translations for QuestExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."}
  },
  'WorldGuardExtension': {
    'worldguard_l10n_en.json': {"worldguard.comment":"English translations for WorldGuardExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."},
    'worldguard_l10n_ru.json': {"worldguard.comment":"Russian translations for WorldGuardExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."}
  },
  'SuperiorSkyblockExtension': {
    'superiorskyblock_l10n_en.json': {"superiorskyblock.comment":"English translations for SuperiorSkyblockExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."},
    'superiorskyblock_l10n_ru.json': {"superiorskyblock.comment":"Russian translations for SuperiorSkyblockExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."}
  },
  'RoadNetworkExtension': {
    'roadnetwork_l10n_en.json': {"roadnetwork.comment":"English translations for RoadNetworkExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."},
    'roadnetwork_l10n_ru.json': {"roadnetwork.comment":"Russian translations for RoadNetworkExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."}
  },
  'RPGRegionsExtension': {
    'rpgregions_l10n_en.json': {"rpgregions.comment":"English translations for RPGRegionsExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."},
    'rpgregions_l10n_ru.json': {"rpgregions.comment":"Russian translations for RPGRegionsExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."}
  },
  'MythicMobsExtension': {
    'mythicmobs_l10n_en.json': {"mythicmobs.comment":"English translations for MythicMobsExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."},
    'mythicmobs_l10n_ru.json': {"mythicmobs.comment":"Russian translations for MythicMobsExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."}
  },
  '_DocsExtension': {
    'docs_l10n_en.json': {"docs.comment":"English translations for _DocsExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."},
    'docs_l10n_ru.json': {"docs.comment":"Russian translations for _DocsExtension - auto-generated stubs. Run generate_all_l10n.py to populate with real data."}
  }
};

const basePath = 'c:\\Users\\Ося\\Documents\\Dev\\Minecraft\\plugins\\Typewriter\\extensions';
let filesCreated = 0;
let errors = [];

for (const [extName, files] of Object.entries(extensionsData)) {
  const targetDir = path.join(basePath, extName, 'src', 'main', 'resources', 'translations');
  
  // Create directory recursively
  try {
    fs.mkdirSync(targetDir, { recursive: true });
    console.log(`✓ Directory: ${extName}`);
  } catch (err) {
    errors.push(`Error creating dir ${extName}: ${err.message}`);
    continue;
  }
  
  // Create files
  for (const [filename, content] of Object.entries(files)) {
    const filepath = path.join(targetDir, filename);
    try {
      fs.writeFileSync(filepath, JSON.stringify(content, null, 2), 'utf8');
      filesCreated++;
      console.log(`  ✓ ${filename}`);
    } catch (err) {
      errors.push(`Error creating ${filename} in ${extName}: ${err.message}`);
    }
  }
}

console.log(`\n✓ Created ${filesCreated} files!`);
if (errors.length > 0) {
  console.log('\nErrors:');
  errors.forEach(e => console.log(`  ✗ ${e}`));
}
