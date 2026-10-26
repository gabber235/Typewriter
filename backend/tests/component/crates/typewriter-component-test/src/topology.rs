//! The NATS topology Typewriter's components rely on: the subjects people reach them on and the
//! JetStream streams persisted events land in, as the cluster defines them. Component fixtures and
//! the local stack both create the streams from here, so neither keeps its own copy.
//!
//! Subjects are written out here instead of rendered by the transport generator, so a generator
//! change that moves a subject fails the component tests instead of moving with them.

use component_test::{FixtureBuilder, FixtureDeclaration, subject_matches};

use crate::{Organization, StackUser};

/// The subject on which `user` calls `route` of a component, such as `organization.create`.
pub fn from_user(user: &StackUser, route: &str) -> String {
    format!("typewriter.from.user.{}.{route}", user.token())
}

/// The subject on which `user` calls `route` of `organization`, such as `members.update`.
pub fn from_member(user: &StackUser, organization: &Organization, route: &str) -> String {
    format!(
        "typewriter.from.user.{}.organization.{}.{route}",
        user.token(),
        organization.key
    )
}

/// The subject on which a component tells `user` about `event`, such as
/// `organizations.changed`.
pub fn to_user(user: &StackUser, event: &str) -> String {
    format!("typewriter.to.user.{}.{event}", user.token())
}

/// The subject on which a component tells the members of `organization` about `event`, such as
/// `members.changed`.
pub fn to_organization(organization: &Organization, event: &str) -> String {
    format!("typewriter.to.organization.{}.{event}", organization.key)
}

/// A JetStream stream and the event subjects it captures.
///
/// Subjects are written without their direction prefix: components publish an event on
/// `typewriter.to.<subject>`, and the broker delivers it to the panel as `cloud.from.<subject>`.
pub struct Stream {
    pub name: &'static str,
    subjects: &'static [&'static str],
}

impl Stream {
    /// The subjects as the publishing components see them.
    pub fn published_subjects(&self) -> impl Iterator<Item = String> {
        self.subjects
            .iter()
            .map(|subject| format!("typewriter.to.{subject}"))
    }

    /// The subjects as the panel receives them.
    pub fn delivered_subjects(&self) -> impl Iterator<Item = String> {
        self.subjects
            .iter()
            .map(|subject| format!("cloud.from.{subject}"))
    }
}

/// Membership changes the panel replays after reconnecting.
pub const MEMBERSHIP: Stream = Stream {
    name: "TYPEWRITER_MEMBERSHIP",
    subjects: &[
        "organization.*.members.changed",
        "organization.*.join_requests.changed",
        "organization.*.join_codes.changed",
        "user.*.join_requests.changed",
        "user.*.organizations.changed",
    ],
};

/// Every stream of the topology.
pub const STREAMS: &[Stream] = &[MEMBERSHIP];

/// Reports whether a component publish on `subject` is persisted into a stream.
pub fn is_persisted(subject: &str) -> bool {
    STREAMS.iter().any(|stream| {
        stream
            .published_subjects()
            .any(|pattern| subject_matches(&pattern, subject))
    })
}

/// Creates the topology's streams in a fixture's broker account.
pub trait TopologyFixtureBuilderExt: Sized {
    fn typewriter_streams(self) -> Self;
}

impl<F: FixtureDeclaration> TopologyFixtureBuilderExt for FixtureBuilder<F> {
    fn typewriter_streams(self) -> Self {
        STREAMS.iter().fold(self, |builder, stream| {
            builder.stream(stream.name, stream.published_subjects())
        })
    }
}
