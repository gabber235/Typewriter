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

  # The Seamlezz wasmCloud fork, which the deployed runtime matches.
  wash = releaseBinary rec {
    pname = "wash";
    version = "2.10.3-1";
    target = asset {
      aarch64-darwin = "aarch64-apple-darwin";
      x86_64-linux = "x86_64-unknown-linux-gnu";
    };
    url = "https://github.com/gabber235/wasmCloud/releases/download/typewriter-v${version}/wash-${target}";
    hash = asset {
      aarch64-darwin = "sha256-i06o97BABXbIbxZoxsjXoOtgLV8cPoZYtnJx3iepd3g=";
      x86_64-linux = "sha256-UyoXJNpNcGWjy4VSrjOsUlQ50PwIbxagBYeCB/MxdNQ=";
    };
  };
}
