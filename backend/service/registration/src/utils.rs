use crate::typewriter;

pub fn map_service_types(types: &[String]) -> Vec<i32> {
    types
        .iter()
        .filter_map(|t| match t.as_str() {
            "engine" => Some(typewriter::models::v1::ServiceType::Engine as i32),
            "realm" => Some(typewriter::models::v1::ServiceType::Realm as i32),
            _ => None,
        })
        .collect()
}

pub fn generate_registration_token() -> String {
    const CHARSET: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    let uuid = uuid::Uuid::new_v4();
    let uuid_bytes = uuid.as_bytes();

    uuid_bytes
        .iter()
        .take(10)
        .map(|b| {
            let idx = (*b as usize) % CHARSET.len();
            CHARSET[idx] as char
        })
        .collect()
}
