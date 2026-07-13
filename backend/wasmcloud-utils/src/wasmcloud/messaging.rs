use std::collections::HashMap;

use otel_wasi::ResultWithSlug;

pub use crate::bindings::exports::wasmcloud::messaging::*;
pub use crate::bindings::wasmcloud::messaging::*;

/// Parse the subject and collect certain components.
///
/// If the subject doesn't match the template an error is returned.
///
/// When a placeholder like `<action>` is the last part of the template,
/// it will capture all remaining segments of the subject (greedy match).
/// This allows for multi-segment actions like `join_requests.list`.
///
/// Suppose a template is `test.<id>.something.<type>.*.<action>.>`
/// Then the following subjects will be parsed:
///
/// ```rust
/// # use wasmcloud_utils::wasmcloud::messaging::parse_subject;
/// let m = parse_subject("test.<id>.something.<type>.*.<action>.>",
///                        "test.123.something.foo.bar.baz.qux.zab")
///                        .expect("Failed to parse subject");
/// assert_eq!(m.get("id"), Some(&"123".to_string()));
/// assert_eq!(m.get("type"), Some(&"foo".to_string()));
/// assert_eq!(m.get("action"), Some(&"baz".to_string()));
/// assert_eq!(m.get(">"), Some(&"qux.zab".to_string()));
///
/// // If the template doesn't match, an error is returned:
/// let m2 = parse_subject("test.<id>.something.<type>.*.<action>.>",
///                         "test.abc.whatever.foo.bar.baz.qux");
/// assert!(m2.is_err());
///
/// // If the subject is too short, an error is returned:
/// let m3 = parse_subject("test.<id>.something.<type>.*.<action>.>",
///                         "test.123.something");
/// assert!(m3.is_err());
///
/// // When a placeholder is the last template part, it captures all remaining segments:
/// let m4 = parse_subject("user.<user_id>.organization.<action>",
///                         "user.123.organization.join_requests.list")
///                         .expect("Failed to parse subject");
/// assert_eq!(m4.get("action"), Some(&"join_requests.list".to_string()));
///
/// // Optional segments can be specified with []:
/// let m5 = parse_subject("[typewriter.from.]user.<user_id>.organization.<action>",
///                         "typewriter.from.user.abc.organization.list")
///                         .expect("Failed to parse subject");
/// assert_eq!(m5.get("user_id"), Some(&"abc".to_string()));
///
/// let m6 = parse_subject("[typewriter.from.]user.<user_id>.organization.<action>",
///                         "user.abc.organization.list")
///                         .expect("Failed to parse subject");
/// assert_eq!(m6.get("user_id"), Some(&"abc".to_string()));
/// ```
pub fn parse_subject(
    template: &str,
    subject: &str,
) -> Result<HashMap<String, String>, otel_wasi::Error> {
    let expanded_templates = expand_optional_segments(template);

    let mut last_error = String::new();
    for expanded_template in &expanded_templates {
        match parse_subject_inner(expanded_template, subject) {
            Ok(map) => return Ok(map),
            Err(e) => last_error = e,
        }
    }

    Err(otel_wasi::Error::new("subject-parse-failed", last_error))
}

fn expand_optional_segments(template: &str) -> Vec<String> {
    let mut optional_segments: Vec<&str> = Vec::new();
    let mut remaining = template;
    let mut base_parts: Vec<&str> = Vec::new();

    while let Some(start) = remaining.find('[') {
        if start > 0 {
            base_parts.push(&remaining[..start]);
        }
        let end = remaining[start..].find(']').map(|e| start + e);
        if let Some(end_idx) = end {
            optional_segments.push(&remaining[start + 1..end_idx]);
            remaining = &remaining[end_idx + 1..];
        } else {
            break;
        }
    }
    base_parts.push(remaining);

    let num_optionals = optional_segments.len();
    if num_optionals == 0 {
        return vec![template.to_string()];
    }

    let mut results = Vec::new();
    for mask in 0..(1 << num_optionals) {
        let mut result = String::new();
        let mut opt_idx = 0;
        let mut remaining = template;

        while let Some(start) = remaining.find('[') {
            result.push_str(&remaining[..start]);
            let end = remaining[start..].find(']').map(|e| start + e).unwrap();
            if (mask >> opt_idx) & 1 == 1 {
                result.push_str(&remaining[start + 1..end]);
            }
            opt_idx += 1;
            remaining = &remaining[end + 1..];
        }
        result.push_str(remaining);
        results.push(result);
    }

    results.sort_by_key(|b| std::cmp::Reverse(b.len()));
    results
}

