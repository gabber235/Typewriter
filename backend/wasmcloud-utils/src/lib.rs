mod bindings {
    wit_bindgen::generate!({
        pub_export_macro: true,
        generate_all,
    });
}

mod error_response;

#[cfg(test)]
mod tests {
    use super::wasmcloud::messaging::parse_subject;

    #[test]
    fn test_parse_subject_single_segment_action() {
        let template = "user.<user_id>.organization.<action>";
        let subject = "user.123.organization.list";

        let result = parse_subject(template, subject).unwrap();
        assert_eq!(result.get("user_id"), Some(&"123".to_string()));
        assert_eq!(result.get("action"), Some(&"list".to_string()));
    }

    #[test]
    fn test_parse_subject_multi_segment_action() {
        // This test demonstrates the DESIRED behavior for nested actions
        let template = "user.<user_id>.organization.<action>";
        let subject = "user.123.organization.join_requests.list";

        let result = parse_subject(template, subject).unwrap();
        assert_eq!(result.get("user_id"), Some(&"123".to_string()));
        // We want <action> at the end to capture all remaining segments
        assert_eq!(
            result.get("action"),
            Some(&"join_requests.list".to_string())
        );
    }

    #[test]
    fn test_parse_subject_multi_segment_action_deep() {
        let template = "typewriter.in.user.<user_id>.organization.<org_id>.members.<action>";
        let subject = "typewriter.in.user.abc123.organization.org456.members.join_requests.list";

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
        // When <action> is NOT at the end, it should only capture one segment
        let template = "user.<action>.details.<id>";
        let subject = "user.list.details.123";

        let result = parse_subject(template, subject).unwrap();
        assert_eq!(result.get("action"), Some(&"list".to_string()));
        assert_eq!(result.get("id"), Some(&"123".to_string()));
    }
}

#[macro_export]
macro_rules! export {
    ($ty:ident) => {
        ::wasmcloud_utils::__export_wasmcloud_messaging_handler_0_2_0_cabi!($ty with_types_in ::wasmcloud_utils::wasmcloud::messaging::handler);
    };
}

pub mod wasmcloud {
    pub mod messaging {
        use std::collections::HashMap;

