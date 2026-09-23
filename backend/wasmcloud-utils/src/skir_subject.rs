use crate::wasmcloud::messaging;

/// JetStream stream that acknowledges persisted membership events.
const MEMBERSHIP_STREAM: &str = "TYPEWRITER_MEMBERSHIP";

/// Typed address for publishing one SKIR message kind.
///
/// The subject and serializer are kept together so each constructor exposes one message type at
/// one broker address. `publish` sends a transient notification. `persist` is reserved for the
/// membership event consumer, whose request reply acknowledges acceptance by the membership stream.
pub struct SkirSubject<M> {
    subject: String,
    serialize: fn(&M) -> Vec<u8>,
}

impl<M> SkirSubject<M> {
    /// Create a typed subject from its fully rendered address and serializer.
    pub fn new(subject: impl Into<String>, serialize: fn(&M) -> Vec<u8>) -> Self {
        Self {
            subject: subject.into(),
            serialize,
        }
    }

    /// Return the broker subject used by this address.
    pub fn subject(&self) -> &str {
        &self.subject
    }

    /// Publish a transient message without waiting for a persistence acknowledgement.
    pub async fn publish(&self, message: M) -> Result<(), otel_wasi::Error> {
        messaging::publish(self.subject.clone(), (self.serialize)(&message)).await
    }

    /// Persist a membership event and verify the JetStream stream acknowledgement.
    ///
    /// A successful request means the broker returned an acknowledgement for
    /// `TYPEWRITER_MEMBERSHIP`. A reply from another stream is rejected to avoid
    /// reporting persistence for the wrong event pipeline.
    pub async fn persist(&self, message: M) -> Result<(), otel_wasi::Error> {
        let acknowledgement =
            messaging::persist(self.subject.clone(), (self.serialize)(&message)).await?;
        if acknowledgement.stream_name != MEMBERSHIP_STREAM {
            return Err(otel_wasi::Error::new(
                "membership-event-wrong-stream",
                format!(
                    "expected {MEMBERSHIP_STREAM}, got {}",
                    acknowledgement.stream_name
                ),
            ));
        }
        Ok(())
    }
}

/// Generate typed constructors for the subjects in a SKIR messaging contract.
///
/// Each generated constructor accepts displayable route parameters, renders the
/// subject template, and binds the response serializer to the resulting address.
#[macro_export]
macro_rules! define_skir_subjects {
    (
        $(
            $name:ident ( $( $param:ident ),* $(,)? )
                -> $response:ty = $template:literal;
        )*
    ) => {
        $(
            pub fn $name(
                $( $param: impl ::std::fmt::Display ),*
            ) -> $crate::SkirSubject<$response> {
                $crate::SkirSubject::new(
                    format!(
                        $template,
                        $( $param = $param ),*
                    ),
                    |message: &$response| <$response>::serializer().to_bytes(message),
                )
            }
        )*
    };
}
