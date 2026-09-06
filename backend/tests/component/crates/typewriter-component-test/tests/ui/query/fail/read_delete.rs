use wasmcloud_utils::read_query;

fn main() {
    let _query = read_query!("DELETE user:test;");
}
