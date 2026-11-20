# Tools nixpkgs lacks at the needed version. Release binaries are fetched rather than compiled,
# so a cold shell takes minutes.
{ pkgs }:
let
  system = pkgs.stdenv.hostPlatform.system;
  # Maps a Nix system to the value each upstream release uses for it.
  asset = table: table.${system} or (throw "no release asset for ${system}");
  # An archive is unpacked and `binary` is its path inside; a bare executable is installed as is.
  # Extra attributes (an asset name the URL is built from) are allowed and ignored.
  releaseBinary =
    {
      pname,
      version,
      url,
      hash,
      binary ? null,
      ...
    }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version;
      src = pkgs.fetchurl { inherit url hash; };
      sourceRoot = ".";
      dontUnpack = binary == null;
      installPhase =
        if binary == null then
          ''install -Dm755 "$src" "$out/bin/${pname}"''
        else
          ''install -Dm755 ${binary} "$out/bin/${pname}"'';
    };
in
{
  # The newest release of the 2.15 line the brokers Infrastructure deploys run; nixpkgs trails it.
  nats-server = releaseBinary rec {
    pname = "nats-server";
    version = "2.15.3";
    platform = asset {
      aarch64-darwin = "darwin-arm64";
      x86_64-linux = "linux-amd64";
    };
    url = "https://github.com/nats-io/nats-server/releases/download/v${version}/nats-server-v${version}-${platform}.tar.gz";
    hash = asset {
      aarch64-darwin = "sha256-p+JeMiRwJESeMty3Ep/0Ftyjos1Wn+PCBWA+z4/l+BA=";
      x86_64-linux = "sha256-MuGMHnjX70+G5IMHDu86uyZHw9TWfilmgHfHrYHaB5c=";
    };
    binary = "nats-server-v${version}-${platform}/nats-server";
  };

  # The SurrealDB server release every Infrastructure environment runs (the one image tag in its
  # platform/surrealdb/base), which the database suites run against (`cargo xtask check backend`).
  # Nothing checks that the two agree, so a bump moves both. nixpkgs trails it.
  surreal = releaseBinary rec {
    pname = "surreal";
    version = "3.3.5";
    platform = asset {
      aarch64-darwin = "darwin-arm64";
      x86_64-linux = "linux-amd64";
    };
    url = "https://github.com/surrealdb/surrealdb/releases/download/v${version}/surreal-v${version}.${platform}.tgz";
    hash = asset {
      aarch64-darwin = "sha256-U0FAI25yRthpaQFbqa6N0vf48nftFBLLF/PTl/laEJA=";
      x86_64-linux = "sha256-jzvBY0BQhTQ/xtuXRqjgzVVQPJOYAq0rNaRmZ1qcCc8=";
    };
    binary = "surreal";
  };

  # The surrealkit release the database deploy jobs run (`SURREALKIT_IMAGE` in xtask/src/deploy.rs),
  # which runs the database suites; nixpkgs lacks it.
  surrealkit = releaseBinary rec {
    pname = "surrealkit";
    version = "0.6.3";
    target = asset {
      aarch64-darwin = "aarch64-apple-darwin";
      x86_64-linux = "x86_64-unknown-linux-gnu";
    };
    url = "https://github.com/surrealdb/surrealkit/releases/download/v${version}/surrealkit-v${version}-${target}.tar.gz";
    hash = asset {
      aarch64-darwin = "sha256-614svcQRBG+0H3edybN1dePK5E3zCvBGwr854XNrdHM=";
      x86_64-linux = "sha256-99TDEdxTlyFx8OIL4ay19abOdR6spqBgnF1iXRDlzPs=";
    };
    binary = "surrealkit";
  };

  # The Seamlezz wasmCloud fork, which the deployed runtime matches.
  wash = releaseBinary rec {
    pname = "wash";
    version = "2.12.2-1";
    target = asset {
      aarch64-darwin = "aarch64-apple-darwin";
      x86_64-linux = "x86_64-unknown-linux-gnu";
    };
    url = "https://github.com/gabber235/wasmCloud/releases/download/typewriter-v${version}/wash-${target}";
    hash = asset {
      aarch64-darwin = "sha256-XrvAPTUrkak1l95U/+GGZW9yPiprr9u2iYNBZ+BvcM8=";
      x86_64-linux = "sha256-xgI1kKhMHxl4K5JG63klizrrgFcE0aTReJyGPBuTYwU=";
    };
  };
}
