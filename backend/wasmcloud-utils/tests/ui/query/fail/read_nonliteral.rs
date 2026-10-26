use wasmcloud_utils::read_query;

fn main() {
    let query = "SELECT * FROM user;";
    let _query = read_query!(query);
}