        pub use super::super::bindings::exports::wasmcloud::messaging::*;
        pub use super::super::bindings::wasmcloud::messaging::*;

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
        /// assert_eq!(m2, Err("Subject 'test.abc.whatever.foo.bar.baz.qux' doesn't match template 'test.<id>.something.<type>.*.<action>.>', expected 'something' but got 'whatever'".to_string()));
        ///
        ///
        /// // If the subject is too short, an error is returned:
        /// let m3 = parse_subject("test.<id>.something.<type>.*.<action>.>",
        ///                         "test.123.something");
        /// assert_eq!(m3, Err("Subject 'test.123.something' doesn't match template 'test.<id>.something.<type>.*.<action>.>', missing part '<type>.*.<action>.>'".to_string()));
        ///
        /// // When a placeholder is the last template part, it captures all remaining segments:
        /// let m4 = parse_subject("user.<user_id>.organization.<action>",
        ///                         "user.123.organization.join_requests.list")
        ///                         .expect("Failed to parse subject");
        /// assert_eq!(m4.get("action"), Some(&"join_requests.list".to_string()));
        /// ```
        pub fn parse_subject(
            template: &str,
            subject: &str,
        ) -> Result<HashMap<String, String>, String> {
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
        pub fn reply(
            reply_to: types::BrokerMessage,
            data: impl Into<Vec<u8>>,
        ) -> Result<(), String> {
            if let Some(reply_to) = reply_to.reply_to {
                consumer::publish(&types::BrokerMessage {
                    subject: reply_to,
                    reply_to: None,
                    body: data.into(),
                })
            } else {
                Err("No reply_to field in message, ignoring message".to_string())
            }
        }

        /// Dispatch a message to one of multiple action handlers based on the <action> value in the subject.
        ///
        /// This function parses the subject using the provided template (which must include an <action> placeholder),
        /// extracts the action value, and dispatches to the corresponding handler function.
        ///
        /// Each action can optionally have an error handler. When an error occurs and an error handler
        /// is provided for that action, it will call the error handler to generate error response bytes
        /// and send them as a reply to the original message.
        ///
        /// # Arguments
        /// * `msg` - The incoming broker message
        /// * `subject_template` - Subject template that includes `<action>` (e.g., "user.<user_id>.organization.<action>")
        /// * `actions` - A slice of tuples containing (action_name, handler_function, optional_error_handler)
        ///
        /// # Returns
        /// Returns `Ok(())` if the action was handled successfully, or an error if:
        /// - The subject doesn't match the template
        /// - The action is not found in the provided actions list
        /// - The handler function returns an error
        pub fn dispatch_action(
            msg: types::BrokerMessage,
            subject_template: &str,
            actions: &[(
                &str,
                fn(
                    types::BrokerMessage,
                    std::collections::HashMap<String, String>,
                ) -> Result<(), String>,
                Option<fn() -> Vec<u8>>,
            )],
        ) -> Result<(), String> {
            if !subject_template.contains("<action>") {
                return Err(format!(
                    "Subject template '{}' must contain '<action>' placeholder",
                    subject_template
                ));
            }

            let params = parse_subject(subject_template, &msg.subject)?;

            let action = params.get("action").ok_or_else(|| {
                format!(
                    "Failed to extract action from subject '{}' using template '{}'",
                    msg.subject, subject_template
                )
            })?;

            let Some((_, handler, error_handler)) =
                actions.iter().find(|(name, _, _)| *name == action)
            else {
                let valid_actions: Vec<&str> = actions.iter().map(|(name, _, _)| *name).collect();
                return Err(format!(
                    "Unknown action '{}' for subject '{}'. Valid actions are: {}",
                    action,
                    msg.subject,
                    valid_actions.join(", ")
                ));
            };

            let error_handler = *error_handler;
            let result = handler(msg.clone(), params);

            if let Err(_) = result {
                if let Some(err_fn) = error_handler {
                    let error_response = err_fn();
                    if let Some(ref reply_to) = msg.reply_to {
                        let _ = consumer::publish(&types::BrokerMessage {
                            subject: reply_to.clone(),
                            reply_to: None,
                            body: error_response,
                        });
                    }
                }
            }

            result
        }
    }
}

/// Macro to simplify action dispatching by automatically generating the handler function type signatures.
///
/// Each action can optionally have an error handler that generates error response bytes when that action fails.
/// The error handler will be called and its result sent as a reply to the original message.
/// Use `=> handler => error_handler` syntax to specify an error handler.
///
/// # Example
/// ```rust,no_run
/// use wasmcloud_utils::dispatch_actions;
/// use wasmcloud_utils::wasmcloud::messaging::types::BrokerMessage;
/// use std::collections::HashMap;
///
/// fn handle_list(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
///     Ok(())
/// }
///
/// fn handle_create(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
///     Ok(())
/// }
///
/// fn handle_create_error() -> Vec<u8> {
///     vec![1, 2, 3] // protobuf encoded error response
/// }
///
/// fn handle_message(msg: BrokerMessage) -> Result<(), String> {
///     dispatch_actions!(
///         msg,
///         "user.<user_id>.organization.<action>",
///         "list" => handle_list,
///         "create" => handle_create => handle_create_error,
///     )
/// }
/// ```
#[macro_export]
macro_rules! dispatch_actions {
    ($msg:expr, $template:expr, $($rest:tt)+) => {{
        $crate::wasmcloud::messaging::dispatch_action(
            $msg,
            $template,
            &$crate::dispatch_actions!(@collect [] $($rest)+),
        )
    }};

    (@collect [$($acc:tt)*] $action_name:expr => $handler:expr => $error_handler:expr, $($rest:tt)+) => {
        $crate::dispatch_actions!(@collect [$($acc)* (
            $action_name,
            $handler as fn($crate::wasmcloud::messaging::types::BrokerMessage, ::std::collections::HashMap<String, String>) -> Result<(), String>,
            Some($error_handler as fn() -> Vec<u8>),
        ),] $($rest)+)
    };

    (@collect [$($acc:tt)*] $action_name:expr => $handler:expr, $($rest:tt)+) => {
        $crate::dispatch_actions!(@collect [$($acc)* (
            $action_name,
            $handler as fn($crate::wasmcloud::messaging::types::BrokerMessage, ::std::collections::HashMap<String, String>) -> Result<(), String>,
            None,
        ),] $($rest)+)
    };

    (@collect [$($acc:tt)*] $action_name:expr => $handler:expr => $error_handler:expr $(,)?) => {
        [$($acc)* (
            $action_name,
            $handler as fn($crate::wasmcloud::messaging::types::BrokerMessage, ::std::collections::HashMap<String, String>) -> Result<(), String>,
            Some($error_handler as fn() -> Vec<u8>),
        )]
    };

    (@collect [$($acc:tt)*] $action_name:expr => $handler:expr $(,)?) => {
        [$($acc)* (
            $action_name,
            $handler as fn($crate::wasmcloud::messaging::types::BrokerMessage, ::std::collections::HashMap<String, String>) -> Result<(), String>,
            None,
        )]
    };
}
