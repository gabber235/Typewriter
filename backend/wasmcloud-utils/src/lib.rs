mod bindings {
    wit_bindgen::generate!({
        pub_export_macro: true,
        generate_all,
    });
}

#[macro_export]
macro_rules! export {
    ($ty:ident) => {
        ::wasmcloud_utils::wasmcloud::messaging::handler::__export_wasmcloud_messaging_handler_0_2_0_cabi!($ty with_types_in ::wasmcloud_utils::wasmcloud::messaging::handler);
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
                map.insert(key, subject_part.to_string());
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
        /// # Arguments
        /// * `msg` - The incoming broker message
        /// * `subject_template` - Subject template that includes `<action>` (e.g., "user.<user_id>.organization.<action>")
        /// * `actions` - A slice of tuples containing (action_name, handler_function)
        ///
        /// # Returns
        /// Returns `Ok(())` if the action was handled successfully, or an error if:
        /// - The subject doesn't match the template
        /// - The action is not found in the provided actions list
        /// - The handler function returns an error
        ///
        /// # Example
        /// ```rust,no_run
        /// use wasmcloud_utils::wasmcloud::messaging::{dispatch_action, types::BrokerMessage};
        ///
        /// fn handle_list(msg: BrokerMessage, params: std::collections::HashMap<String, String>) -> Result<(), String> {
        ///     // Handle list action
        ///     Ok(())
        /// }
        ///
        /// fn handle_create(msg: BrokerMessage, params: std::collections::HashMap<String, String>) -> Result<(), String> {
        ///     // Handle create action
        ///     Ok(())
        /// }
        ///
        /// fn handle_message(msg: BrokerMessage) -> Result<(), String> {
        ///     dispatch_action(
        ///         msg,
        ///         "user.<user_id>.organization.<action>",
        ///         &[
        ///             ("list", handle_list as fn(BrokerMessage, std::collections::HashMap<String, String>) -> Result<(), String>),
        ///             ("create", handle_create as fn(BrokerMessage, std::collections::HashMap<String, String>) -> Result<(), String>),
        ///         ],
        ///     )
        /// }
        /// ```
        pub fn dispatch_action(
            msg: types::BrokerMessage,
            subject_template: &str,
            actions: &[(&str, fn(types::BrokerMessage, std::collections::HashMap<String, String>) -> Result<(), String>)],
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

            for (action_name, handler) in actions {
                if action_name == action {
                    return handler(msg, params);
                }
            }

            let valid_actions: Vec<&str> = actions.iter().map(|(name, _)| *name).collect();
            Err(format!(
                "Unknown action '{}' for subject '{}'. Valid actions are: {}",
                action,
                msg.subject,
                valid_actions.join(", ")
            ))
        }
    }
}

/// Macro to simplify action dispatching by automatically generating the handler function type signatures.
///
/// # Example
/// ```rust,no_run
/// use wasmcloud_utils::dispatch_actions;
/// use wasmcloud_utils::wasmcloud::messaging::types::BrokerMessage;
/// use std::collections::HashMap;
///
/// fn handle_list(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
///     // Handle list action
///     Ok(())
/// }
///
/// fn handle_create(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
///     // Handle create action
///     Ok(())
/// }
///
/// fn handle_message(msg: BrokerMessage) -> Result<(), String> {
///     dispatch_actions!(
///         msg,
///         "user.<user_id>.organization.<action>",
///         "list" => handle_list,
///         "create" => handle_create
///     )
/// }
/// ```
#[macro_export]
macro_rules! dispatch_actions {
    ($msg:expr, $template:expr, $($action_name:expr => $handler:expr),+ $(,)?) => {{
        $crate::wasmcloud::messaging::dispatch_action(
            $msg,
            $template,
            &[
                $(
                    ($action_name, $handler as fn($crate::wasmcloud::messaging::types::BrokerMessage, ::std::collections::HashMap<String, String>) -> Result<(), String>),
                )+
            ],
        )
    }};
}