fn parse_subject_inner(template: &str, subject: &str) -> Result<HashMap<String, String>, String> {
    let mut map = HashMap::new();
    let template_parts = template.split(".").collect::<Vec<&str>>();
    let subject_parts = subject.split(".").collect::<Vec<&str>>();
    for i in 0..template_parts.len() {
        if subject_parts.len() <= i {
            return Err(format!(
                "Subject '{}' doesn't match template '{}', missing part '{}'",
                subject,
                template,
                template_parts[i..].join(".")
            ));
        }

        let template_part = template_parts[i];
        if template_part == "*" {
            continue;
        }
        if template_part == ">" {
            let left_over = subject_parts[i..].join(".");
            map.insert(template_part.to_string(), left_over);
            break;
        }

        let subject_part = subject_parts[i];
        if !template_part.starts_with("<") || !template_part.ends_with(">") {
            if template_part != subject_part {
                return Err(format!(
                    "Subject '{}' doesn't match template '{}', expected '{}' but got '{}'",
                    subject, template, template_part, subject_part
                ));
            }
            continue;
        }

        let key = template_part[1..template_part.len() - 1].to_string();
        if key.is_empty() {
            continue;
        }

        // If this is the last template part and there are more subject parts,
        // capture all remaining segments (greedy match for trailing placeholders)
        let is_last_template_part = i == template_parts.len() - 1;
        if is_last_template_part && subject_parts.len() > i + 1 {
            let remaining = subject_parts[i..].join(".");
            map.insert(key, remaining);
        } else {
            map.insert(key, subject_part.to_string());
        }
    }
    Ok(map)
}

/// Send a message to the reply_to field of the message
pub async fn reply(
    reply_to: types::BrokerMessage,
    data: impl Into<Vec<u8>>,
) -> Result<(), otel_wasi::Error> {
    if let Some(reply_to) = reply_to.reply_to {
        consumer::publish(&types::BrokerMessage {
            subject: reply_to,
            reply_to: None,
            body: data.into(),
        })
        .map_err(|e| otel_wasi::Error::new("message-reply-failed", e))
    } else {
        Err(otel_wasi::Error::new(
            "message-no-reply-to",
            "No reply_to field in message",
        ))
    }
}

/// Send a message with a specific reply_to
pub async fn send(
    subject: String,
    reply_to: String,
    data: impl Into<Vec<u8>>,
) -> Result<(), otel_wasi::Error> {
    consumer::publish(&types::BrokerMessage {
        subject,
        reply_to: Some(reply_to),
        body: data.into(),
    })
    .error_with_slug("message-send-failed")
}

/// Publish a message without a reply_to.
pub async fn publish(subject: String, data: impl Into<Vec<u8>>) -> Result<(), otel_wasi::Error> {
    consumer::publish(&types::BrokerMessage {
        subject,
        reply_to: None,
        body: data.into(),
    })
    .error_with_slug("message-publish-failed")
}

/// Request a reply to a message.
pub async fn request(
    subject: String,
    data: impl Into<Vec<u8>>,
) -> Result<types::BrokerMessage, otel_wasi::Error> {
    consumer::request(&subject, &data.into(), 5000).error_with_slug("message-request-failed")
}

/// Reply to a message with the result of a handler that returns `Result<R, otel_wasi::Error>`.
///
/// `Ok(response)` is serialized and replied as the selected success or domain outcome.
/// `Err(error)` is converted to the response enum's generic `InternalError` variant,
/// replied, and then the original error is returned for logging/tracing.
pub async fn reply_handler_result<R>(
    msg: types::BrokerMessage,
    result: Result<R, otel_wasi::Error>,
) -> Result<(), otel_wasi::Error>
where
    R: crate::SkirResponse,
{
    match result {
        Ok(response) => reply_response(msg, response).await,
        Err(error) => {
            let response = R::internal_error();

            otel_wasi::main_attribute!(
                "messaging.response.variant" = response.variant_slug(),
                "messaging.response.outcome" = crate::SkirResponseOutcome::InternalError.as_str(),
                "messaging.response.success" = false,
            );

            reply(msg, response.to_skir_bytes()).await?;
            Err(error)
        }
    }
}

async fn reply_response<R>(msg: types::BrokerMessage, response: R) -> Result<(), otel_wasi::Error>
where
    R: crate::SkirResponse,
{
    let outcome = response.outcome();
    let slug = response.variant_slug();
    let message = response.variant_message();

    otel_wasi::main_attribute!(
        "messaging.response.variant" = slug,
        "messaging.response.outcome" = outcome.as_str(),
        "messaging.response.success" = outcome == crate::SkirResponseOutcome::Success,
    );

    if outcome == crate::SkirResponseOutcome::DomainError {
        otel_wasi::main_attribute!("messaging.response.message" = message.clone(),);
    }

    reply(msg, response.to_skir_bytes()).await?;

    match outcome {
        crate::SkirResponseOutcome::Success | crate::SkirResponseOutcome::DomainError => Ok(()),
        crate::SkirResponseOutcome::InternalError => Err(otel_wasi::Error::new(slug, message)),
    }
}

