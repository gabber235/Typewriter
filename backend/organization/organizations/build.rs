fn main() {
    let proto_files = [
        "../../../proto/models/common.proto",
        "../../../proto/models/organization.proto",
        "../../../proto/api/organization.proto",
    ];
    
    let mut config = prost_build::Config::new();
    config.type_attribute(".", "#[derive(serde::Serialize, serde::Deserialize)]");
    config.out_dir("src/generated");
    config
        .compile_protos(&proto_files, &["../../../proto/"])
        .expect("Failed to compile proto files");
}
