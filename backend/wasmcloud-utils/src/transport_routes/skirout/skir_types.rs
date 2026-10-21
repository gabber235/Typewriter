//! Generated `SkirType` implementations of every Skir record. Do not edit; regenerate with
//! `bun run generate:protocol`.
impl crate::SkirType
    for crate::skirout::base::access::v1::permission::EntityPermissionQualifier_User
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::access::v1::permission::EntityPermissionQualifier_Service
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::access::v1::permission::EntityPermissionQualifier {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::access::v1::permission::EntityPermissionQualifier::User(_)
                | crate::skirout::base::access::v1::permission::EntityPermissionQualifier::Service(
                    _
                )
        )
    }
}
impl crate::SkirType for crate::skirout::base::access::v1::permission::Permission {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::access::v1::permission::ResponsePermission {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::access::v1::permission::Permissions {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::access::v1::permission::EntityPermissionGrant {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::access::v1::permission::GetEntityPermissionRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::access::v1::permission::GetEntityPermissionResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::access::v1::permission::GetEntityPermissionResponse::Granted(_) | crate::skirout::base::access::v1::permission::GetEntityPermissionResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::access::v1::sentinel::GetSentinelCredentialsRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::access::v1::sentinel::GetSentinelCredentialsResponse_Success
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::access::v1::sentinel::GetSentinelCredentialsResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::access::v1::sentinel::GetSentinelCredentialsResponse::InternalError(_) | crate::skirout::base::access::v1::sentinel::GetSentinelCredentialsResponse::Success(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::SetValueAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::InsertListItemAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::AppendListItemAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::RemoveListItemAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::DuplicateListItemAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::MoveListItemAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::InsertMapRowAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::UpdateMapRowAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::RemoveMapRowAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::ChooseFormAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::LocalEditorAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::action::LocalEditorAction::SetValue(_)
                | crate::skirout::base::editor::v1::action::LocalEditorAction::InsertListItem(_)
                | crate::skirout::base::editor::v1::action::LocalEditorAction::AppendListItem(_)
                | crate::skirout::base::editor::v1::action::LocalEditorAction::RemoveListItem(_)
                | crate::skirout::base::editor::v1::action::LocalEditorAction::DuplicateListItem(_)
                | crate::skirout::base::editor::v1::action::LocalEditorAction::MoveListItem(_)
                | crate::skirout::base::editor::v1::action::LocalEditorAction::InsertMapRow(_)
                | crate::skirout::base::editor::v1::action::LocalEditorAction::UpdateMapRow(_)
                | crate::skirout::base::editor::v1::action::LocalEditorAction::RemoveMapRow(_)
                | crate::skirout::base::editor::v1::action::LocalEditorAction::ChooseForm(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::ReloadRealmAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::CommandCapabilityAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::RealmEditorAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::action::RealmEditorAction::Reload(_)
                | crate::skirout::base::editor::v1::action::RealmEditorAction::Command(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::ResourceNavigationMode {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::action::ResourceNavigationMode::Open
                | crate::skirout::base::editor::v1::action::ResourceNavigationMode::Reveal
                | crate::skirout::base::editor::v1::action::ResourceNavigationMode::Edit
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::ResourceNavigationAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::AuthoringCapabilityAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::EditorAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::action::EditorAction::Local(_)
                | crate::skirout::base::editor::v1::action::EditorAction::Realm(_)
                | crate::skirout::base::editor::v1::action::EditorAction::Navigate(_)
                | crate::skirout::base::editor::v1::action::EditorAction::Authoring(_)
                | crate::skirout::base::editor::v1::action::EditorAction::Create(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::CreateFieldValue {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::action::CreateResourceAction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::AuthoringResource {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::LinkOccurrenceId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::LinkOccurrence {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::RelationProjectionDelta {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::FamilyRelationSelection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::ContractRelationSelection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::AllRelationSelection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::RelationSelection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::authoring::RelationSelection::Family(_)
                | crate::skirout::base::editor::v1::authoring::RelationSelection::Contracts(_)
                | crate::skirout::base::editor::v1::authoring::RelationSelection::All(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::TraversalBudget {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::GraphEndpoint {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::GraphStep {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::UnresolvedLink {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::authoring::UnresolvedLink::Unfilled(_)
                | crate::skirout::base::editor::v1::authoring::UnresolvedLink::UnavailableTarget(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::PresentationSubject {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::AuthoringDiagnostic {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::AuthoringInvalid {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::CatalogChanged {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::AuthoringState {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::SetValueIntent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::InsertIntent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::RemoveIntent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::MoveIntent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::CreateResourceIntent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::DeleteResourceIntent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::NewCounterpartChoice {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::CounterpartChoice {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::authoring::CounterpartChoice::Existing(_)
                | crate::skirout::base::editor::v1::authoring::CounterpartChoice::New(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::ConnectIntent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::RetagIntent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::ResourceConfigurationIntent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::EditIntent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::authoring::EditIntent::CreateResource(_)
                | crate::skirout::base::editor::v1::authoring::EditIntent::DeleteResource(_)
                | crate::skirout::base::editor::v1::authoring::EditIntent::SetValue(_)
                | crate::skirout::base::editor::v1::authoring::EditIntent::Insert(_)
                | crate::skirout::base::editor::v1::authoring::EditIntent::Remove(_)
                | crate::skirout::base::editor::v1::authoring::EditIntent::Move(_)
                | crate::skirout::base::editor::v1::authoring::EditIntent::ConnectRelation(_)
                | crate::skirout::base::editor::v1::authoring::EditIntent::DisconnectRelation(_)
                | crate::skirout::base::editor::v1::authoring::EditIntent::Retag(_)
                | crate::skirout::base::editor::v1::authoring::EditIntent::ConfigureResource(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::PreparedEdit {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::PreparedEditReady {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::AuthoringOperation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::authoring::AuthoringOperation::CommitPrepared(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::AuthoringChanged {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::LinkRepairIntent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::authoring::LinkRepairIntent::Clear(_)
                | crate::skirout::base::editor::v1::authoring::LinkRepairIntent::Remove(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::TypeArgumentChangePreview {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::ArgumentLocation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::AuthoringSearchHit {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::AuthoringSearchResult {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::AuthoringObservationId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::QueryAuthoringStateRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::QueryAuthoringStateResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::authoring::QueryAuthoringStateResponse::State(_) | crate::skirout::base::editor::v1::authoring::QueryAuthoringStateResponse::CatalogChangedError(_) | crate::skirout::base::editor::v1::authoring::QueryAuthoringStateResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::SearchAuthoringRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse::Success(_) | crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse::InvalidError(_) | crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse::CatalogChangedError(_) | crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::Committed | crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::ConflictError(_) | crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::RejectedError(_) | crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::CatalogChangedError(_) | crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::InternalError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::Ready(_) | crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::InvalidArgumentsError(_) | crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::Incomplete(_) | crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::RejectedError(_) | crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::InternalError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::authoring::PrepareTypeArgumentChangeResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::authoring::PrepareTypeArgumentChangeResponse::Prepared(_) | crate::skirout::base::editor::v1::authoring::PrepareTypeArgumentChangeResponse::NeedsInput(_) | crate::skirout::base::editor::v1::authoring::PrepareTypeArgumentChangeResponse::RejectedError(_) | crate::skirout::base::editor::v1::authoring::PrepareTypeArgumentChangeResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring_facts::LinkProjection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring_facts::TraversalDirection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::authoring_facts::TraversalDirection::Forward
                | crate::skirout::base::editor::v1::authoring_facts::TraversalDirection::Reverse
                | crate::skirout::base::editor::v1::authoring_facts::TraversalDirection::Both
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring_facts::EditExpectation_Value {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::authoring_facts::EditExpectation_Resource
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::authoring_facts::EditExpectation_ResourceExists
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::authoring_facts::EditExpectation_Configuration
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring_facts::EditExpectation_Links {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring_facts::EditExpectation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::authoring_facts::EditExpectation::Value(_)
                | crate::skirout::base::editor::v1::authoring_facts::EditExpectation::Resource(_)
                | crate::skirout::base::editor::v1::authoring_facts::EditExpectation::ResourceExists(
                    _
                )
                | crate::skirout::base::editor::v1::authoring_facts::EditExpectation::Configuration(
                    _
                )
                | crate::skirout::base::editor::v1::authoring_facts::EditExpectation::ResourceIds(_)
                | crate::skirout::base::editor::v1::authoring_facts::EditExpectation::Links(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::authoring_facts::ExpectationConflict {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::binding::BindingRef {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::InvocationId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::SearchCapabilityDefinition {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::capability::ComputationCapabilityDefinition
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::CommandCapabilityDefinition {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::CapabilityDefinition {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::capability::CapabilityDefinition::Search(_)
                | crate::skirout::base::editor::v1::capability::CapabilityDefinition::Computation(
                    _
                )
                | crate::skirout::base::editor::v1::capability::CapabilityDefinition::Command(_)
                | crate::skirout::base::editor::v1::capability::CapabilityDefinition::Authoring(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::ResourceAddress {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::capability::InvalidateResourceInstruction
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::OpenResourceInstruction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::NotificationSeverity {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::capability::NotificationSeverity::Info
                | crate::skirout::base::editor::v1::capability::NotificationSeverity::Success
                | crate::skirout::base::editor::v1::capability::NotificationSeverity::Warning
                | crate::skirout::base::editor::v1::capability::NotificationSeverity::Error
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::NotifyInstruction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::PanelInstruction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::capability::PanelInstruction::InvalidateResource(_)
                | crate::skirout::base::editor::v1::capability::PanelInstruction::OpenResource(_)
                | crate::skirout::base::editor::v1::capability::PanelInstruction::Notify(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::CapabilityInvocationRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::ComputationSuccess {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::CommandSuccess {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::CapabilityPermissionDenied {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::StaleCatalogGeneration {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::CapabilityFailure {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::ComputationResult {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::capability::ComputationResult::Success(_) | crate::skirout::base::editor::v1::capability::ComputationResult::InvalidError(_) | crate::skirout::base::editor::v1::capability::ComputationResult::UnavailableError(_) | crate::skirout::base::editor::v1::capability::ComputationResult::PermissionDeniedError(_) | crate::skirout::base::editor::v1::capability::ComputationResult::StaleGenerationError(_) | crate::skirout::base::editor::v1::capability::ComputationResult::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::capability::CommandResult {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::capability::CommandResult::Success(_)
                | crate::skirout::base::editor::v1::capability::CommandResult::InvalidError(_)
                | crate::skirout::base::editor::v1::capability::CommandResult::UnavailableError(_)
                | crate::skirout::base::editor::v1::capability::CommandResult::PermissionDeniedError(
                    _
                )
                | crate::skirout::base::editor::v1::capability::CommandResult::StaleGenerationError(
                    _
                )
                | crate::skirout::base::editor::v1::capability::CommandResult::InternalError(_)
        )
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::capability::AuthoringCapabilityDefinition
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::ResourceDisplayFormulas {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::RelationDeletePolicy {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::catalog::RelationDeletePolicy::Restrict
                | crate::skirout::base::editor::v1::catalog::RelationDeletePolicy::Cascade
                | crate::skirout::base::editor::v1::catalog::RelationDeletePolicy::Clear
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::EndpointSlot {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::catalog::EndpointSlot::First
                | crate::skirout::base::editor::v1::catalog::EndpointSlot::Second
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::EndpointCardinality {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::catalog::EndpointCardinality::One
                | crate::skirout::base::editor::v1::catalog::EndpointCardinality::Many
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::EndpointDefinition {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::RelationContract {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::DeclarationStatus {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::catalog::DeclarationStatus::Ready
                | crate::skirout::base::editor::v1::catalog::DeclarationStatus::Unavailable(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::EffectiveFieldTemplate {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::PublishedType {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::TypeDisplay {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::RepresentationKind {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::catalog::RepresentationKind::Unit
                | crate::skirout::base::editor::v1::catalog::RepresentationKind::Boolean
                | crate::skirout::base::editor::v1::catalog::RepresentationKind::Text
                | crate::skirout::base::editor::v1::catalog::RepresentationKind::Bytes
                | crate::skirout::base::editor::v1::catalog::RepresentationKind::Integer
                | crate::skirout::base::editor::v1::catalog::RepresentationKind::Float
                | crate::skirout::base::editor::v1::catalog::RepresentationKind::Decimal
                | crate::skirout::base::editor::v1::catalog::RepresentationKind::Timestamp
                | crate::skirout::base::editor::v1::catalog::RepresentationKind::Duration
                | crate::skirout::base::editor::v1::catalog::RepresentationKind::Record
                | crate::skirout::base::editor::v1::catalog::RepresentationKind::List
                | crate::skirout::base::editor::v1::catalog::RepresentationKind::Set
                | crate::skirout::base::editor::v1::catalog::RepresentationKind::Map
                | crate::skirout::base::editor::v1::catalog::RepresentationKind::Enumeration
                | crate::skirout::base::editor::v1::catalog::RepresentationKind::Link
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::RuleDescriptor {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::OwnedRule {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::ConfigurationRecipe {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::PresentationRole {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::catalog::PresentationRole::Workspace
                | crate::skirout::base::editor::v1::catalog::PresentationRole::Navigator
                | crate::skirout::base::editor::v1::catalog::PresentationRole::Inspector
                | crate::skirout::base::editor::v1::catalog::PresentationRole::Item
                | crate::skirout::base::editor::v1::catalog::PresentationRole::ReferencePreview
                | crate::skirout::base::editor::v1::catalog::PresentationRole::ReferencePickerResult
                | crate::skirout::base::editor::v1::catalog::PresentationRole::ResourceSearchResult
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::PresentationTarget {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::catalog::PresentationTarget::Named(_)
                | crate::skirout::base::editor::v1::catalog::PresentationTarget::Representation(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::PresentationDescriptor {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::PresentationMaterial {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::RoleFallback {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::EditorCatalog {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::CatalogFetchRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::CatalogFetchResult {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::catalog::CatalogFetchResult::Catalog(_) | crate::skirout::base::editor::v1::catalog::CatalogFetchResult::GenerationChangedError(_) | crate::skirout::base::editor::v1::catalog::CatalogFetchResult::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::CatalogInvalidated {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::PreparationTarget {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::catalog::PreparationTarget::Value(_)
                | crate::skirout::base::editor::v1::catalog::PreparationTarget::Record(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::ValuePreparationRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::PreparedContent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::catalog::PreparedContent::Value(_)
                | crate::skirout::base::editor::v1::catalog::PreparedContent::Record(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::PreparedValue {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::RequiredInput {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::PreparationDraft {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::InputAnswer {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::PreparationOperation_Resume {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::PreparationOperation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::catalog::PreparationOperation::Start(_)
                | crate::skirout::base::editor::v1::catalog::PreparationOperation::Resume(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::PrepareValueResult {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::catalog::PrepareValueResult::Ready(_)
                | crate::skirout::base::editor::v1::catalog::PrepareValueResult::NeedsInput(_)
                | crate::skirout::base::editor::v1::catalog::PrepareValueResult::UnavailableError(_)
                | crate::skirout::base::editor::v1::catalog::PrepareValueResult::CatalogChangedError(
                    _
                )
                | crate::skirout::base::editor::v1::catalog::PrepareValueResult::InternalError(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::EndpointBindingTemplate {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::TypeRecommendation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::ResourceAppearance {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::WatchEditorCatalogRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::catalog::WatchEditorCatalogResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::catalog::WatchEditorCatalogResponse::Invalidated(_) | crate::skirout::base::editor::v1::catalog::WatchEditorCatalogResponse::InternalError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::catalog_presentation::CatalogPresentationSubject
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::checking::CheckOutcome {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::checking::CheckOutcome::Finished
                | crate::skirout::base::editor::v1::checking::CheckOutcome::NeedsInput(_)
                | crate::skirout::base::editor::v1::checking::CheckOutcome::Failed(_)
                | crate::skirout::base::editor::v1::checking::CheckOutcome::Incomplete(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::checking::FindingStatus {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::checking::FindingStatus::Current
                | crate::skirout::base::editor::v1::checking::FindingStatus::Outdated
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::checking::CheckInstanceId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::checking::CheckTicket {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::checking::FindingSet {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::checking::CheckResult {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::compilation_root::CompilationProjectionId
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::compilation_root::CompilationRoot {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::compiled_content::CompiledBlobPointer {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::compiled_content::CompiledArtifactReference
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::compiled_content::PublishedOutput {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::compiled_content::PublishedContent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::compiled_content::CompiledResourceState {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::compiled_content::CompiledResourceState::NotCompiled
                | crate::skirout::base::editor::v1::compiled_content::CompiledResourceState::Active(
                    _
                )
        )
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::compiled_content::CompiledResourceStatus
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::compiled_content::CompiledContentChanged
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::compiled_content::CompilationStatusSelection
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::compiled_content::CompilationStatusSelection::AllRoots | crate::skirout::base::editor::v1::compiled_content::CompilationStatusSelection::SuppliedRoots(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::compiled_content::InstancePath {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::compiled_content::CompilationContext {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::compiled_content::CompiledResourceKey {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::compiled_content::CompiledResource {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::compiled_content::CompiledRelationOrigin
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::compiled_content::CompiledEdgeOrigin {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::compiled_content::CompiledEdgeOrigin::Relation(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::compiled_content::CompiledEdge {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::compiled_content::RuntimeRelationFact {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::compiled_content::RuntimeCompilationFacts
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::compiled_content::ResourceGraphShard {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::compiled_content::QueryPublishedContentRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::compiled_content::QueryPublishedContentResponse_Absent
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::compiled_content::QueryPublishedContentResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::compiled_content::QueryPublishedContentResponse::Content(_) | crate::skirout::base::editor::v1::compiled_content::QueryPublishedContentResponse::Absent(_) | crate::skirout::base::editor::v1::compiled_content::QueryPublishedContentResponse::InternalError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::compiled_content::QueryCompiledResourceStatusRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::compiled_content::QueryCompiledResourceStatusResponse_Success {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::compiled_content::QueryCompiledResourceStatusResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::compiled_content::QueryCompiledResourceStatusResponse::Success(_) | crate::skirout::base::editor::v1::compiled_content::QueryCompiledResourceStatusResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::diagnostic::DiagnosticSeverity {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::diagnostic::DiagnosticSeverity::Information
                | crate::skirout::base::editor::v1::diagnostic::DiagnosticSeverity::Warning
                | crate::skirout::base::editor::v1::diagnostic::DiagnosticSeverity::Error
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::diagnostic::DeclarationOrigin {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::diagnostic::DeclarationDiagnostic {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::diagnostic::DiagnosticTemplate {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::diagnostic::Diagnostic {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::diagnostic::ValueProblem {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::diagnostic::InitializationDiagnostic {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::diagnostic::CompleteValue {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::diagnostic::StructuralResult {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::diagnostic::StructuralResult::Valid
                | crate::skirout::base::editor::v1::diagnostic::StructuralResult::Invalid(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::diagnostic::CompletenessResult {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::diagnostic::CompletenessResult::Complete(_)
                | crate::skirout::base::editor::v1::diagnostic::CompletenessResult::Unfinished(_)
                | crate::skirout::base::editor::v1::diagnostic::CompletenessResult::Invalid(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ExpressionInput {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ExpressionLocal {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ExpressionField {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::EntryBranch {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::expression::EntryBranch::Key
                | crate::skirout::base::editor::v1::expression::EntryBranch::Value
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ExpressionEntryProjection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::BinaryExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ConditionalExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::OrElseExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::TextUnaryOperation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::expression::TextUnaryOperation::Value
                | crate::skirout::base::editor::v1::expression::TextUnaryOperation::Trim
                | crate::skirout::base::editor::v1::expression::TextUnaryOperation::Lower
                | crate::skirout::base::editor::v1::expression::TextUnaryOperation::Upper
                | crate::skirout::base::editor::v1::expression::TextUnaryOperation::Title
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::TextUnaryExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::TextCompareOperation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::expression::TextCompareOperation::Contains
                | crate::skirout::base::editor::v1::expression::TextCompareOperation::StartsWith
                | crate::skirout::base::editor::v1::expression::TextCompareOperation::EndsWith
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::TextCompareExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::TextReplaceExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::TextSplitExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::TextJoinExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::TextSubstringExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::TextInterpolateExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::RegexMatchMode {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::expression::RegexMatchMode::Search
                | crate::skirout::base::editor::v1::expression::RegexMatchMode::FullMatch
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::RegexTestExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::RegexCaptureExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::RegexReplaceExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ValueCompareOperation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::expression::ValueCompareOperation::Equal
                | crate::skirout::base::editor::v1::expression::ValueCompareOperation::NotEqual
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ValueCompareExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::NumberArithmeticOperation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::expression::NumberArithmeticOperation::Add | crate::skirout::base::editor::v1::expression::NumberArithmeticOperation::Subtract | crate::skirout::base::editor::v1::expression::NumberArithmeticOperation::Multiply | crate::skirout::base::editor::v1::expression::NumberArithmeticOperation::Divide | crate::skirout::base::editor::v1::expression::NumberArithmeticOperation::Remainder)
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::NumberArithmeticExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::NumberCompareOperation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::expression::NumberCompareOperation::Greater
                | crate::skirout::base::editor::v1::expression::NumberCompareOperation::GreaterEqual
                | crate::skirout::base::editor::v1::expression::NumberCompareOperation::Less
                | crate::skirout::base::editor::v1::expression::NumberCompareOperation::LessEqual
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::NumberCompareExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::NumberRoundExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::NumberFormatExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::DurationFormatExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::TimestampFormatExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::CollectionAccessExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::expression::CollectionContainsExpression
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ColorWithAlphaExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::RuleUnaryOperation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::expression::RuleUnaryOperation::NonEmpty
                | crate::skirout::base::editor::v1::expression::RuleUnaryOperation::NonBlank
                | crate::skirout::base::editor::v1::expression::RuleUnaryOperation::SingleLine
                | crate::skirout::base::editor::v1::expression::RuleUnaryOperation::Positive
                | crate::skirout::base::editor::v1::expression::RuleUnaryOperation::NonNegative
                | crate::skirout::base::editor::v1::expression::RuleUnaryOperation::Unique
                | crate::skirout::base::editor::v1::expression::RuleUnaryOperation::NotNull
                | crate::skirout::base::editor::v1::expression::RuleUnaryOperation::Opaque
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::RuleUnaryExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::RuleOneOfExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::BoundDirection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::expression::BoundDirection::Minimum
                | crate::skirout::base::editor::v1::expression::BoundDirection::Maximum
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::SizeBoundMetric {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::expression::SizeBoundMetric::TextLength
                | crate::skirout::base::editor::v1::expression::SizeBoundMetric::TextLines
                | crate::skirout::base::editor::v1::expression::SizeBoundMetric::CollectionItems
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::SizeRangeMetric {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::expression::SizeRangeMetric::TextLength
                | crate::skirout::base::editor::v1::expression::SizeRangeMetric::CollectionItems
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::RuleSizeBoundExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::RuleSizeRangeExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::RuleNumericBoundExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::RuleNumericRangeExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::RuleMultipleOfExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::RuleMaximumScaleExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::TimestampBoundDirection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::expression::TimestampBoundDirection::NotBefore
                | crate::skirout::base::editor::v1::expression::TimestampBoundDirection::NotAfter
        )
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::expression::RuleTimestampBoundExpression
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::UnaryCollectionExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::FoldExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::SortByExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::SortWithExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::CollectionSliceExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ResourceIdentityQuerySource {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ResourceQuerySource {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::expression::ResourceQuerySource::Reference(_)
                | crate::skirout::base::editor::v1::expression::ResourceQuerySource::Identity(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ExpressionQuery {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::expression::ExpressionQuery::ResourceIdentity(_) | crate::skirout::base::editor::v1::expression::ExpressionQuery::ResourceValue(_) | crate::skirout::base::editor::v1::expression::ExpressionQuery::ResourceConfiguration(_) | crate::skirout::base::editor::v1::expression::ExpressionQuery::ValueConfiguration(_) | crate::skirout::base::editor::v1::expression::ExpressionQuery::CatalogDeclaration(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ExpressionNode {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::expression::ExpressionNode::Literal(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Input(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Local(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Field(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::EntryProjection(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::And(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Or(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Conditional(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::OrElse(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::TextUnary(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::TextCompare(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::TextLength(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::TextHasLineBreak(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::TextReplace(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::TextSplit(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::TextJoin(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::TextSubstring(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::TextInterpolate(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::RegexTest(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::RegexCapture(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::RegexReplace(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::ValueCompare(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::IsNull(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::LinkTarget(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::BooleanNot(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::NumberArithmetic(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::NumberCompare(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::NumberNegate(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::NumberRound(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::NumberFormat(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::DurationFormat(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::TimestampFormat(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::CollectionSize(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::CollectionAccess(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::CollectionContains(
                    _
                )
                | crate::skirout::base::editor::v1::expression::ExpressionNode::ColorWithAlpha(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::RuleUnary(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::RuleOneOf(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::RuleSizeBound(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::RuleSizeRange(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::RuleNumericBound(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::RuleNumericRange(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::RuleMultipleOf(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::RuleMaximumScale(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::RuleTimestampBound(
                    _
                )
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Any(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::All(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::None(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Map(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Filter(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Find(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::FindLast(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Count(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::DistinctBy(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::GroupBy(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::FlatMap(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::UniqueBy(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Reduce(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::SortBy(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::SortWith(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Fold(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Take(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Skip(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Reverse(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Distinct(_)
                | crate::skirout::base::editor::v1::expression::ExpressionNode::Query(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ExpressionValueType {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::expression::ExpressionValueType::Nominal(_)
                | crate::skirout::base::editor::v1::expression::ExpressionValueType::List(_)
                | crate::skirout::base::editor::v1::expression::ExpressionValueType::Map(_)
                | crate::skirout::base::editor::v1::expression::ExpressionValueType::Entry(_)
                | crate::skirout::base::editor::v1::expression::ExpressionValueType::Nullable(_)
                | crate::skirout::base::editor::v1::expression::ExpressionValueType::NullValue
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ExpressionMappingType {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ExpressionType {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::EvaluationBudget {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ExpressionBinding {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::ExpressionBindings {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::expression::EvaluationDiagnostic {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::operation::ResourceOperationId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::operation::OperationTargets {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::operation::OperationGroup {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::operation::OperationGroup::Edit
                | crate::skirout::base::editor::v1::operation::OperationGroup::Organize
                | crate::skirout::base::editor::v1::operation::OperationGroup::Destructive
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::operation::OperationConfirmation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::operation::OperationPresentation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::operation::OperationInputDefinition {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::operation::ResourceOperationDefinition {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::operation::OperationAvailability {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::operation::OperationAvailability::Hidden
                | crate::skirout::base::editor::v1::operation::OperationAvailability::Disabled(_)
                | crate::skirout::base::editor::v1::operation::OperationAvailability::Enabled
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::operation::ResolvedResourceOperation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::operation::ResolvedResourceOperations {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::operation::OperationCardinality {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::operation::OperationCardinality::Single
                | crate::skirout::base::editor::v1::operation::OperationCardinality::Selection
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::operation::OperationInspector {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::operation::OperationInspector::Hidden
                | crate::skirout::base::editor::v1::operation::OperationInspector::Button(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::operation::OperationDrop {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::operation::OperationShortcut {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::operation::OperationShortcut::Delete
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::MainAxisAlignment {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::MainAxisAlignment::Start
                | crate::skirout::base::editor::v1::presentation::MainAxisAlignment::Center
                | crate::skirout::base::editor::v1::presentation::MainAxisAlignment::End
                | crate::skirout::base::editor::v1::presentation::MainAxisAlignment::SpaceBetween
                | crate::skirout::base::editor::v1::presentation::MainAxisAlignment::SpaceAround
                | crate::skirout::base::editor::v1::presentation::MainAxisAlignment::SpaceEvenly
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::CrossAxisAlignment {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::CrossAxisAlignment::Start
                | crate::skirout::base::editor::v1::presentation::CrossAxisAlignment::Center
                | crate::skirout::base::editor::v1::presentation::CrossAxisAlignment::End
                | crate::skirout::base::editor::v1::presentation::CrossAxisAlignment::Stretch
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationProperties {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::HeaderItemId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::HeaderActionTone {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::HeaderActionTone::Neutral
                | crate::skirout::base::editor::v1::presentation::HeaderActionTone::Destructive
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::HeaderActionPlacement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::HeaderActionPlacement::BeforeTitle
                | crate::skirout::base::editor::v1::presentation::HeaderActionPlacement::AfterTitle
                | crate::skirout::base::editor::v1::presentation::HeaderActionPlacement::End
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::HeaderActionConfirmation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::HeaderButtonItem {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::HeaderBooleanToggleItem {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::HeaderReorderHandleItem {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::HeaderItem {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::HeaderItem::Button(_)
                | crate::skirout::base::editor::v1::presentation::HeaderItem::BooleanToggle(_)
                | crate::skirout::base::editor::v1::presentation::HeaderItem::ReorderHandle(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationHeaderTitle {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::presentation::PresentationHeaderTitle::Text(_) | crate::skirout::base::editor::v1::presentation::PresentationHeaderTitle::Presentation(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::SymmetricPresentationInsets
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::OnlyPresentationInsets {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationInsets {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::PresentationInsets::All(_)
                | crate::skirout::base::editor::v1::presentation::PresentationInsets::Symmetric(_)
                | crate::skirout::base::editor::v1::presentation::PresentationInsets::Only(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationHeader {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationNode {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::AxisChildrenLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::FlexFit {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::FlexFit::Tight
                | crate::skirout::base::editor::v1::presentation::FlexFit::Loose
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::FlexibleAxisChild {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::AxisChild {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::AxisChild::Fixed(_)
                | crate::skirout::base::editor::v1::presentation::AxisChild::Flexible(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::WrapChildrenLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::GridChildrenLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ChildrenLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::ChildrenLayout::Column(_)
                | crate::skirout::base::editor::v1::presentation::ChildrenLayout::Row(_)
                | crate::skirout::base::editor::v1::presentation::ChildrenLayout::Wrap(_)
                | crate::skirout::base::editor::v1::presentation::ChildrenLayout::Grid(_)
                | crate::skirout::base::editor::v1::presentation::ChildrenLayout::Stack
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::AxisChildrenElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::WrapChildrenElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::GridChildrenElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::StackChildrenElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ChildrenElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::ChildrenElement::Column(_)
                | crate::skirout::base::editor::v1::presentation::ChildrenElement::Row(_)
                | crate::skirout::base::editor::v1::presentation::ChildrenElement::Wrap(_)
                | crate::skirout::base::editor::v1::presentation::ChildrenElement::Grid(_)
                | crate::skirout::base::editor::v1::presentation::ChildrenElement::Stack(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationBorderSide {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::DirectionalPresentationBorder
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationBorder {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::PresentationBorder::All(_)
                | crate::skirout::base::editor::v1::presentation::PresentationBorder::Sides(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SectionLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PaddingLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationSlotElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TabItem {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TabsLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SpacerLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TextContent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationTextOverflow {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::presentation::PresentationTextOverflow::Clip | crate::skirout::base::editor::v1::presentation::PresentationTextOverflow::Ellipsis)
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationTextTone {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::PresentationTextTone::Primary
                | crate::skirout::base::editor::v1::presentation::PresentationTextTone::Secondary
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TextParagraph {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TextStyleOverride {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TextRun {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::RichTextContent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::AdaptiveLeadingElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::IconContent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ImageContent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::BadgeContent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ChipContent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ProgressContent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::StatusTone {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::StatusTone::Neutral
                | crate::skirout::base::editor::v1::presentation::StatusTone::UnknownStatus
                | crate::skirout::base::editor::v1::presentation::StatusTone::Information
                | crate::skirout::base::editor::v1::presentation::StatusTone::Success
                | crate::skirout::base::editor::v1::presentation::StatusTone::Warning
                | crate::skirout::base::editor::v1::presentation::StatusTone::Danger
                | crate::skirout::base::editor::v1::presentation::StatusTone::Active
                | crate::skirout::base::editor::v1::presentation::StatusTone::Inactive
                | crate::skirout::base::editor::v1::presentation::StatusTone::Online
                | crate::skirout::base::editor::v1::presentation::StatusTone::Offline
                | crate::skirout::base::editor::v1::presentation::StatusTone::Pending
                | crate::skirout::base::editor::v1::presentation::StatusTone::InProgress
                | crate::skirout::base::editor::v1::presentation::StatusTone::Paused
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::StatusAppearance {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::StatusCase {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::StatusContent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::DateTimeZone {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::DateTimeZone::Local
                | crate::skirout::base::editor::v1::presentation::DateTimeZone::Utc
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::DateTimeContent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::RelativeTimeStyle {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::RelativeTimeStyle::Compact
                | crate::skirout::base::editor::v1::presentation::RelativeTimeStyle::Natural
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::RelativeTimeContent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TypedFieldElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ConditionalElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SequencePresentation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::RepeatedElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ScopedBindingElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::CollectionGraphDirection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::CollectionGraphDirection::Forward
                | crate::skirout::base::editor::v1::presentation::CollectionGraphDirection::Reverse
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::CollectionLookupElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::CollectionGraphElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationRadius {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::PresentationRadius::None
                | crate::skirout::base::editor::v1::presentation::PresentationRadius::Small
                | crate::skirout::base::editor::v1::presentation::PresentationRadius::Medium
                | crate::skirout::base::editor::v1::presentation::PresentationRadius::Large
                | crate::skirout::base::editor::v1::presentation::PresentationRadius::Custom(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ContainerLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationAlignment {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::presentation::PresentationAlignment::TopStart | crate::skirout::base::editor::v1::presentation::PresentationAlignment::TopCenter | crate::skirout::base::editor::v1::presentation::PresentationAlignment::TopEnd | crate::skirout::base::editor::v1::presentation::PresentationAlignment::CenterStart | crate::skirout::base::editor::v1::presentation::PresentationAlignment::Center | crate::skirout::base::editor::v1::presentation::PresentationAlignment::CenterEnd | crate::skirout::base::editor::v1::presentation::PresentationAlignment::BottomStart | crate::skirout::base::editor::v1::presentation::PresentationAlignment::BottomCenter | crate::skirout::base::editor::v1::presentation::PresentationAlignment::BottomEnd)
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationOffset {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationAnchorPoint {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationAnchorLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::PresentationAnchorSelector
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::presentation::PresentationAnchorSelector::Local(_) | crate::skirout::base::editor::v1::presentation::PresentationAnchorSelector::ExportedGroup(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ConnectionExpressionScope {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::ConnectionExpressionScope::Layer
                | crate::skirout::base::editor::v1::presentation::ConnectionExpressionScope::Source
                | crate::skirout::base::editor::v1::presentation::ConnectionExpressionScope::Target
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ConnectorStroke {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ConnectionMarker {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::OrthogonalConnectionPath {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::CurvedConnectionPath {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ConnectionPath {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::ConnectionPath::Straight
                | crate::skirout::base::editor::v1::presentation::ConnectionPath::Orthogonal(_)
                | crate::skirout::base::editor::v1::presentation::ConnectionPath::Curved(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ConnectionAxis {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::ConnectionAxis::Horizontal
                | crate::skirout::base::editor::v1::presentation::ConnectionAxis::Vertical
        )
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::OrthogonalConnectionBundlePath
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ConnectionBundlePath {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::ConnectionBundlePath::Orthogonal(_)
                | crate::skirout::base::editor::v1::presentation::ConnectionBundlePath::Fan
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::AnchoredConnection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::AnchoredConnectionBundle {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationConnection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::PresentationConnection::Connection(_)
                | crate::skirout::base::editor::v1::presentation::PresentationConnection::Bundle(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ConnectionLayerLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ArrowConnectorMarker {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::CircleConnectorMarker {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ConnectorEndpointMarker {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::ConnectorEndpointMarker::Arrow(_)
                | crate::skirout::base::editor::v1::presentation::ConnectorEndpointMarker::Circle(
                    _
                )
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ConnectorStyle {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ConnectorAnchor {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::ConnectorAnchor::Start
                | crate::skirout::base::editor::v1::presentation::ConnectorAnchor::Center
                | crate::skirout::base::editor::v1::presentation::ConnectorAnchor::Offset(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::HierarchySequenceLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SequenceLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::SequenceLayout::Children(_)
                | crate::skirout::base::editor::v1::presentation::SequenceLayout::Hierarchy(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::BoundControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ColorControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::DateTimeControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SelectOption {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SelectControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SliderControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ListControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::MapControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::RecordControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ConcreteTypePresentation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PolymorphicControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::NamedControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PolymorphicMatchCase {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PolymorphicMatchElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SearchSelectionMode {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::SearchSelectionMode::Single
                | crate::skirout::base::editor::v1::presentation::SearchSelectionMode::Multiple
        )
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::SearchSelectorMultiplicity
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::presentation::SearchSelectorMultiplicity::Single | crate::skirout::base::editor::v1::presentation::SearchSelectorMultiplicity::Multiple)
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SearchSelectorEnumValues {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SearchSelectorValues {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::SearchSelectorValues::FreeText
                | crate::skirout::base::editor::v1::presentation::SearchSelectorValues::Enumeration(
                    _
                )
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SearchSelectorDefinition {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SearchResultMapping {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::HttpQueryParameter {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::HttpJsonContextBinding {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::StaticSearchProvider {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::CollectionSearchProvider {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::HttpJsonSearchProvider {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::RealmCallbackSearchProvider
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::GatedSearchProvider {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::DebouncedSearchProvider {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::CachedSearchProvider {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SearchRankingField {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::RankedSearchProvider {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::LimitedSearchProvider {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::DistinctSearchProvider {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::HistoricalSearchProvider {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SectionSearchProvider {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::MergedSearchProvider {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SearchProvider {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::SearchProvider::StaticValues(_)
                | crate::skirout::base::editor::v1::presentation::SearchProvider::HttpJson(_)
                | crate::skirout::base::editor::v1::presentation::SearchProvider::RealmCallback(_)
                | crate::skirout::base::editor::v1::presentation::SearchProvider::Gate(_)
                | crate::skirout::base::editor::v1::presentation::SearchProvider::Debounce(_)
                | crate::skirout::base::editor::v1::presentation::SearchProvider::Cache(_)
                | crate::skirout::base::editor::v1::presentation::SearchProvider::Rank(_)
                | crate::skirout::base::editor::v1::presentation::SearchProvider::Limit(_)
                | crate::skirout::base::editor::v1::presentation::SearchProvider::Distinct(_)
                | crate::skirout::base::editor::v1::presentation::SearchProvider::History(_)
                | crate::skirout::base::editor::v1::presentation::SearchProvider::Section(_)
                | crate::skirout::base::editor::v1::presentation::SearchProvider::Merge(_)
                | crate::skirout::base::editor::v1::presentation::SearchProvider::Collection(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SearchControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::DefaultPresentationElement
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::CommitControlsElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ButtonElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::IconButtonElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::MenuItem {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::MenuElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TooltipElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::presentation::PresentationElement::Children(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Section(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Padding(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Slot(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Tabs(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Divider(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Spacer(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Text(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Markdown(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Icon(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Image(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Badge(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Chip(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Progress(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Status(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::DateTime(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::RelativeTime(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::TypedField(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Conditional(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Repeated(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::ScopedBinding(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::TextInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::NumericInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::ToggleInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::SelectInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::SliderInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::DateTimeInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::DurationInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::ColorInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::BytesInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::NamedInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::CommitControls(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Button(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::IconButton(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Menu(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Tooltip(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::ListInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::MapInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::RecordInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::EnumInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::PolymorphicInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::DefaultPresentation(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::SearchInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::CollectionLookup(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::CollectionGraph(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Container(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Anchor(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::ConnectionLayer(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::PolymorphicMatch(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Invocation(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::LinkInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::RichText(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::AdaptiveLeading(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::RemainingFields(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::NullableInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::SetInput(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Resources(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Align(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::AppearanceDefaults(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Part(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Size(_) | crate::skirout::base::editor::v1::presentation::PresentationElement::Transform(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationDefinition {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationDependencies {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::PresentationCollectionRelationDefinition
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::PresentationCollectionDefinition
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::PresentationCollectionProjectionValue
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::presentation::PresentationCollectionProjectionValue::Content(_) | crate::skirout::base::editor::v1::presentation::PresentationCollectionProjectionValue::Literal(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::PresentationCollectionProjectionField
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::PresentationCollectionProjection
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationInputAccess {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::PresentationInputAccess::Read
                | crate::skirout::base::editor::v1::presentation::PresentationInputAccess::Edit
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationInput {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationArgument {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationInvocation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::LinkControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::LinkCandidatePolicyId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::LinkRejectionDisplay {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::LinkRejectionDisplay::Hidden
                | crate::skirout::base::editor::v1::presentation::LinkRejectionDisplay::Disabled
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::RemainingFieldsElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::NullableControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SetControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::GraphDirection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::GraphDirection::LeftToRight
                | crate::skirout::base::editor::v1::presentation::GraphDirection::RightToLeft
                | crate::skirout::base::editor::v1::presentation::GraphDirection::TopToBottom
                | crate::skirout::base::editor::v1::presentation::GraphDirection::BottomToTop
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ResourcesElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ResourcesLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::ResourcesLayout::Graph(_)
                | crate::skirout::base::editor::v1::presentation::ResourcesLayout::Timeline(_)
                | crate::skirout::base::editor::v1::presentation::ResourcesLayout::Grid(_)
                | crate::skirout::base::editor::v1::presentation::ResourcesLayout::Tree(_)
                | crate::skirout::base::editor::v1::presentation::ResourcesLayout::List
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TextFit {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TextSizing {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::TextSizing::Exact(_)
                | crate::skirout::base::editor::v1::presentation::TextSizing::Fit(_)
        )
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::PresentationInteractionState
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::presentation::PresentationInteractionState::Hovered | crate::skirout::base::editor::v1::presentation::PresentationInteractionState::Selected | crate::skirout::base::editor::v1::presentation::PresentationInteractionState::Focused | crate::skirout::base::editor::v1::presentation::PresentationInteractionState::Pressed | crate::skirout::base::editor::v1::presentation::PresentationInteractionState::Disabled | crate::skirout::base::editor::v1::presentation::PresentationInteractionState::ReadOnly | crate::skirout::base::editor::v1::presentation::PresentationInteractionState::Invalid | crate::skirout::base::editor::v1::presentation::PresentationInteractionState::Routed | crate::skirout::base::editor::v1::presentation::PresentationInteractionState::DropAccepted | crate::skirout::base::editor::v1::presentation::PresentationInteractionState::DropRejected)
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationStateMatch {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationThemeColor {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::presentation::PresentationThemeColor::Primary | crate::skirout::base::editor::v1::presentation::PresentationThemeColor::OnPrimary | crate::skirout::base::editor::v1::presentation::PresentationThemeColor::Surface | crate::skirout::base::editor::v1::presentation::PresentationThemeColor::OnSurface | crate::skirout::base::editor::v1::presentation::PresentationThemeColor::OnSurfaceVariant | crate::skirout::base::editor::v1::presentation::PresentationThemeColor::FocusOutline)
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationAmbientColor {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::presentation::PresentationAmbientColor::Background | crate::skirout::base::editor::v1::presentation::PresentationAmbientColor::Foreground | crate::skirout::base::editor::v1::presentation::PresentationAmbientColor::SecondaryForeground)
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationContrastMode {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::presentation::PresentationContrastMode::Tonal | crate::skirout::base::editor::v1::presentation::PresentationContrastMode::Monochrome)
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationContrastColor {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationAlphaColor {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationBlendColor {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::PresentationStateColorRule
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationStateColor {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationColor {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::PresentationColor::Value(_)
                | crate::skirout::base::editor::v1::presentation::PresentationColor::Theme(_)
                | crate::skirout::base::editor::v1::presentation::PresentationColor::Ambient(_)
                | crate::skirout::base::editor::v1::presentation::PresentationColor::Contrast(_)
                | crate::skirout::base::editor::v1::presentation::PresentationColor::Alpha(_)
                | crate::skirout::base::editor::v1::presentation::PresentationColor::Blend(_)
                | crate::skirout::base::editor::v1::presentation::PresentationColor::States(_)
                | crate::skirout::base::editor::v1::presentation::PresentationColor::Adjusted(_)
                | crate::skirout::base::editor::v1::presentation::PresentationColor::Brightness(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::AlignmentLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ControlDensity {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::ControlDensity::Comfortable
                | crate::skirout::base::editor::v1::presentation::ControlDensity::Compact
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::InputTextAlignment {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::InputTextAlignment::Start
                | crate::skirout::base::editor::v1::presentation::InputTextAlignment::Center
                | crate::skirout::base::editor::v1::presentation::InputTextAlignment::End
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::InputTextStyle {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::BorderOverride {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::BorderOverride::None
                | crate::skirout::base::editor::v1::presentation::BorderOverride::Value(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::InputAdornment {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::InputAdornment::Default
                | crate::skirout::base::editor::v1::presentation::InputAdornment::None
                | crate::skirout::base::editor::v1::presentation::InputAdornment::Content(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::InputAppearance {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::InputContent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::AppearanceDefaultsElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::TextEntryInteractionOptions
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::NumericSteppers {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::NumericSteppers::Hidden
                | crate::skirout::base::editor::v1::presentation::NumericSteppers::Inline
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::NumericInteractionOptions {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ExpressionMapping {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ValueMappings {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::MultipleTextLines {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TextLines {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::TextLines::Single
                | crate::skirout::base::editor::v1::presentation::TextLines::Multiple(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TextPurpose {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::TextPurpose::Plain
                | crate::skirout::base::editor::v1::presentation::TextPurpose::Email
                | crate::skirout::base::editor::v1::presentation::TextPurpose::Url
                | crate::skirout::base::editor::v1::presentation::TextPurpose::Password
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TextCapitalization {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::TextCapitalization::None
                | crate::skirout::base::editor::v1::presentation::TextCapitalization::Words
                | crate::skirout::base::editor::v1::presentation::TextCapitalization::Sentences
                | crate::skirout::base::editor::v1::presentation::TextCapitalization::Characters
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::CharacterFilter {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::CharacterFilter::Allow(_)
                | crate::skirout::base::editor::v1::presentation::CharacterFilter::Deny(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TextLengthPolicy {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TextEditingOptions {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::NumericControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TextControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PopupAppearance {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PopupSide {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::PopupSide::Automatic
                | crate::skirout::base::editor::v1::presentation::PopupSide::Above
                | crate::skirout::base::editor::v1::presentation::PopupSide::Below
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ChoicePresentation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::ChoicePresentation::Automatic
                | crate::skirout::base::editor::v1::presentation::ChoicePresentation::Dropdown
                | crate::skirout::base::editor::v1::presentation::ChoicePresentation::Segmented
                | crate::skirout::base::editor::v1::presentation::ChoicePresentation::Radio
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SelectInteractionOptions {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::EnumControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::DateTimePickerPresentation
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::DateTimePickerPresentation::Calendar
                | crate::skirout::base::editor::v1::presentation::DateTimePickerPresentation::Text
        )
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::DateTimeInteractionOptions
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::DurationInteractionOptions
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::DurationControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::ColorEditingRepresentation
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::ColorEditingRepresentation::Hex
                | crate::skirout::base::editor::v1::presentation::ColorEditingRepresentation::Rgb
                | crate::skirout::base::editor::v1::presentation::ColorEditingRepresentation::Hsl
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ColorPickerFormat {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::ColorPickerFormat::Hex
                | crate::skirout::base::editor::v1::presentation::ColorPickerFormat::Rgb
                | crate::skirout::base::editor::v1::presentation::ColorPickerFormat::Hsl
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ColorInteractionOptions {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::BytesEditingEncoding {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::BytesEditingEncoding::Hexadecimal
                | crate::skirout::base::editor::v1::presentation::BytesEditingEncoding::Base64
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::BytesInteractionOptions {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::BytesControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TogglePresentation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::TogglePresentation::Switch
                | crate::skirout::base::editor::v1::presentation::TogglePresentation::Checkbox
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TogglePosition {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::TogglePosition::Leading
                | crate::skirout::base::editor::v1::presentation::TogglePosition::Trailing
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ToggleInteractionOptions {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ToggleControl {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SliderValueDisplay {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::presentation::SliderValueDisplay::Hidden | crate::skirout::base::editor::v1::presentation::SliderValueDisplay::WhileInteracting | crate::skirout::base::editor::v1::presentation::SliderValueDisplay::Always)
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SliderOrientation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::SliderOrientation::Horizontal
                | crate::skirout::base::editor::v1::presentation::SliderOrientation::Vertical
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SliderInteraction {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::SliderInteraction::TapAndDrag
                | crate::skirout::base::editor::v1::presentation::SliderInteraction::DragOnly
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SliderInteractionOptions {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ButtonVariant {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::ButtonVariant::Filled
                | crate::skirout::base::editor::v1::presentation::ButtonVariant::Outlined
                | crate::skirout::base::editor::v1::presentation::ButtonVariant::Text
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ActionAppearance {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::CollectionAppearance {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::CollectionContent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ResourceGraphAppearance {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::ResourceTimelineAppearance
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ChoiceOptionAppearance {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ImageFit {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::ImageFit::Contain
                | crate::skirout::base::editor::v1::presentation::ImageFit::Cover
                | crate::skirout::base::editor::v1::presentation::ImageFit::Fill
                | crate::skirout::base::editor::v1::presentation::ImageFit::FitWidth
                | crate::skirout::base::editor::v1::presentation::ImageFit::FitHeight
                | crate::skirout::base::editor::v1::presentation::ImageFit::None
                | crate::skirout::base::editor::v1::presentation::ImageFit::ScaleDown
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ImageOptions {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::DisplayAppearance {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::ProgressAppearance {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TooltipAppearance {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::DividerAppearance {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::HostContextInput {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::HostContextInput::ActiveResource
                | crate::skirout::base::editor::v1::presentation::HostContextInput::SelectionCount
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationContextSource {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::PresentationContextSource::Caller
                | crate::skirout::base::editor::v1::presentation::PresentationContextSource::Host(
                    _
                )
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationContextInput {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationPartId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationPartElement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::GraphResourcesLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TimelineResourcesLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::GridResourcesLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TreeResourcesLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationNumber {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::PresentationNumber::Value(_)
                | crate::skirout::base::editor::v1::presentation::PresentationNumber::States(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationStateNumber {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::PresentationStateNumberRule
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationCurve {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::PresentationCurve::Linear
                | crate::skirout::base::editor::v1::presentation::PresentationCurve::EaseInOut
                | crate::skirout::base::editor::v1::presentation::PresentationCurve::EaseOut
                | crate::skirout::base::editor::v1::presentation::PresentationCurve::Emphasized
                | crate::skirout::base::editor::v1::presentation::PresentationCurve::ElasticOut(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationTransition {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::PresentationTransitionPolicy
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::PresentationStateTransitionRule
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationShadow {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PresentationAdjustedColor {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::presentation::PresentationBrightnessColor
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::StackChild {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::presentation::StackChild::Flow(_)
                | crate::skirout::base::editor::v1::presentation::StackChild::Positioned(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::PositionedStackChild {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::SizeLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::presentation::TransformLayout {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::EngineImplementationInputs {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationState {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::publication::PublicationState::Checking
                | crate::skirout::base::editor::v1::publication::PublicationState::Compiling
                | crate::skirout::base::editor::v1::publication::PublicationState::Activating
                | crate::skirout::base::editor::v1::publication::PublicationState::Complete
                | crate::skirout::base::editor::v1::publication::PublicationState::Blocked(_)
                | crate::skirout::base::editor::v1::publication::PublicationState::Interrupted
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationAttempt {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationReport {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationCandidateId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationViewId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationBaseline {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::publication::PublicationBaseline::Initial
                | crate::skirout::base::editor::v1::publication::PublicationBaseline::Selected(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::DiagnosticEvidence {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::publication::PublicationDiagnosticDetails
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationNotice {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::publication::PublicationNotice::Information(_)
                | crate::skirout::base::editor::v1::publication::PublicationNotice::Warning(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationBlocker {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationChange {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::publication::PublicationChange::RootAdded(_) | crate::skirout::base::editor::v1::publication::PublicationChange::RootUpdated(_) | crate::skirout::base::editor::v1::publication::PublicationChange::RootRemoved(_) | crate::skirout::base::editor::v1::publication::PublicationChange::RequirementsChanged)
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationDelta {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationBlockers {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationActivationPhase {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::publication::PublicationActivationPhase::Storing | crate::skirout::base::editor::v1::publication::PublicationActivationPhase::Activating)
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationPendingReview {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationFailure {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::publication::PublicationFailure::EvaluationInterrupted(_) | crate::skirout::base::editor::v1::publication::PublicationFailure::ImplementationUnavailable(_) | crate::skirout::base::editor::v1::publication::PublicationFailure::PublicationInterrupted(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationStatus_Empty {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationStatus_Current {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationStatus_Ready {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationStatus_Blocked {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationStatus_Checking {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::publication::PublicationStatus_Publishing
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::publication::PublicationStatus_Unavailable
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationStatus {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::publication::PublicationStatus::Empty(_)
                | crate::skirout::base::editor::v1::publication::PublicationStatus::Current(_)
                | crate::skirout::base::editor::v1::publication::PublicationStatus::Ready(_)
                | crate::skirout::base::editor::v1::publication::PublicationStatus::Blocked(_)
                | crate::skirout::base::editor::v1::publication::PublicationStatus::Checking(_)
                | crate::skirout::base::editor::v1::publication::PublicationStatus::Publishing(_)
                | crate::skirout::base::editor::v1::publication::PublicationStatus::Unavailable(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationView {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublicationViewChanged {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublishAuthoringRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::publication::PublishAuthoringResponse_Activated
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::PublishAuthoringResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::Publishing | crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::Activated(_) | crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::BlockedError(_) | crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::InterruptedError(_) | crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::NoChanges | crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::CandidateChangedError(_) | crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::WatchPublicationRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::publication::WatchPublicationResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::publication::WatchPublicationResponse::ViewChanged(_) | crate::skirout::base::editor::v1::publication::WatchPublicationResponse::InternalError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::publication::QueryPublicationViewRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::publication::QueryPublicationViewResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::publication::QueryPublicationViewResponse::View(_) | crate::skirout::base::editor::v1::publication::QueryPublicationViewResponse::ViewChangedError(_) | crate::skirout::base::editor::v1::publication::QueryPublicationViewResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::resource_operations::OperationOrigin {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::OperationInvocation
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::OperationResourceUpsert
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::OperationWorkingOverlay
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::OperationWorkingContext
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::PreparationChoiceId
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::PreparationSourceOption
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::PreparationCounterpartOption
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::PreparationChoice_Source
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::PreparationChoice_Counterpart
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::resource_operations::PreparationChoice {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::resource_operations::PreparationChoice::Source(_) | crate::skirout::base::editor::v1::resource_operations::PreparationChoice::Counterpart(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::PreparationChoiceAnswer_Source
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::PreparationChoiceAnswer_Counterpart
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::PreparationChoiceAnswer
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::resource_operations::PreparationChoiceAnswer::Source(_) | crate::skirout::base::editor::v1::resource_operations::PreparationChoiceAnswer::Counterpart(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::OperationInputProblem
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::OperationSelectionEffect
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::resource_operations::OperationSelectionEffect::Unchanged | crate::skirout::base::editor::v1::resource_operations::OperationSelectionEffect::Replace(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::StaleAuthoringObservation
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::ResourceOperationFailure
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::Resolved(_) | crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::StaleObservationError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::InvalidError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::CatalogChangedError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::PermissionDeniedError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::FailedError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::InternalError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::PrepareAuthoringActionRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::AuthoringActionNeedsInput
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::AuthoringActionPreview
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::NeedsInput(_) | crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::Preview(_) | crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::StaleObservationError(_) | crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::InvalidError(_) | crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::UnavailableError(_) | crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::CatalogChangedError(_) | crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::PermissionDeniedError(_) | crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::FailedError(_) | crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::InternalError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::OperationSearchContext
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::resource_operations::DropCandidates {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::Resolved(_) | crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::StaleObservationError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::InvalidError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::CatalogChangedError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::PermissionDeniedError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::FailedError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::search::RealmSearchSelector {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::search::RealmSearchSelectorOperator {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::search::RealmSearchSelectorOperator::And
                | crate::skirout::base::editor::v1::search::RealmSearchSelectorOperator::Or
        )
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::search::RealmSearchSelectorBinaryExpression
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::search::RealmSearchSelectorNotExpression
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::search::RealmSearchSelectorExpression {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::search::RealmSearchSelectorExpression::Selector(_)
                | crate::skirout::base::editor::v1::search::RealmSearchSelectorExpression::Binary(
                    _
                )
                | crate::skirout::base::editor::v1::search::RealmSearchSelectorExpression::Not(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::search::RealmSearchQuery {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::search::RealmPresentationSearchRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::search::RealmPresentationSearchStatus {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::search::RealmPresentationSearchStatus::Loading | crate::skirout::base::editor::v1::search::RealmPresentationSearchStatus::Ready | crate::skirout::base::editor::v1::search::RealmPresentationSearchStatus::SearchFailedError)
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::search::RealmPresentationSearchSnapshot {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::search::RealmPresentationSearchUnavailable
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate_StaleObservationError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate::Snapshot(_) | crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate::UnavailableError(_) | crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate::StaleObservationError(_) | crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate::InternalError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::search::CancelRealmPresentationSearchRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::search::CancelRealmPresentationSearchResult
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::search::CancelRealmPresentationSearchResult::Canceled | crate::skirout::base::editor::v1::search::CancelRealmPresentationSearchResult::NotFoundError | crate::skirout::base::editor::v1::search::CancelRealmPresentationSearchResult::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::DeclaredTypeId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::QualifiedTypeId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::TypeId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::type_catalog::TypeId::Declared(_)
                | crate::skirout::base::editor::v1::type_catalog::TypeId::Qualified(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::TypeDefinitionId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ParameterKey {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::IntegerWidth {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::type_catalog::IntegerWidth::SignedEight
                | crate::skirout::base::editor::v1::type_catalog::IntegerWidth::SignedSixteen
                | crate::skirout::base::editor::v1::type_catalog::IntegerWidth::SignedThirtyTwo
                | crate::skirout::base::editor::v1::type_catalog::IntegerWidth::SignedSixtyFour
                | crate::skirout::base::editor::v1::type_catalog::IntegerWidth::UnsignedEight
                | crate::skirout::base::editor::v1::type_catalog::IntegerWidth::UnsignedSixteen
                | crate::skirout::base::editor::v1::type_catalog::IntegerWidth::UnsignedThirtyTwo
                | crate::skirout::base::editor::v1::type_catalog::IntegerWidth::UnsignedSixtyFour
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::FloatWidth {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::type_catalog::FloatWidth::ThirtyTwo
                | crate::skirout::base::editor::v1::type_catalog::FloatWidth::SixtyFour
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::IntegerScalar {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::FloatScalar {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ScalarKind {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::type_catalog::ScalarKind::Unit
                | crate::skirout::base::editor::v1::type_catalog::ScalarKind::Boolean
                | crate::skirout::base::editor::v1::type_catalog::ScalarKind::Text
                | crate::skirout::base::editor::v1::type_catalog::ScalarKind::Bytes
                | crate::skirout::base::editor::v1::type_catalog::ScalarKind::Integer(_)
                | crate::skirout::base::editor::v1::type_catalog::ScalarKind::Float(_)
                | crate::skirout::base::editor::v1::type_catalog::ScalarKind::Decimal
                | crate::skirout::base::editor::v1::type_catalog::ScalarKind::Timestamp
                | crate::skirout::base::editor::v1::type_catalog::ScalarKind::Duration
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::NamedTypeTemplate {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::NullableTypeTemplate {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::TypeTemplate {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::type_catalog::TypeTemplate::Parameter(_)
                | crate::skirout::base::editor::v1::type_catalog::TypeTemplate::Named(_)
                | crate::skirout::base::editor::v1::type_catalog::TypeTemplate::Nullable(_)
                | crate::skirout::base::editor::v1::type_catalog::TypeTemplate::Scalar(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::NamedTypeUse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::NullableTypeUse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::TypeUse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::type_catalog::TypeUse::Named(_)
                | crate::skirout::base::editor::v1::type_catalog::TypeUse::Nullable(_)
                | crate::skirout::base::editor::v1::type_catalog::TypeUse::Scalar(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::TypeParameter {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::FieldOwner {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::FieldDeclaration {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::CollectionKind {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::type_catalog::CollectionKind::List
                | crate::skirout::base::editor::v1::type_catalog::CollectionKind::Set
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::EnumVariant {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::type_catalog::ScalarRepresentationTemplate
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::type_catalog::RecordRepresentationTemplate
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::type_catalog::SequenceRepresentationTemplate
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::type_catalog::MappingRepresentationTemplate
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::type_catalog::EnumerationRepresentationTemplate
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::EndpointId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::type_catalog::LinkRepresentationTemplate
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::RepresentationTemplate {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::type_catalog::RepresentationTemplate::Scalar(_) | crate::skirout::base::editor::v1::type_catalog::RepresentationTemplate::Record(_) | crate::skirout::base::editor::v1::type_catalog::RepresentationTemplate::Sequence(_) | crate::skirout::base::editor::v1::type_catalog::RepresentationTemplate::Mapping(_) | crate::skirout::base::editor::v1::type_catalog::RepresentationTemplate::Enumeration(_) | crate::skirout::base::editor::v1::type_catalog::RepresentationTemplate::Link(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::TypeDefinition {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ResourceId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ItemId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::LinkTarget {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::LinkValue {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::FieldValue {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::RecordPayload {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::NamedValue {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ListItem {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ListPayload {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::MapRow {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::MapPayload {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::DurationValue {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::DataValue {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::type_catalog::DataValue::Unfilled
                | crate::skirout::base::editor::v1::type_catalog::DataValue::Null
                | crate::skirout::base::editor::v1::type_catalog::DataValue::Unit
                | crate::skirout::base::editor::v1::type_catalog::DataValue::Boolean(_)
                | crate::skirout::base::editor::v1::type_catalog::DataValue::Integer(_)
                | crate::skirout::base::editor::v1::type_catalog::DataValue::Float(_)
                | crate::skirout::base::editor::v1::type_catalog::DataValue::Decimal(_)
                | crate::skirout::base::editor::v1::type_catalog::DataValue::StringValue(_)
                | crate::skirout::base::editor::v1::type_catalog::DataValue::Bytes(_)
                | crate::skirout::base::editor::v1::type_catalog::DataValue::Timestamp(_)
                | crate::skirout::base::editor::v1::type_catalog::DataValue::Duration(_)
                | crate::skirout::base::editor::v1::type_catalog::DataValue::EnumCase(_)
                | crate::skirout::base::editor::v1::type_catalog::DataValue::Record(_)
                | crate::skirout::base::editor::v1::type_catalog::DataValue::Named(_)
                | crate::skirout::base::editor::v1::type_catalog::DataValue::ListValue(_)
                | crate::skirout::base::editor::v1::type_catalog::DataValue::SetValue(_)
                | crate::skirout::base::editor::v1::type_catalog::DataValue::MapValue(_)
                | crate::skirout::base::editor::v1::type_catalog::DataValue::Link(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ArgumentSelection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::type_catalog::ArgumentSelection::Chosen(_)
                | crate::skirout::base::editor::v1::type_catalog::ArgumentSelection::Unfilled
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::PendingTypeSelection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::TypeSelection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::type_catalog::TypeSelection::Complete(_)
                | crate::skirout::base::editor::v1::type_catalog::TypeSelection::Pending(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::AuthoringRecord {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::PresentationId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ConversionId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::CapabilityId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::CatalogGeneration {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::InputToken {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ExpressionBindingId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::RuleOrigin {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::RuleId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ValuePath {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::FieldPathSegment {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ItemPathSegment {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::PathSegment {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::type_catalog::PathSegment::Field(_)
                | crate::skirout::base::editor::v1::type_catalog::PathSegment::Item(_)
                | crate::skirout::base::editor::v1::type_catalog::PathSegment::MapKey
                | crate::skirout::base::editor::v1::type_catalog::PathSegment::MapValue
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ValueLocation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::NamedFieldPatternSegment {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::FieldPatternSegment {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::type_catalog::FieldPatternSegment::Field(_)
                | crate::skirout::base::editor::v1::type_catalog::FieldPatternSegment::Items
                | crate::skirout::base::editor::v1::type_catalog::FieldPatternSegment::Keys
                | crate::skirout::base::editor::v1::type_catalog::FieldPatternSegment::Values
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::RelativeFieldPattern {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::NativeBindingId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::CheckExecutionId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::DiagnosticId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::SelectionId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::PublicationId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::CanonicalValueHash {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::RelationId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::RelationFamilyId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::type_catalog::ScalarResolvedRepresentation
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::type_catalog::RecordResolvedRepresentation
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::type_catalog::SequenceResolvedRepresentation
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::type_catalog::MappingResolvedRepresentation
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::type_catalog::EnumerationResolvedRepresentation
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::editor::v1::type_catalog::LinkResolvedRepresentation
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ResolvedRepresentation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::editor::v1::type_catalog::ResolvedRepresentation::Scalar(_) | crate::skirout::base::editor::v1::type_catalog::ResolvedRepresentation::Record(_) | crate::skirout::base::editor::v1::type_catalog::ResolvedRepresentation::Sequence(_) | crate::skirout::base::editor::v1::type_catalog::ResolvedRepresentation::Mapping(_) | crate::skirout::base::editor::v1::type_catalog::ResolvedRepresentation::Enumeration(_) | crate::skirout::base::editor::v1::type_catalog::ResolvedRepresentation::Link(_))
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ResolvedField {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::AppliedSchema {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::CheckedType {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ArgumentLocation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::DependentField {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::PartialSchema {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ContributionSourceId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ProducerId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ContributionName {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ContributionKey {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::DeclarationOwner {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::type_catalog::ResourceTarget {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::editor::v1::type_catalog::ResourceTarget::Type(_)
                | crate::skirout::base::editor::v1::type_catalog::ResourceTarget::AnyResource
        )
    }
}
impl crate::SkirType for crate::skirout::base::editor::v1::typed_value::PortableValue {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::kernel::v1::color::Color {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::kernel::v1::duration::Duration {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::kernel::v1::errors::InternalError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::kernel::v1::errors::InvalidRecordIdError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::kernel::v1::icon::Icon {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::kernel::v1::icon::Icon::Iconify(_)
                | crate::skirout::base::kernel::v1::icon::Icon::Svg(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::kernel::v1::record_id::RecordId {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::kernel::v1::record_id::RecordIdKey {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::kernel::v1::record_id::RecordIdKey::Number(_)
                | crate::skirout::base::kernel::v1::record_id::RecordIdKey::String(_)
                | crate::skirout::base::kernel::v1::record_id::RecordIdKey::Uuid(_)
                | crate::skirout::base::kernel::v1::record_id::RecordIdKey::Array(_)
                | crate::skirout::base::kernel::v1::record_id::RecordIdKey::Object(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::kernel::v1::record_id::ObjectRecordIdKey {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::kernel::v1::record_id::RecordIdValue {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::kernel::v1::record_id::RecordIdValue::Null
                | crate::skirout::base::kernel::v1::record_id::RecordIdValue::Boolean(_)
                | crate::skirout::base::kernel::v1::record_id::RecordIdValue::Number(_)
                | crate::skirout::base::kernel::v1::record_id::RecordIdValue::Float(_)
                | crate::skirout::base::kernel::v1::record_id::RecordIdValue::String(_)
                | crate::skirout::base::kernel::v1::record_id::RecordIdValue::Array(_)
                | crate::skirout::base::kernel::v1::record_id::RecordIdValue::Object(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::kernel::v1::record_id::ObjectRecordIdValue {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_codes::JoinCode_AutoAccept {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_codes::JoinCode {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_codes::OrganizationJoinCodesSnapshot
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_codes::OrganizationJoinCodesChange
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::join_codes::OrganizationJoinCodesChange::Add(_) | crate::skirout::base::organization::v1::join_codes::OrganizationJoinCodesChange::Remove(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_codes::OrganizationJoinCodesChanged
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesResponse::InternalError(_) | crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesResponse::Snapshot(_) | crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesResponse::Changed(_))
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeRequest_Expiration {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeRequest_Expiration::Never | crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeRequest_Expiration::Duration(_))
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeRequest_AutoAccept {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse_Success {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse_RolesNotFoundError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse_RolesNotAssignableError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse_InvalidExpirationError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::InternalError(_) | crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::Success(_) | crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::RolesNotFoundError(_) | crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::RolesNotAssignableError(_) | crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::InvalidExpirationError(_) | crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::InvalidRecordIdError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse_Success {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse_CodeNotFoundError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::InternalError(_) | crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::Success(_) | crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::CodeNotFoundError(_) | crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::InvalidRecordIdError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_request::OrganizationJoinRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_request::UserJoinRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_request::OrganizationJoinRequestsSnapshot
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_request::OrganizationJoinRequestsChange
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::join_request::OrganizationJoinRequestsChange::Add(_) | crate::skirout::base::organization::v1::join_request::OrganizationJoinRequestsChange::Remove(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_request::OrganizationJoinRequestsChanged
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_request::UserJoinRequestsSnapshot
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_request::UserJoinRequestsChange
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::join_request::UserJoinRequestsChange::Add(_) | crate::skirout::base::organization::v1::join_request::UserJoinRequestsChange::Remove(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_request::UserJoinRequestsChanged
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_request::AutoAcceptedMember {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsResponse::InternalError(_) | crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsResponse::Snapshot(_) | crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsResponse::Changed(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_request::ApprovedOrganizationJoinRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse_Success {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse_RequestNotFoundError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse_RolesNotFoundError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse_RolesNotAssignableError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse_RolesRequiredError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse_UserAlreadyMemberError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse_InvalidSelectionError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::InternalError(_) | crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::Success(_) | crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RequestNotFoundError(_) | crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RolesNotFoundError(_) | crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RolesNotAssignableError(_) | crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RolesRequiredError(_) | crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::UserAlreadyMemberError(_) | crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::InvalidSelectionError(_) | crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::InvalidRecordIdError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse_Success {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse_RequestNotFoundError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::InternalError(_) | crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::Success(_) | crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::RequestNotFoundError(_) | crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::InvalidRecordIdError(_))
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::member::OrganizationMember {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::member::OrganizationMembersSnapshot
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::member::OrganizationMembersChange {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::organization::v1::member::OrganizationMembersChange::Add(_)
                | crate::skirout::base::organization::v1::member::OrganizationMembersChange::Update(
                    _
                )
                | crate::skirout::base::organization::v1::member::OrganizationMembersChange::Remove(
                    _
                )
        )
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::member::OrganizationMembersChanged
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::member::WatchOrganizationMembersRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::member::WatchOrganizationMembersResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::member::WatchOrganizationMembersResponse::InternalError(_) | crate::skirout::base::organization::v1::member::WatchOrganizationMembersResponse::Snapshot(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse_Success {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse_UserNotFoundError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse_RolesNotFoundError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse_RolesNotAssignableError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse_RolesRequiredError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse_FounderRoleRequiredError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse_InvalidSelectionError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::InternalError(_) | crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::Success(_) | crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::UserNotFoundError(_) | crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::RolesNotFoundError(_) | crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::RolesNotAssignableError(_) | crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::RolesRequiredError(_) | crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::FounderRoleRequiredError(_) | crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::InvalidSelectionError(_) | crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::InvalidRecordIdError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::member::RemoveOrganizationMemberRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse_Success
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse_UserNotMemberError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse_FounderCannotBeRemovedError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::InternalError(_) | crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::Success(_) | crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::UserNotMemberError(_) | crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::FounderCannotBeRemovedError(_) | crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::InvalidRecordIdError(_))
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::organization::Organization {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::organization::UserOrganizationsSnapshot
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::organization::UserOrganizationsChange
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::organization::UserOrganizationsChange::Add(_) | crate::skirout::base::organization::v1::organization::UserOrganizationsChange::Remove(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::organization::UserOrganizationsChanged
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::organization::CreateOrganizationRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::organization::CreateOrganizationResponse_Success
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::organization::CreateOrganizationResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::organization::CreateOrganizationResponse::InternalError(_) | crate::skirout::base::organization::v1::organization::CreateOrganizationResponse::Success(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::organization::DeleteOrganizationRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::organization::DeleteOrganizationResponse_Success
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::organization::DeleteOrganizationResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::organization::DeleteOrganizationResponse::InternalError(_) | crate::skirout::base::organization::v1::organization::DeleteOrganizationResponse::Success(_) | crate::skirout::base::organization::v1::organization::DeleteOrganizationResponse::InvalidRecordIdError(_))
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::presence::OrganizationPresence {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::presence::MembersPresence {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::presence::ServicesPresence {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::presence::ServicePresence {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::presence::RealmsPresence {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::presence::RealmPresence {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::presence::ResourcePresence {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::presence::PresenceLocation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::organization::v1::presence::PresenceLocation::Organization(_)
                | crate::skirout::base::organization::v1::presence::PresenceLocation::Members(_)
                | crate::skirout::base::organization::v1::presence::PresenceLocation::Services(_)
                | crate::skirout::base::organization::v1::presence::PresenceLocation::Service(_)
                | crate::skirout::base::organization::v1::presence::PresenceLocation::Realms(_)
                | crate::skirout::base::organization::v1::presence::PresenceLocation::Realm(_)
                | crate::skirout::base::organization::v1::presence::PresenceLocation::Resource(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::presence::PanelPresence {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::presence::PresenceLeft {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::presence::PresenceEvent {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::organization::v1::presence::PresenceEvent::Active(_)
                | crate::skirout::base::organization::v1::presence::PresenceEvent::Left(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::role::OrganizationRole {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::role::WatchOrganizationRolesRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse::InternalError(_) | crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse::List(_) | crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse::Add(_) | crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse::Update(_) | crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse::Remove(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::user::WatchUserOrganizationsRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::user::WatchUserOrganizationsResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::user::WatchUserOrganizationsResponse::InternalError(_) | crate::skirout::base::organization::v1::user::WatchUserOrganizationsResponse::Snapshot(_) | crate::skirout::base::organization::v1::user::WatchUserOrganizationsResponse::Changed(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::user::WatchUserJoinRequestsRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::user::WatchUserJoinRequestsResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::user::WatchUserJoinRequestsResponse::InternalError(_) | crate::skirout::base::organization::v1::user::WatchUserJoinRequestsResponse::Snapshot(_) | crate::skirout::base::organization::v1::user::WatchUserJoinRequestsResponse::Changed(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::user::SubmitUserJoinRequestRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse_RequestMade
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse_AutoAccepted
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse_CodeNotFoundError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse_AlreadyMemberError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse_NoAssignableRolesError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse_MaxPendingRequestsError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse_PendingRequestExistsError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::InternalError(_) | crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::RequestMade(_) | crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::AutoAccepted(_) | crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::CodeNotFoundError(_) | crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::AlreadyMemberError(_) | crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::NoAssignableRolesError(_) | crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::MaxPendingRequestsError(_) | crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::PendingRequestExistsError(_) | crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::InvalidRecordIdError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::user::CancelUserJoinRequestRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse_Success
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse_RequestNotFoundError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::InternalError(_) | crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::Success(_) | crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::RequestNotFoundError(_) | crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::InvalidRecordIdError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::artifact::ArtifactDigest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::artifact::DigestAlgorithm {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::service::v1::artifact::DigestAlgorithm::Sha256
        )
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::artifact::BlobMetadata {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::artifact::BlobChunk {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::artifact::SharedArtifactDescriptor {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::SharedArtifactProvenance_LocalInbox
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::SharedArtifactProvenance_Panel
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::SharedArtifactProvenance_Service
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::artifact::SharedArtifactProvenance {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::service::v1::artifact::SharedArtifactProvenance::LocalInbox(_)
                | crate::skirout::base::service::v1::artifact::SharedArtifactProvenance::Panel(_)
                | crate::skirout::base::service::v1::artifact::SharedArtifactProvenance::Service(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::artifact::SharedArtifactCatalog {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::artifact::ProducerMetadataEntry {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::artifact::ProducerMetadata {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::FetchSharedArtifactCatalogRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::FetchSharedArtifactCatalogResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::artifact::FetchSharedArtifactCatalogResponse::Success(_) | crate::skirout::base::service::v1::artifact::FetchSharedArtifactCatalogResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::artifact::PublishSharedArtifactRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::PublishSharedArtifactResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::artifact::PublishSharedArtifactResponse::Published(_) | crate::skirout::base::service::v1::artifact::PublishSharedArtifactResponse::Unchanged(_) | crate::skirout::base::service::v1::artifact::PublishSharedArtifactResponse::ConflictError(_) | crate::skirout::base::service::v1::artifact::PublishSharedArtifactResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::artifact::ReadArtifactBlobRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse_NotFoundError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse_InvalidError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse::Success(_) | crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse::NotFoundError(_) | crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse::InvalidError(_) | crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse::InternalError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse_Accepted
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse_InvalidError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse_ConflictError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse::Accepted(_) | crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse::InvalidError(_) | crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse::ConflictError(_) | crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse::InternalError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse_Accepted
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse_NotFoundError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse_InvalidError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse_ConflictError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::Accepted(_) | crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::NotFoundError(_) | crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::InvalidError(_) | crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::ConflictError(_) | crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::InternalError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse_NotFoundError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse_InvalidError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse_ConflictError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::Success(_) | crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::NotFoundError(_) | crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::InvalidError(_) | crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::ConflictError(_) | crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::InternalError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse_NotFoundError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse_InvalidError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse::Success(_) | crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse::NotFoundError(_) | crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse::InvalidError(_) | crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::identity::IssueServiceIdentityRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse_Success
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse_MalformedRequestError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse_UnknownRoleError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse_RoleUnknownPropertyError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse_RoleTypeInvalidError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse_RoleVersionInvalidError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse_CustomRoleNameRequiredError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse_CustomRoleNameInvalidError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse_BuiltinRoleNameForbiddenError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse_IdentityProviderUnavailableError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::InternalError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::Success(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::MalformedRequestError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::UnknownRoleError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::RoleUnknownPropertyError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::RoleTypeInvalidError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::RoleVersionInvalidError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::CustomRoleNameRequiredError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::CustomRoleNameInvalidError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::BuiltinRoleNameForbiddenError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::IdentityProviderUnavailableError(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::lifecycle::ServiceHeartbeatNotification
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::lifecycle::ServiceShutdownNotification {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::organization::ServiceUpdateValidationError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::organization::ServiceUpdateValidationError::NameInvalid)
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::organization::OrganizationServicesChanged
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::organization::OrganizationServicesChanged::Replace(_) | crate::skirout::base::service::v1::organization::OrganizationServicesChanged::Update(_) | crate::skirout::base::service::v1::organization::OrganizationServicesChanged::Remove(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::organization::WatchOrganizationServicesRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::organization::WatchOrganizationServicesResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::organization::WatchOrganizationServicesResponse::InternalError(_) | crate::skirout::base::service::v1::organization::WatchOrganizationServicesResponse::List(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::organization::UpdateOrganizationServiceRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse_ConflictError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse_ServiceNotFoundError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::InternalError(_) | crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::Success(_) | crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::ConflictError(_) | crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::ServiceNotFoundError(_) | crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::ValidationError(_) | crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::InvalidRecordIdError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::registration::BindServiceRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::registration::BindServiceResponse_Success
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::registration::BindServiceResponse_InvalidRegistrationTokenError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::registration::BindServiceResponse_OrganizationNotFoundError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::registration::BindServiceResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::registration::BindServiceResponse::InternalError(_) | crate::skirout::base::service::v1::registration::BindServiceResponse::Success(_) | crate::skirout::base::service::v1::registration::BindServiceResponse::InvalidRegistrationTokenError(_) | crate::skirout::base::service::v1::registration::BindServiceResponse::OrganizationNotFoundError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::registration::ServiceBoundNotification {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::registration::UnbindServiceRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::registration::UnbindServiceResponse_Success
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::registration::UnbindServiceResponse_ServiceNotFoundError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::registration::UnbindServiceResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::registration::UnbindServiceResponse::InternalError(_) | crate::skirout::base::service::v1::registration::UnbindServiceResponse::Success(_) | crate::skirout::base::service::v1::registration::UnbindServiceResponse::ServiceNotFoundError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::RuntimePlacement {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::service::v1::rollout::RuntimePlacement::Realm
                | crate::skirout::base::service::v1::rollout::RuntimePlacement::PanelEngine
                | crate::skirout::base::service::v1::rollout::RuntimePlacement::PrimaryEngine
        )
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::RuntimeVersion {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ProjectionReference {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ProjectionHealth_Unhealthy {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ProjectionHealth {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::service::v1::rollout::ProjectionHealth::Staged
                | crate::skirout::base::service::v1::rollout::ProjectionHealth::Healthy
                | crate::skirout::base::service::v1::rollout::ProjectionHealth::Unhealthy(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ActiveProjection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::RealmHostPresence {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::RolloutAttempt {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::RollbackTarget {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::service::v1::rollout::RollbackTarget::Empty
                | crate::skirout::base::service::v1::rollout::RollbackTarget::Projection(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ParticipantProjection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ParticipantProjections {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ParticipantRollback {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ParticipantRollbacks {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::RolloutCommand {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::service::v1::rollout::RolloutCommand::Stage(_)
                | crate::skirout::base::service::v1::rollout::RolloutCommand::Commit(_)
                | crate::skirout::base::service::v1::rollout::RolloutCommand::Abort(_)
                | crate::skirout::base::service::v1::rollout::RolloutCommand::RollBack(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::RolloutCommandKind {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::service::v1::rollout::RolloutCommandKind::Stage
                | crate::skirout::base::service::v1::rollout::RolloutCommandKind::Commit
                | crate::skirout::base::service::v1::rollout::RolloutCommandKind::Abort
                | crate::skirout::base::service::v1::rollout::RolloutCommandKind::RollBack
        )
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::StagedCandidate {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ActiveParticipant {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::RecoverableParticipantState {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::service::v1::rollout::RecoverableParticipantState::Empty
                | crate::skirout::base::service::v1::rollout::RecoverableParticipantState::Active(
                    _
                )
                | crate::skirout::base::service::v1::rollout::RecoverableParticipantState::Staged(
                    _
                )
        )
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ParticipantPhase_RollingBack {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ParticipantPhase_Failed {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ParticipantPhase {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::service::v1::rollout::ParticipantPhase::Idle
                | crate::skirout::base::service::v1::rollout::ParticipantPhase::Staging(_)
                | crate::skirout::base::service::v1::rollout::ParticipantPhase::Staged(_)
                | crate::skirout::base::service::v1::rollout::ParticipantPhase::Committing(_)
                | crate::skirout::base::service::v1::rollout::ParticipantPhase::Active(_)
                | crate::skirout::base::service::v1::rollout::ParticipantPhase::Aborting(_)
                | crate::skirout::base::service::v1::rollout::ParticipantPhase::RollingBack(_)
                | crate::skirout::base::service::v1::rollout::ParticipantPhase::Failed(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ParticipantStatus {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ProbeRealmHostsRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ProbeRealmHostsResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::rollout::ProbeRealmHostsResponse::Present(_) | crate::skirout::base::service::v1::rollout::ProbeRealmHostsResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ApplyRolloutCommandRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse_Accepted
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse_StaleAttemptError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse_AttemptConflictError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse_CommandRejectedError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse_CommandFailedError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::Accepted(_) | crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::StaleAttemptError(_) | crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::AttemptConflictError(_) | crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::CommandRejectedError(_) | crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::CommandFailedError(_) | crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::rollout::QueryParticipantStatusRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::rollout::QueryParticipantStatusResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::rollout::QueryParticipantStatusResponse::Status(_) | crate::skirout::base::service::v1::rollout::QueryParticipantStatusResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::service::Service {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::service::ServiceRole_Host {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::service::ServiceRole_Custom {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::service::ServiceRole {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::service::v1::service::ServiceRole::Host(_)
                | crate::skirout::base::service::v1::service::ServiceRole::Custom(_)
        )
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::service::ServiceStatus {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::service::v1::service::ServiceStatus::Online
                | crate::skirout::base::service::v1::service::ServiceStatus::Offline
        )
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::service::ServiceState {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::service::ServiceRegistration {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::status::ServiceBinding_Bound {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::status::ServiceBinding {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::service::v1::status::ServiceBinding::Bound(_)
                | crate::skirout::base::service::v1::status::ServiceBinding::Unbound
        )
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::status::RegistrationLease {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::status::QueryServiceBindingRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::status::QueryServiceBindingResponse_Binding
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::status::QueryServiceBindingResponse_ServiceNotFoundError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::status::QueryServiceBindingResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::status::QueryServiceBindingResponse::Binding(_) | crate::skirout::base::service::v1::status::QueryServiceBindingResponse::ServiceNotFoundError(_) | crate::skirout::base::service::v1::status::QueryServiceBindingResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::status::EnsureRegistrationLeaseRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse_AlreadyBound
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse_ServiceNotFoundError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse::Issued(_) | crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse::AlreadyBound(_) | crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse::ServiceNotFoundError(_) | crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::ReconciledRevision {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::EngineTarget {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::SupportedEngine {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::HostRuntimeStatus {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::service::v1::topology::HostRuntimeStatus::Offline
                | crate::skirout::base::service::v1::topology::HostRuntimeStatus::Reconciling
                | crate::skirout::base::service::v1::topology::HostRuntimeStatus::Active
                | crate::skirout::base::service::v1::topology::HostRuntimeStatus::Failed
                | crate::skirout::base::service::v1::topology::HostRuntimeStatus::Drifted
        )
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::HostRuntimeState {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::ChildRuntimeStatus {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::service::v1::topology::ChildRuntimeStatus::Absent
                | crate::skirout::base::service::v1::topology::ChildRuntimeStatus::Staging
                | crate::skirout::base::service::v1::topology::ChildRuntimeStatus::Active
                | crate::skirout::base::service::v1::topology::ChildRuntimeStatus::Quiescing
                | crate::skirout::base::service::v1::topology::ChildRuntimeStatus::Failed
                | crate::skirout::base::service::v1::topology::ChildRuntimeStatus::RolledBack
                | crate::skirout::base::service::v1::topology::ChildRuntimeStatus::Drifted
        )
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::ChildRuntimeState {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::ServiceHost {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::OwnerHost {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::RealmInstance {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::RealmInfo {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::EngineInstance {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::HostedRealmConfiguration {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::topology::EngineRealmSelection_ExistingRealm
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::EngineRealmSelection {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(
            self,
            crate::skirout::base::service::v1::topology::EngineRealmSelection::HostedRealm
                | crate::skirout::base::service::v1::topology::EngineRealmSelection::ExistingRealm(
                    _
                )
        )
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::HostedEngineConfiguration {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::HostExecutionConfiguration {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::HostConfigurationChange {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::ConfigureServiceHostRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse_ConflictError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse_InvalidConfigurationError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse_IncompatibleEngineError {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse_RealmNotFoundError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::Success(_) | crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::ConflictError(_) | crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::InvalidConfigurationError(_) | crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::IncompatibleEngineError(_) | crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::RealmNotFoundError(_) | crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::InvalidRecordIdError(_) | crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::OrganizationTopologySnapshot {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::RealmRuntimeObservation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::EngineRuntimeObservation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::HostExecutionObservation {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::OrganizationTopologyChanged {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::topology::OrganizationTopologyChanged::Replace(_) | crate::skirout::base::service::v1::topology::OrganizationTopologyChanged::ConfigurationChanged(_) | crate::skirout::base::service::v1::topology::OrganizationTopologyChanged::ObservationsReported(_) | crate::skirout::base::service::v1::topology::OrganizationTopologyChanged::HostAdvertised(_))
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::topology::WatchOrganizationTopologyRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::topology::WatchOrganizationTopologyResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::topology::WatchOrganizationTopologyResponse::List(_) | crate::skirout::base::service::v1::topology::WatchOrganizationTopologyResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::WatchHostExecutionRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::topology::WatchHostExecutionResponse_Desired
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::WatchHostExecutionResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::topology::WatchHostExecutionResponse::Desired(_) | crate::skirout::base::service::v1::topology::WatchHostExecutionResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::ReportHostExecutionRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::topology::ReportHostExecutionResponse_Success
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::topology::ReportHostExecutionResponse_StaleRevisionError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::ReportHostExecutionResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::topology::ReportHostExecutionResponse::Success(_) | crate::skirout::base::service::v1::topology::ReportHostExecutionResponse::StaleRevisionError(_) | crate::skirout::base::service::v1::topology::ReportHostExecutionResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::ServiceMessagingScope {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::topology::GetServiceMessagingScopeRequest
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse_NotFoundError
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType
    for crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse
{
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse::Found(_) | crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse::NotFoundError(_) | crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse::InternalError(_))
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::RegisterServiceHostRequest {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}
impl crate::SkirType for crate::skirout::base::service::v1::topology::RegisterServiceHostResponse {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, crate::skirout::base::service::v1::topology::RegisterServiceHostResponse::Success(_) | crate::skirout::base::service::v1::topology::RegisterServiceHostResponse::InternalError(_))
    }
}
