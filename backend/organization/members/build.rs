fn main() {
    let proto_files = [
        "../../../proto/models/common.proto",
        "../../../proto/models/organization/role.proto",
        "../../../proto/models/organization/member.proto",
        "../../../proto/api/organization/member.proto",
    ];

    prost_build::Config::new()
        .out_dir("src/generated")
        .compile_protos(&proto_files, &["../../../proto/"])
        .expect("Failed to compile proto files");
}
