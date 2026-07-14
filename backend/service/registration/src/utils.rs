pub fn generate_registration_token() -> String {
    const CHARSET: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    let uuid = uuid::Uuid::new_v4();

    uuid.as_bytes()
        .iter()
        .take(10)
        .map(|byte| CHARSET[*byte as usize % CHARSET.len()] as char)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn registration_token_matches_schema() {
        for _ in 0..32 {
            let token = generate_registration_token();
            assert_eq!(token.len(), 10);
            assert!(
                token
                    .chars()
                    .all(|character| character.is_ascii_uppercase() || character.is_ascii_digit())
            );
        }
    }
}
