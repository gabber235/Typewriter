use std::marker::PhantomData;

use crate::{SkirResponse, wasmcloud::messaging};

pub struct SkirSubject<R> {
    subject: String,
    _response: PhantomData<fn() -> R>,
}

impl<R> SkirSubject<R> {
    pub fn new(subject: impl Into<String>) -> Self {
        Self {
            subject: subject.into(),
            _response: PhantomData,
        }
    }

    pub fn subject(&self) -> &str {
        &self.subject
    }
}

impl<R> SkirSubject<R>
where
    R: SkirResponse,
{
    pub async fn publish(&self, response: R) -> Result<(), otel_wasi::Error> {
        messaging::publish(self.subject.clone(), response.to_skir_bytes()).await
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
                $crate::SkirSubject::new(format!(
                    $template,
                    $( $param = $param ),*
                ))
            }
        )*
    };
}
