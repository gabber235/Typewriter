//! Storage of generated Skir values in SurrealDB.
//!
//! Row structs hold generated Skir types directly through [`SkirDb`] instead of hand written
//! copies with conversion tables, so the Skir declaration is the only model of a stored value and
//! the schema literals are the only other place its names appear.

use serde::{Deserialize, Deserializer, Serialize, Serializer, de, ser};
use skir_client::{JsonFlavor, UnrecognizedValues};

/// Gives generic code the serializer of a generated Skir type.
///
/// The transport generator implements it for every generated Skir record, beside the
/// `SkirResponse` implementations that serialize through it.
pub trait SkirType: Sized + 'static {
    /// Returns the generated serializer of this type.
    fn serializer() -> skir_client::Serializer<Self>;

    /// Reports whether this value is the generated unknown variant of an enum.
    ///
    /// The unknown variant stands for a variant this schema does not declare, so it carries
    /// nothing a reader of this schema can interpret. Structs are never unknown.
    fn is_unknown(&self) -> bool {
        false
    }
}

/// Stores a generated Skir value in SurrealDB as its readable Skir JSON.
///
/// An enum constant stores its Skir variant name, such as `"rolled_back"`; a wrapper variant
/// stores `{ "kind": <name>, "value": <payload> }`; a struct stores an object keyed by Skir field
/// names that omits fields holding their default value. Schema literals therefore spell the Skir
/// names, and renaming a Skir field or variant changes the stored data. A Skir timestamp stores
/// as an object, so a value whose column the schema declares as `datetime` must stay a storage
/// field instead of being wrapped.
///
/// The unknown variant is rejected in both directions: serializing it fails, and so does loading
/// a stored name this schema does not declare, so an unrecognized value never reaches domain
/// code as unknown.
#[derive(Debug, Clone, PartialEq)]
pub struct SkirDb<T>(pub T);

impl<T: SkirType> Serialize for SkirDb<T> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        if self.0.is_unknown() {
            return Err(ser::Error::custom(
                "the unknown Skir variant cannot be stored",
            ));
        }
        let json: serde_json::Value =
            serde_json::from_str(&T::serializer().to_json(&self.0, JsonFlavor::Readable))
                .map_err(ser::Error::custom)?;
        json.serialize(serializer)
    }
}

impl<'de, T: SkirType> Deserialize<'de> for SkirDb<T> {
    fn deserialize<D: Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
        let json = serde_json::Value::deserialize(deserializer)?;
        let value = T::serializer()
            .from_json(&json.to_string(), UnrecognizedValues::Keep)
            .map_err(de::Error::custom)?;
        if value.is_unknown() {
            return Err(de::Error::custom(format!(
                "stored Skir value {json} is not a variant this schema declares"
            )));
        }
        Ok(SkirDb(value))
    }
}

#[cfg(test)]
mod tests {
    use serde_json::json;

    use super::SkirDb;
    use crate::skir::base::service::v1::{
        service::{ServiceRole, ServiceRole_Custom, ServiceStatus},
        topology::{ChildRuntimeStatus, EngineTarget, HostRuntimeStatus},
    };

    fn stored<T: super::SkirType>(value: T) -> serde_json::Value {
        serde_json::to_value(SkirDb(value)).unwrap()
    }

    fn loaded<T: super::SkirType>(json: serde_json::Value) -> Result<T, serde_json::Error> {
        serde_json::from_value::<SkirDb<T>>(json).map(|SkirDb(value)| value)
    }

    #[test]
    fn enum_constants_store_their_skir_names() {
        let child = [
            (ChildRuntimeStatus::Absent, "absent"),
            (ChildRuntimeStatus::Staging, "staging"),
            (ChildRuntimeStatus::Active, "active"),
            (ChildRuntimeStatus::Quiescing, "quiescing"),
            (ChildRuntimeStatus::Failed, "failed"),
            (ChildRuntimeStatus::RolledBack, "rolled_back"),
            (ChildRuntimeStatus::Drifted, "drifted"),
        ];
        for (status, name) in child {
            assert_eq!(stored(status.clone()), json!(name));
            assert_eq!(loaded::<ChildRuntimeStatus>(json!(name)).unwrap(), status);
        }
        let host = [
            (HostRuntimeStatus::Offline, "offline"),
            (HostRuntimeStatus::Reconciling, "reconciling"),
            (HostRuntimeStatus::Active, "active"),
            (HostRuntimeStatus::Failed, "failed"),
            (HostRuntimeStatus::Drifted, "drifted"),
        ];
        for (status, name) in host {
            assert_eq!(stored(status.clone()), json!(name));
            assert_eq!(loaded::<HostRuntimeStatus>(json!(name)).unwrap(), status);
        }
        for (status, name) in [
            (ServiceStatus::Online, "online"),
            (ServiceStatus::Offline, "offline"),
        ] {
            assert_eq!(stored(status.clone()), json!(name));
            assert_eq!(loaded::<ServiceStatus>(json!(name)).unwrap(), status);
        }
    }

    #[test]
    fn structs_and_wrapper_variants_store_readable_objects() {
        let target = EngineTarget {
            engine_id: "paper".into(),
            version_constraint: String::new(),
            _unrecognized: None,
        };
        assert_eq!(stored(target.clone()), json!({ "engine_id": "paper" }));
        assert_eq!(
            loaded::<EngineTarget>(json!({ "engine_id": "paper" })).unwrap(),
            target
        );

        let role = ServiceRole::Custom(Box::new(ServiceRole_Custom {
            name: "voice".into(),
            version: "2".into(),
            _unrecognized: None,
        }));
        let json = json!({ "kind": "custom", "value": { "name": "voice", "version": "2" } });
        assert_eq!(stored(role.clone()), json);
        assert_eq!(loaded::<ServiceRole>(json).unwrap(), role);
    }

    #[test]
    fn the_unknown_variant_is_never_stored() {
        let error = serde_json::to_value(SkirDb(ChildRuntimeStatus::Unknown(None))).unwrap_err();
        assert!(error.to_string().contains("unknown Skir variant"));
    }

    #[test]
    fn undeclared_stored_names_are_rejected_on_load() {
        // Skir also reads the upper case spelling of a declared name; the schema literals keep
        // stored values to the Skir names.
        assert_eq!(
            loaded::<ChildRuntimeStatus>(json!("ROLLED_BACK")).unwrap(),
            ChildRuntimeStatus::RolledBack
        );
        for json in [json!("ROLLEDBACK"), json!("unknown"), json!("paused")] {
            let error = loaded::<ChildRuntimeStatus>(json).unwrap_err();
            assert!(
                error
                    .to_string()
                    .contains("not a variant this schema declares")
            );
        }
        assert!(loaded::<ServiceRole>(json!({ "kind": "admin", "value": {} })).is_err());
    }
}
