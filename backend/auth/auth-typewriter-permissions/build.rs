fn main() {
    let proto_files = [
        "../../../proto/models/common.proto",
        "../../../proto/models/auth.proto",
        "../../../proto/models/service.proto",
        "../../../proto/api/auth.proto",
        "../../../proto/api/service/registration.proto",
    ];
    
    prost_build::Config::new()
        .out_dir("src/generated")
        .compile_protos(&proto_files, &["../../../proto/"])
        .unwrap();
}
