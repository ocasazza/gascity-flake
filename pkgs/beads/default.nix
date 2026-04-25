{
  lib,
  stdenv,
  fetchurl,
}:
let
  version = "1.0.2";

  # Upstream publishes one prebuilt tarball per (os, arch). Hashes were
  # captured from `nix-prefetch-url` against the v1.0.2 release assets.
  sources = {
    aarch64-darwin = {
      url = "https://github.com/gastownhall/beads/releases/download/v${version}/beads_${version}_darwin_arm64.tar.gz";
      hash = "sha256-87J+3U7UPOiqeSg3FF8yTkuKPL+dwMgdFEaC2kYYkDg=";
    };
    x86_64-darwin = {
      url = "https://github.com/gastownhall/beads/releases/download/v${version}/beads_${version}_darwin_amd64.tar.gz";
      hash = "sha256-fZ3je1ROzFXMx5jaZ3gFE0TbqDmDSUOVeULzhBLXoTo=";
    };
    x86_64-linux = {
      url = "https://github.com/gastownhall/beads/releases/download/v${version}/beads_${version}_linux_amd64.tar.gz";
      hash = "sha256-ZigLyhRYEhhoQCf+4ACBDC5Aqcb+AOh2/2S9ywGgNsA=";
    };
    aarch64-linux = {
      url = "https://github.com/gastownhall/beads/releases/download/v${version}/beads_${version}_linux_arm64.tar.gz";
      hash = "sha256-97YMI5gwW9sY1OzhyEuHlR5bvNaWb6DWB6wW+dbhGk0=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "beads: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "beads";
  inherit version;

  src = fetchurl source;

  # Upstream tarball layout differs per platform: darwin tarballs nest
  # under `beads_${version}_${os}_${arch}/`, linux tarballs are flat.
  # The default unpackPhase + `sourceRoot = "."` relies on a stdenv
  # patch that older nixpkgs revisions don't carry (the unpack-found-
  # no-directories check fires before sourceRoot is honored), so do the
  # extraction by hand into a fresh dir. Works on every stdenv vintage.
  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    mkdir -p source
    tar -xzf "$src" -C source
    runHook postUnpack
  '';

  sourceRoot = "source";

  installPhase = ''
    runHook preInstall
    install -Dm755 "$(find . -type f -name bd | head -n1)" "$out/bin/bd"
    runHook postInstall
  '';

  meta = {
    description = "Beads: dependency-aware issue tracker CLI (bd)";
    homepage = "https://github.com/gastownhall/beads";
    license = lib.licenses.mit;
    mainProgram = "bd";
    platforms = builtins.attrNames sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
