use wasmcloud_utils::read_query;

fn main() {
    let _query = read_query!("SELECT * FROM user WHERE id = $user_id;");
}
