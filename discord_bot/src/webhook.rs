use actix_web::{web::Bytes, HttpRequest, HttpResponse, Responder};
use hmac::{Hmac, Mac};
use log::{debug, info, warn};
use serde::{Deserialize, Serialize};
use sha2::Sha256;

use crate::clickup::move_done_to_beta;

type HmacSha256 = Hmac<Sha256>;

#[actix_web::get("/")]
pub async fn webhook_get() -> impl Responder {
    HttpResponse::Ok().body("ok")
}

#[actix_web::get("/publishbeta")]
pub async fn publish_beta_version(req: HttpRequest) -> impl Responder {
    let secret =
        std::env::var("GITHUB_WEBHOOK_SIGNATURE").expect("missing GITHUB_WEBHOOK_SIGNATURE");
    let headers = req.headers();
    let signature = headers
        .get("X-Signature")
        .expect("missing X-Signature header")
        .to_str()
        .expect("failed to convert X-Signature header to str")
        .trim();

    // Check if the signature is equal to the expected signature
    if signature != secret {
        return HttpResponse::Unauthorized().body("invalid signature");
    }

    info!("Received publish beta request");

    match move_done_to_beta().await {
        Ok(_) => HttpResponse::Ok().body("ok"),
        Err(e) => {
            warn!("failed to move tasks to beta: {}", e);
            HttpResponse::InternalServerError().body(format!("failed to move tasks to beta: {}", e))
        }
    }
}

#[actix_web::post("/")]
pub async fn clickup_webhook(req: HttpRequest, bytes: Bytes) -> impl Responder {
    let headers = req.headers();
    let signature = headers
        .get("X-Signature")
        .expect("missing X-Signature header")
        .to_str()
        .expect("failed to convert X-Signature header to str")
        .trim();

    let secret = std::env::var("CLICKUP_WEBHOOK_SECRET").expect("missing CLICKUP_WEBHOOK_SECRET");
    let mut mac =
        HmacSha256::new_from_slice(secret.as_bytes()).expect("HMAC can take key of any size");

    mac.update(&bytes);

    let new_signature = if signature.len() % 2 != 0 {
        format!("0{}", signature)
    } else {
        signature.to_string()
    };

    let Ok(signature) = hex::decode(new_signature.trim()) else {
        warn!("failed to decode signature");
        return HttpResponse::BadRequest()
            .body("failed to decode signature")
            .into();
    };
    if let Err(_) = mac.verify_slice(&signature) {
        warn!("invalid signature: {:?}", signature);
        return HttpResponse::Unauthorized()
            .body("invalid signature")
            .into();
    }

    let event: Event = serde_json::from_slice(&bytes).expect("failed to deserialize event");

    debug!("Received Event: {:?}", event);

    let result = match event {
        Event::TaskCreated(e) => crate::webhooks::handle_task_created(e).await,
        Event::TaskUpdated(e) => crate::webhooks::handle_task_updated(e).await,
        Event::TaskStatusUpdated(e) => crate::webhooks::handle_task_status_updated(e).await,
        _ => Ok(()),
    };

    if let Err(e) = result {
        warn!("failed to handle event: {}", e);
        return HttpResponse::InternalServerError()
            .body(format!("failed to handle event: {}", e))
            .into();
    }

    HttpResponse::Ok().finish()
}

