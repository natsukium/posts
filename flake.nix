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
      devShell = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

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
                  "${pkgs.textlint-rule-prh}/lib/node_modules/textlint-rule-prh/node_modules/prh/prh-rules/media/WEB+DB_PRESS.yml"
                  "${pkgs.textlint-rule-prh}/lib/node_modules/textlint-rule-prh/node_modules/prh/prh-rules/media/techbooster.yml"
                ];
              };
            };
          };
        in
        pkgs.mkShell {
          packages = with pkgs; [
            nodejs
            markdownlint-cli2
            (textlint.withPackages [
              textlint-rule-preset-ja-technical-writing
              textlint-rule-prh
            ])
            zenn-cli
          ];

          shellHook = ''
            unlink .textlintrc
            ln -s ${textlintrc} .textlintrc
          '';
        }
      );
    };
}
