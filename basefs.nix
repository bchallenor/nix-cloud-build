{ bash, coreutils, runCommand }:

runCommand "basefs" {} ''
  mkdir -p $out/bin $out/usr/bin $out/etc $out/etc/nix

  ln -s ${bash}/bin/bash $out/bin/sh

  ln -s ${coreutils}/bin/env $out/usr/bin/env

  cat >$out/etc/passwd <<EOF
  root:!:0:0::/root:${coreutils}/bin/false
  nixbld1:!:30001:30000::/var/empty:${coreutils}/bin/false
  nixbld2:!:30002:30000::/var/empty:${coreutils}/bin/false
  nixbld3:!:30003:30000::/var/empty:${coreutils}/bin/false
  nixbld4:!:30004:30000::/var/empty:${coreutils}/bin/false
  EOF

  cat >$out/etc/group <<EOF
  root:!:0:
  nixbld:!:30000:nixbld1,nixbld2,nixbld3,nixbld4
  EOF

  cat >$out/etc/nix/nix.conf <<EOF
  build-users-group = nixbld
  sandbox = false
  EOF
''
