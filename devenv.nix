# The Typewriter toolchain: every pinned tool, plus which xtask command each git hook runs.
# Commands live in `cargo xtask` (xtask/src/main.rs).
{ pkgs, config, inputs, ... }:
let
  pins = import ./nix { inherit pkgs; };
  # Flutter beta: the panel tracks the newest Dart and Flutter releases.
  flutter = inputs.flutter-overlay.packages.${pkgs.stdenv.hostPlatform.system}.beta;
in
{
  packages = [
    flutter # `devenv update flutter-overlay` moves it to the newest release
    pins.nats-server
    pins.wash
    pkgs.bun # Skir code generation and checks, and the documentation site's package manager
    pkgs.nodejs_24 # runs Astro, which builds the documentation site (`cargo xtask check docs`)
    pkgs.toxiproxy # the faults link of the worktree stack (`cargo xtask stack`)
    pkgs.chromedriver # `cargo xtask e2e panel-web`
    pkgs.jdk25 # runs Gradle; project JDKs come from Gradle toolchains
    pkgs.kustomize
    pkgs.kubeconform
    pkgs.yamllint
    pkgs.kubectl
    pkgs.k3d
    pkgs.fluxcd # `cargo xtask cluster ci` bootstraps Flux
    pkgs.crane
    pkgs.ast-grep # project rules (sgconfig.yml), run by `cargo xtask review`
    # Coverage of `cargo xtask check backend`. Its own test suite fails inside the macOS Nix
    # sandbox, so the package is used without running it.
    (pkgs.cargo-llvm-cov.overrideAttrs { doCheck = false; })
  ]
  ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
    # The end to end suites on Linux (CI): the virtual display and recorder `cargo xtask evidence`
    # runs, software OpenGL and Vulkan for the Flutter desktop app and the browser for panel web.
    # llvmpipe and lavapipe need no host driver, so no apt packages are involved.
    pkgs.xvfb
    pkgs.ffmpeg
    pkgs.mesa
    pkgs.vulkan-loader
    pkgs.gtk3
    pkgs.chromium
  ];

  # Xcode and the macOS SDK come from the system: Flutter's native asset builds and
  # `flutter build macos` call Xcode's xcrun, which the Nix SDK does not provide.
  apple.sdk = null;

  env = {
    # `dart` does not know the Flutter it belongs to, so pub cannot resolve `sdk: flutter`
    # packages (`dart run build_runner` in the panel) without being told where Flutter is.
    FLUTTER_ROOT = "${flutter.sdk}";

    NATS_SERVER_BIN = "${pins.nats-server}/bin/nats-server";
  }
  // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
    LIBGL_DRIVERS_PATH = "${pkgs.mesa}/lib/dri";
    __EGL_VENDOR_LIBRARY_DIRS = "${pkgs.mesa}/share/glvnd/egl_vendor.d";
    VK_ICD_FILENAMES = "${pkgs.mesa}/share/vulkan/icd.d/lvp_icd.${pkgs.stdenv.hostPlatform.parsed.cpu.name}.json";
    # Flutter's web device looks for Chrome here; chromedriver drives the same browser.
    CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
  };

  languages.rust = {
    enable = true;
    channel = "stable";
    version = "1.95.0";
    targets = [ "wasm32-wasip2" ];
    components = [
      "rustc"
      "cargo"
      "clippy"
      "rustfmt"
      "rust-src"
      "llvm-tools-preview" # cargo llvm-cov: coverage of `cargo xtask check backend`
    ];
  };

  # Hook rules live in xtask (xtask/src/hooks); devenv installs the hooks on shell entry.
  # Absolute toolchain paths make commits from an IDE outside the shell work too: RUSTC keeps
  # cargo off whatever rustc that PATH would offer, and BUN is the bun xtask's build.rs runs to
  # generate its Skir types (hook entries are not run by a shell, so PATH cannot be extended).
  git-hooks.hooks =
    let
      toolchain = config.languages.rust.toolchainPackage;
      cargo = "env RUSTC=${toolchain}/bin/rustc BUN=${pkgs.bun}/bin/bun ${toolchain}/bin/cargo";
    in
    {
      commit-message = {
        enable = true;
        name = "commit message";
        entry = "${cargo} xtask hook commit-msg"; # the hook runner passes the message file
        stages = [ "commit-msg" ];
      };
      staged-files = {
        enable = true;
        name = "staged files";
        entry = "${cargo} xtask hook pre-commit";
        stages = [ "pre-commit" ];
        pass_filenames = false; # xtask reads the staged index itself
        always_run = true;
      };
    };
}
