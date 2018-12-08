with (import <nixpkgs> {});

let
  basefs = callPackage ./basefs.nix {};

  cmd = writeScript "cmd" ''
    #!${bash}/bin/bash
    set -eux -o pipefail

    mkdir -m 1777 /tmp

    aws s3 cp "s3://$DRV_BUCKET_NAME/$DRV_OBJECT_KEY" drv.closure

    drv="$(nix-store --import <drv.closure | tail -n1)"

    nix-build "$drv"

    if [ ! -f result ]; then
      echo >/dev/stderr "Result is not a file"
      exit 1
    fi

    aws s3 cp result "s3://$RESULT_BUCKET_NAME/$RESULT_OBJECT_KEY"
  '';

  image = dockerTools.buildLayeredImage {
    name = "nix-build/s3";
    maxLayers = 120;
    contents = [
      awscli
      basefs
      coreutils
      nix
    ];
    config = {
      Cmd = [ cmd ];
      Env = [
        "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
    };
  };

in
  image
