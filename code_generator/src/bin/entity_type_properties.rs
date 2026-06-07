/// This script generates parts for the EntityTypeProperty.kt file.
/// It uses the data provided by https://joakimthorsen.github.io/MCPropertyEncyclopedia/entities.html?selection=eye_height,height,id,width
/// To generate the different parts of the data.
use serde::{Deserialize, Serialize};
use std::collections::{BTreeSet, HashMap};
use std::fs::File;
use std::io::Write;

#[derive(Debug, Deserialize, Serialize)]
struct Entity {
    entity: String,
    eye_height: EntityDimension,
    height: EntityDimension,
    id: String,
    width: EntityDimension,
}

#[derive(Debug, Deserialize, Serialize)]
#[serde(untagged)]
enum EntityDimension {
    NonExistant(String),
    Simple(f64),
    Complex(HashMap<String, f64>),
}

fn parse_json(json_str: &str) -> Result<Vec<Entity>, serde_json::Error> {
    serde_json::from_str(json_str)
}

fn format_value(value: f64) -> String {
    if value == value.trunc() {
        format!("{:.1}", value)
    } else {
        format!("{}", value)
    }
}

fn format_property(property: &str, value: &str) -> String {
    match property {
        "pose" => format!("pose = EntityPose.{}", value.to_uppercase()),
        "puff_state" => format!("puffState = PufferFishMeta.State.entries[{}]", value),
        "is_baby" => format!("isBaby = {}", value),
        _ => format!("{} = {}", property, value),
    }
}

fn parse_conditions(condition_set: &str) -> Vec<String> {
    condition_set
        .split(", ")
        .filter_map(|condition| {
            let parts: Vec<&str> = condition.split(": ").collect();
            if parts.len() == 2 {
                Some(format_property(parts[0], parts[1]))
            } else {
                None
            }
        })
        .collect()
}

fn should_use_default_eye_height(eye_height: Option<f64>, height: f64) -> bool {
    let Some(eye_height) = eye_height else {
        return true
    };

    const TOLERANCE: f64 = 0.001;
    (eye_height - height * 0.85).abs() < TOLERANCE
}

fn extract_dimension_map(dimension: &EntityDimension) -> HashMap<String, f64> {
    match dimension {
        EntityDimension::NonExistant(_) => HashMap::new(),
        EntityDimension::Simple(val) => {
            let mut map = HashMap::new();
            map.insert(String::new(), *val);
            map
        }
        EntityDimension::Complex(map) => map.clone(),
    }
}

fn find_matching_value(map: &HashMap<String, f64>, target_condition: &str) -> Option<f64> {
    if let Some(value) = map.get(target_condition) {
        return Some(*value);
    }

    for (key, value) in map {
        if conditions_match(key, target_condition) {
            return Some(*value);
        }
    }

    if target_condition.is_empty() {
        map.get("")
            .copied()
            .or_else(|| map.values().next().copied())
    } else {
        None
    }
}

fn conditions_match(key: &str, target: &str) -> bool {
    if key.contains(target) || target.contains(key) {
        return true;
    }

    if !target.is_empty() && !key.is_empty() {
        let target_parts: std::collections::HashSet<_> = target.split(", ").collect();
        let key_parts: std::collections::HashSet<_> = key.split(", ").collect();
        target_parts.intersection(&key_parts).count() > 0
    } else {
        false
    }
}

fn collect_all_conditions(
    width_map: &HashMap<String, f64>,
    height_map: &HashMap<String, f64>,
    eye_height_map: &HashMap<String, f64>,
) -> BTreeSet<String> {
    let mut all_conditions = BTreeSet::new();

    for key in width_map
        .keys()
        .chain(height_map.keys())
        .chain(eye_height_map.keys())
    {
        for condition_set in key.split("<br>") {
            all_conditions.insert(condition_set.to_string());
        }
    }

    all_conditions
}

fn generate_entity_kotlin_entries(entity: &Entity) -> Vec<String> {
    let entity_type = format!("EntityTypes.{}", entity.id.to_uppercase());

    let width_map = extract_dimension_map(&entity.width);
    let height_map = extract_dimension_map(&entity.height);
    let eye_height_map = extract_dimension_map(&entity.eye_height);

    let all_conditions = collect_all_conditions(&width_map, &height_map, &eye_height_map);

    all_conditions
        .iter()
        .filter_map(|condition_set| {
            let width = find_matching_value(&width_map, condition_set)?;
            let height = find_matching_value(&height_map, condition_set)?;
            let eye_height = find_matching_value(&eye_height_map, condition_set);

            let eye_height_str = if should_use_default_eye_height(eye_height, height) {
                String::new()
            } else {
                format!(", eyeHeight = {}", format_value(eye_height.expect("Should have used default value of eye height")))
            };

            let matcher = if condition_set.is_empty() {
                format!("EntityDataMatcher({})", entity_type)
            } else {
                let conditions = parse_conditions(condition_set);
                format!(
                    "EntityDataMatcher({}, {})",
                    entity_type,
                    conditions.join(", ")
                )
            };

            Some(format!(
                "{} to EntityData(width = {}, height = {}{})",
                matcher,
                format_value(width),
                format_value(height),
                eye_height_str
            ))
        })
        .collect()
}

fn generate_kotlin_entries(entities: &[Entity]) -> Vec<String> {
    entities
        .iter()
        .flat_map(generate_entity_kotlin_entries)
        .collect()
}

fn write_entity_data_entries(entries: &[String]) -> std::io::Result<()> {
    let mut file = File::create("EntityTypeProperty_generated.kt")?;
    writeln!(file, "//<editor-fold desc=\"Entity Data Map Entries\">")?;
    for entry in entries {
        writeln!(file, "        {},", entry)?;
    }
    writeln!(file, "//</editor-fold>")?;
    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let json_str = std::fs::read_to_string("entitylist.json")?;
    let entities = parse_json(&json_str)?;

    let kotlin_entries = generate_kotlin_entries(&entities);
    write_entity_data_entries(&kotlin_entries)?;

    println!("Generated {} entity data entries", kotlin_entries.len());

    Ok(())
}
