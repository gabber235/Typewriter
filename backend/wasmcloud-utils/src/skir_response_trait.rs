/// Trait implemented by skir response enums via the `skir_response!` proc macro.
///
/// Provides serialization, success/error classification, and slug/message
/// generation for typed skir response enums.
pub trait SkirResponse: Sized {
    /// Serialize this response to skir bytes.
    fn to_skir_bytes(&self) -> Vec<u8>;

    /// Returns `true` if this is the success variant.
    fn is_success(&self) -> bool;

    /// Returns a kebab-case slug for this variant (e.g. `"invalid-credentials"`).
    fn variant_slug(&self) -> &'static str;

    /// Returns a human-readable message for this variant.
    fn variant_message(&self) -> String;
}
