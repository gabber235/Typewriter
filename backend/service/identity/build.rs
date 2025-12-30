fn main() {
    let proto_files = [
        "../../../proto/models/common.proto",
        "../../../proto/models/service.proto",
        "../../../proto/api/service.proto",
        "../../../proto/api/auth.proto",
    ];

    prost_build::Config::new()
        .out_dir("src/generated")
        .compile_protos(&proto_files, &["../../../proto/"])
        .expect("Failed to compile proto files");
}
