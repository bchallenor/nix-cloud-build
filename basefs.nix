{ bash, coreutils, runCommand }:

runCommand "basefs" {} ''
  mkdir -p $out/bin $out/usr/bin $out/etc $out/etc/nix

  ln -s ${bash}/bin/bash $out/bin/sh

  ln -s ${coreutils}/bin/env $out/usr/bin/env

  cat >$out/etc/passwd <<EOF
  root:!:0:0::/root:${coreutils}/bin/false
  EOF

  cat >$out/etc/group <<EOF
  root:!:0:
  EOF

  cat >$out/etc/nix/nix.conf <<EOF
  build-users-group =
  sandbox = false
  EOF
''
