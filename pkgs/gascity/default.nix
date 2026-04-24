{
  lib,
  stdenv,
  fetchurl,
}:
let
  version = "1.0.0";

  # Upstream publishes one prebuilt tarball per (os, arch). Hashes were
  # captured from `nix-prefetch-url` against the v1.0.0 release assets.
  sources = {
    aarch64-darwin = {
      url = "https://github.com/gastownhall/gascity/releases/download/v${version}/gascity_${version}_darwin_arm64.tar.gz";
      hash = "sha256-S2zb/9UotLKYUQj82OIS0m3s7uzHjkso+VoJx+MJFFk=";
    };
    x86_64-darwin = {
      url = "https://github.com/gastownhall/gascity/releases/download/v${version}/gascity_${version}_darwin_amd64.tar.gz";
      hash = "sha256-1051hj7RacC12/a2X5My980BbbEyEcyKQ4+A57glMZw=";
    };
    x86_64-linux = {
      url = "https://github.com/gastownhall/gascity/releases/download/v${version}/gascity_${version}_linux_amd64.tar.gz";
      hash = "sha256-zEXmvlTGuwD+aRWCn4vquyWlhbYEpHhGhFqnuacDcNM=";
    };
    aarch64-linux = {
      url = "https://github.com/gastownhall/gascity/releases/download/v${version}/gascity_${version}_linux_arm64.tar.gz";
      hash = "sha256-DTEHuDyk460zzG4UWEQHnR9AJzBMYh4HHy8IXGTZpno=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "gascity: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "gascity";
  inherit version;

  src = fetchurl source;

  # Tarballs unpack a single `gc` binary at the root, no nested dir.
  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 gc $out/bin/gc
    runHook postInstall
  '';

  meta = {
    description = "Gas City: tmux/dolt-based agent operations CLI (gc)";
    homepage = "https://github.com/gastownhall/gascity";
    license = lib.licenses.mit;
    mainProgram = "gc";
    platforms = builtins.attrNames sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
