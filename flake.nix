{
  description = "The writing environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          deps =
            with pkgs;
            buildNpmPackage {
              pname = "node-deps";
              version = "0.1.0";
              src = ./.;

              npmDepsHash = "sha256-j0Se4hBOOdWfT3Mr0CLhBofgW+Byp/hhSEvnCyxMgd8=";

              dontNpmBuild = true;

              installPhase = ''
                runHook preInstall

                mkdir -p $out/{bin,node_modules}
                cp -r node_modules $out
                ln -s $out/node_modules/markdownlint-cli2/markdownlint-cli2.js $out/bin/markdownlint-cli2
                ln -s $out/node_modules/textlint/bin/textlint.js $out/bin/textlint
                ln -s $out/node_modules/zenn-cli/dist/server/zenn.js $out/bin/zenn

                runHook postInstall
              '';
            };
        }
      );

      devShell = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          inherit (self.packages.${system}) deps;

          textlintrc = (pkgs.formats.json { }).generate "textlintrc" {
            filters = { };
            rules = {
              preset-ja-technical-writing = {
                ja-no-weak-phrase = false;
                ja-no-mixed-period = false;
                no-exclamation-question-mark = false;
              };
              prh = {
                rulePaths = [
                  "${deps}/node_modules/prh/prh-rules/media/WEB+DB_PRESS.yml"
                  "${deps}/node_modules/prh/prh-rules/media/techbooster.yml"
                  "./prh.yaml"
                ];
              };
            };
          };
        in
        pkgs.mkShell {
          packages = [
            pkgs.nodejs
            deps
          ];

          shellHook = ''
            unlink .textlintrc
            ln -s ${textlintrc} .textlintrc
          '';
        }
      );
    };
}