pub fn expand_template_pattern(pattern: &str, templates: &[(&str, &str)]) -> String {
    let mut result = pattern.to_string();
    for (template_name, template_value) in templates {
        let placeholder = format!("{{{}}}", template_name);
        result = result.replace(&placeholder, template_value);
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_subject_single_segment_action() {
        let template = "user.<user_id>.organization.<action>";
        let subject = "user.123.organization.list";

        let result = parse_subject(template, subject).unwrap();
        assert_eq!(result.get("user_id"), Some(&"123".to_string()));
        assert_eq!(result.get("action"), Some(&"list".to_string()));
    }

    #[test]
    fn test_parse_subject_optional_prefix_present() {
        let template = "[typewriter.from.]user.<user_id>.organization.<action>";
        let subject = "typewriter.from.user.abc.organization.list";

        let result = parse_subject(template, subject).unwrap();
        assert_eq!(result.get("user_id"), Some(&"abc".to_string()));
        assert_eq!(result.get("action"), Some(&"list".to_string()));
    }

    #[test]
    fn test_parse_subject_optional_prefix_absent() {
        let template = "[typewriter.from.]user.<user_id>.organization.<action>";
        let subject = "user.abc.organization.list";

        let result = parse_subject(template, subject).unwrap();
        assert_eq!(result.get("user_id"), Some(&"abc".to_string()));
        assert_eq!(result.get("action"), Some(&"list".to_string()));
    }

    #[test]
    fn test_parse_subject_multiple_optional_segments() {
        let template = "[prefix.][middle.]user.<user_id>";
        let subject_both = "prefix.middle.user.123";
        let subject_first = "prefix.user.123";
        let subject_second = "middle.user.123";
        let subject_none = "user.123";

        let result_both = parse_subject(template, subject_both).unwrap();
        assert_eq!(result_both.get("user_id"), Some(&"123".to_string()));

        let result_first = parse_subject(template, subject_first).unwrap();
        assert_eq!(result_first.get("user_id"), Some(&"123".to_string()));

        let result_second = parse_subject(template, subject_second).unwrap();
        assert_eq!(result_second.get("user_id"), Some(&"123".to_string()));

        let result_none = parse_subject(template, subject_none).unwrap();
        assert_eq!(result_none.get("user_id"), Some(&"123".to_string()));
    }

    #[test]
    fn test_parse_subject_multi_segment_action() {
        let template = "user.<user_id>.organization.<action>";
        let subject = "user.123.organization.join_requests.list";

        let result = parse_subject(template, subject).unwrap();
        assert_eq!(result.get("user_id"), Some(&"123".to_string()));
        assert_eq!(
            result.get("action"),
            Some(&"join_requests.list".to_string())
        );
    }

    #[test]
    fn test_parse_subject_multi_segment_action_deep() {
        let template = "typewriter.from.user.<user_id>.organization.<org_id>.members.<action>";
        let subject = "typewriter.from.user.abc123.organization.org456.members.join_requests.list";

        let result = parse_subject(template, subject).unwrap();
        assert_eq!(result.get("user_id"), Some(&"abc123".to_string()));
        assert_eq!(result.get("org_id"), Some(&"org456".to_string()));
        assert_eq!(
            result.get("action"),
            Some(&"join_requests.list".to_string())
        );
    }

    #[test]
    fn test_parse_subject_multi_segment_action_three_parts() {
        let template = "members.<action>";
        let subject = "members.join_codes.generate";

        let result = parse_subject(template, subject).unwrap();
        assert_eq!(
            result.get("action"),
            Some(&"join_codes.generate".to_string())
        );
    }

    #[test]
    fn test_parse_subject_action_in_middle_stays_single() {
        let template = "user.<action>.details.<id>";
        let subject = "user.list.details.123";

        let result = parse_subject(template, subject).unwrap();
        assert_eq!(result.get("action"), Some(&"list".to_string()));
        assert_eq!(result.get("id"), Some(&"123".to_string()));
    }

    #[test]
    fn test_expand_template_pattern_single() {
        let templates: &[(&str, &str)] = &[("services", "typewriter.from.service.<service_id>")];
        let pattern = "{services}.status";

        let expanded = expand_template_pattern(pattern, templates);
        assert_eq!(expanded, "typewriter.from.service.<service_id>.status");
    }

    #[test]
    fn test_expand_template_pattern_multiple() {
        let templates: &[(&str, &str)] = &[
            ("services", "typewriter.from.service.<service_id>"),
            (
                "user_services",
                "typewriter.from.user.<user_id>.organization.<org_id>.services",
            ),
        ];

        let pattern1 = "{services}.status";
        let pattern2 = "{user_services}.bind";

        assert_eq!(
            expand_template_pattern(pattern1, templates),
            "typewriter.from.service.<service_id>.status"
        );
        assert_eq!(
            expand_template_pattern(pattern2, templates),
            "typewriter.from.user.<user_id>.organization.<org_id>.services.bind"
        );
    }

    #[test]
    fn test_expand_template_pattern_in_middle() {
        let templates: &[(&str, &str)] = &[("base", "typewriter.from.user.<user_id>")];
        let pattern = "hey.{base}.something.<id>";

        let expanded = expand_template_pattern(pattern, templates);
        assert_eq!(
            expanded,
            "hey.typewriter.from.user.<user_id>.something.<id>"
        );
    }

    #[test]
    fn test_expand_template_pattern_no_match() {
        let templates: &[(&str, &str)] = &[("services", "typewriter.from.service.<service_id>")];
        let pattern = "{unknown}.status";

        let expanded = expand_template_pattern(pattern, templates);
        assert_eq!(expanded, "{unknown}.status");
    }
}
