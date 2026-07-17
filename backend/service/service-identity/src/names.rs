use crate::identity::{NameSource, NamingError};

pub struct GeneratedNames {
    pub authentik_username: String,
    pub display_name: String,
}

pub struct WasiNameSource;

impl NameSource for WasiNameSource {
    fn generate(&self) -> Result<GeneratedNames, NamingError> {
        let seed = fill_random_16(|remaining| {
            crate::bindings::wasi::random::random::get_random_bytes(remaining as u64)
        })?;
        Ok(generate_names(seed))
    }
}

fn fill_random_16(mut read: impl FnMut(usize) -> Vec<u8>) -> Result<[u8; 16], NamingError> {
    let mut seed = [0; 16];
    let mut written = 0;

    while written < seed.len() {
        let bytes = read(seed.len() - written);
        if bytes.is_empty() || bytes.len() > seed.len() - written {
            return Err(NamingError);
        }
        seed[written..written + bytes.len()].copy_from_slice(&bytes);
        written += bytes.len();
    }

    Ok(seed)
}

const ADJECTIVES: &[&str] = &[
    "swift", "bright", "calm", "bold", "keen", "warm", "quiet", "nimble",
];
const COLORS: &[&str] = &[
    "red", "orange", "yellow", "green", "blue", "purple", "teal", "silver",
];
const NOUNS: &[&str] = &["fox", "owl", "bear", "wolf", "deer", "hawk", "swan", "lynx"];

pub fn generate_names(seed: [u8; 16]) -> GeneratedNames {
    let hex = seed
        .iter()
        .map(|byte| format!("{byte:02x}"))
        .collect::<String>();

    let first = u64::from_le_bytes(seed[..8].try_into().unwrap());
    let second = u64::from_le_bytes(seed[8..].try_into().unwrap());

    GeneratedNames {
        authentik_username: format!("service-{hex}"),
        display_name: format!(
            "{}_{}_{}",
            ADJECTIVES[first as usize % ADJECTIVES.len()],
            COLORS[(first >> 16) as usize % COLORS.len()],
            NOUNS[second as usize % NOUNS.len()]
        ),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn names_are_deterministic_and_separate() {
        let names = generate_names([0xab; 16]);
        assert_eq!(
            names.authentik_username,
            "service-abababababababababababababababab"
        );
        assert!(names.display_name.split('_').count() == 3);
        assert_ne!(names.authentik_username, names.display_name);
    }

    #[test]
    fn random_seed_handles_short_reads() {
        let mut calls = 0;
        let seed = fill_random_16(|remaining| {
            calls += 1;
            vec![calls as u8; remaining.min(3)]
        })
        .unwrap();
        assert_eq!(calls, 6);
        assert_eq!(&seed[..3], &[1, 1, 1]);
        assert_eq!(seed[15], 6);
    }

    #[test]
    fn random_seed_rejects_no_progress() {
        assert!(fill_random_16(|_| Vec::new()).is_err());
    }
}
