use crate::wasmcloud::messaging;

pub struct SkirSubject<M> {
    subject: String,
    serialize: fn(&M) -> Vec<u8>,
}

impl<M> SkirSubject<M> {
    pub fn new(subject: impl Into<String>, serialize: fn(&M) -> Vec<u8>) -> Self {
        Self {
            subject: subject.into(),
            serialize,
        }
    }

    pub fn subject(&self) -> &str {
        &self.subject
    }

    pub async fn publish(&self, message: M) -> Result<(), otel_wasi::Error> {
        messaging::publish(self.subject.clone(), (self.serialize)(&message)).await
    }
}

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
