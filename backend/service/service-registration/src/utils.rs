//! Small service registration helpers shared by the registrar handlers.

/// Generates a ten character uppercase alphanumeric token for the temporary bind lease.
///
/// The token is derived from a fresh UUID and is formatted to match the registration schema. It
/// is a lease credential, not a service identity or a liveness signal.
pub fn generate_registration_token() -> String {
    const CHARSET: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    let uuid = uuid::Uuid::new_v4();

    uuid.as_bytes()
        .iter()
        .take(10)
        .map(|byte| CHARSET[*byte as usize % CHARSET.len()] as char)
        .collect()
}

/// Whether the item at `index` names the same target as an earlier item of its batch.
///
/// A batch addresses each target once; a repeat is refused rather than applied twice.
pub fn repeats_earlier<T: PartialEq>(targets: &[T], index: usize) -> bool {
    targets[..index].contains(&targets[index])
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_later_repeats_of_a_target_count_as_repeats() {
        let targets = ["lobby", "arena", "lobby"];
        assert!(!repeats_earlier(&targets, 0));
        assert!(!repeats_earlier(&targets, 1));
        assert!(repeats_earlier(&targets, 2));
    }

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
