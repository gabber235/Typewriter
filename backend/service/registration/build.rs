fn main() {
    let mut config = prost_build::Config::new();
    config.out_dir("src/generated");
    config
        .compile_protos(
            &[
                "../../../proto/models/common.proto",
                "../../../proto/models/service.proto",
                "../../../proto/api/service/registration.proto",
            ],
            &["../../../proto/"],
        )
        .expect("Failed to compile protos");
}
