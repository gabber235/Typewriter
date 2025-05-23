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
    }
}