#[derive(Debug, Deserialize)]
#[serde(tag = "event", rename_all = "camelCase")]
enum Event {
    TaskCreated(TaskCreated),
    TaskUpdated(TaskUpdated),
    TaskDeleted(TaskDeleted),
    TaskPriorityUpdated(TaskPriorityUpdated),
    TaskStatusUpdated(TaskStatusUpdated),
    TaskAssigneeUpdated(TaskAssigneeUpdated),
    TaskDueDateUpdated(TaskDueDateUpdated),
    TaskMoved(TaskMoved),
    TaskCommentCreated(TaskCommentCreated),
    TaskCommentPosted(TaskCommentPosted),
    TaskCommentUpdated(TaskCommentUpdated),
    TaskTimeEstimateUpdated(TaskTimeEstimateUpdated),
    TaskTimeTrackedUpdated(TaskTimeTrackedUpdated),
    TaskTagUpdated(TaskTagUpdated),
    ListCreated(ListCreated),
    ListUpdated(ListUpdated),
    ListDeleted(ListDeleted),
    FolderCreated(FolderCreated),
    FolderUpdated(FolderUpdated),
    FolderDeleted(FolderDeleted),
    SpaceCreated(SpaceCreated),
    SpaceUpdated(SpaceUpdated),
    SpaceDeleted(SpaceDeleted),
    GoalCreated(GoalCreated),
    GoalUpdated(GoalUpdated),
    GoalDeleted(GoalDeleted),
    KeyResultCreated(KeyResultCreated),
    KeyResultUpdated(KeyResultUpdated),
    KeyResultDeleted(KeyResultDeleted),
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct User {
    id: u32,
    username: String,
    email: String,
    color: String,
    initials: Option<String>,
    profile_picture: Option<String>,
}

#[derive(Debug, Deserialize)]
struct HistoryItem {
    id: String,
    #[serde(rename = "type")]
    type_: u32,
    date: String,
    field: String,
    parent_id: String,
    user: User,
    before: Option<BeforeAfter>,
    after: Option<BeforeAfter>,
}

#[derive(Debug, Deserialize)]
#[serde(untagged)]
enum BeforeAfter {
    Empty,
    String(String),
    TaskStatus {
        status: String,
        color: String,
        #[serde(rename = "type")]
        type_: String,
        orderindex: i32,
    },
    TaskPriority {
        id: String,
        priority: String,
        color: String,
        orderindex: String,
    },
    TaskAssignee(User),
    TaskTag(Vec<TaskTag>),
    TaskMoved {
        id: String,
        name: String,
        category: Category,
        project: Project,
    },
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TaskTag {
    pub name: String,
    tag_fg: String,
    tag_bg: String,
    creator: u32,
}

#[derive(Debug, Deserialize)]
pub struct Category {
    id: String,
    name: String,
    hidden: bool,
}

#[derive(Debug, Deserialize)]
pub struct Project {
    id: String,
    name: String,
}

#[derive(Debug, Deserialize)]
struct TaskCreatedHistoryItem {
    #[serde(flatten)]
    item: HistoryItem,
    data: StatusTypeData,
}

#[derive(Debug, Deserialize)]
struct StatusTypeData {
    status_type: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct TaskCreated {
    pub task_id: String,
    pub webhook_id: String,
}

#[derive(Debug, Deserialize)]
pub struct TaskUpdated {
    pub task_id: String,
    pub webhook_id: String,
}

#[derive(Debug, Deserialize)]
struct TaskDeleted {}

#[derive(Debug, Deserialize)]
struct TaskPriorityUpdated {}

#[derive(Debug, Deserialize)]
struct TaskStatusUpdatedHistoryItem {
    #[serde(flatten)]
    item: HistoryItem,
    data: StatusTypeData,
}

#[derive(Debug, Deserialize)]
pub struct TaskStatusUpdated {
    pub task_id: String,
    pub webhook_id: String,
}

#[derive(Debug, Deserialize)]
struct TaskAssigneeUpdated {}

#[derive(Debug, Deserialize)]
struct TaskDueDateUpdated {}

#[derive(Debug, Deserialize)]
struct TaskMoved {}

#[derive(Debug, Deserialize)]
struct TaskCommentCreated {}

#[derive(Debug, Deserialize)]
struct TaskCommentPosted {}

#[derive(Debug, Deserialize)]
struct TaskCommentUpdated {}

#[derive(Debug, Deserialize)]
struct TaskTimeEstimateUpdated {}

#[derive(Debug, Deserialize)]
struct TaskTimeTrackedUpdated {}

#[derive(Debug, Deserialize)]
struct TaskTagUpdated {}

#[derive(Debug, Deserialize)]
struct ListCreated {}

#[derive(Debug, Deserialize)]
struct ListUpdated {}

#[derive(Debug, Deserialize)]
struct ListDeleted {}

#[derive(Debug, Deserialize)]
struct FolderCreated {}

#[derive(Debug, Deserialize)]
struct FolderUpdated {}

#[derive(Debug, Deserialize)]
struct FolderDeleted {}

#[derive(Debug, Deserialize)]
struct SpaceCreated {}

#[derive(Debug, Deserialize)]
struct SpaceUpdated {}

#[derive(Debug, Deserialize)]
struct SpaceDeleted {}

#[derive(Debug, Deserialize)]
struct GoalCreated {}

#[derive(Debug, Deserialize)]
struct GoalUpdated {}

#[derive(Debug, Deserialize)]
struct GoalDeleted {}

#[derive(Debug, Deserialize)]
struct KeyResultCreated {}

#[derive(Debug, Deserialize)]
struct KeyResultUpdated {}

#[derive(Debug, Deserialize)]
struct KeyResultDeleted {}
