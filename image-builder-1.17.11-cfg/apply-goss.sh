#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

apply_goss() {

  TKG_GOSS_DIR="$1"

  # The operation takes place on a new set of files copied from original in
  # tkg-goss folder. Copy and replace to avoid missing on any
  # upstream vars that are needed to support upstream serverspecs


  ########## GOSS (https://github.com/aelsabbahy/goss/blob/master/docs/manual.md) ###########
  # 1. Verify & set GOSS Variables
  # 2. Add new TKG specific GOSS variables
  # 3. Add new serverspecs to respective files
  #    3.1 like, goss-command.yaml, goss-kernel-param.yaml
  #    3.2 To add new type not present upstream,
  #        3.2.1 create new file: goss-interface.yaml in same location as other
  #        3.2.2 Add the file to goss.yaml to be loaded along with other serverspecs file


  ########  Replace upstream variables. IF NEEDED. ###########
  # Only change non-inline vars.
  # Inline Vars can be found here: https://github.com/kubernetes-sigs/image-builder/blob/245c03acaa2641240ffe565d46e14c0f0693ec4e/images/capi/packer/ami/packer.json#L149

  # Add TKG goss variables
  cat << 'EOF' >> "${TKG_GOSS_DIR}/goss-vars.yaml"

tkg:
  centos:
    package:
    command:
    service:
    kernel-param:
      fs.file-max:
        value: "96000"
  ubuntu:
    package:
      gawk:
    command:
    service:
    kernel-param:
      fs.file-max:
        value: "96000"
EOF

  # add service type goss server specs
  cat << 'EOF' >> "${TKG_GOSS_DIR}/goss-service.yaml"

{{range $name, $vers := index .Vars.tkg .Vars.OS "service"}}
  {{ $name }}:
  {{range $key, $val := $vers}}
    {{$key}}: {{$val}}
  {{end}}
{{end}}
EOF

  # add package type goss server specs
  cat << 'EOF' >> "${TKG_GOSS_DIR}/goss-package.yaml"

{{range $name, $vers := index .Vars.tkg .Vars.OS "package"}}
  {{$name}}:
    installed: true
  {{range $key, $val := $vers}}
    {{$key}}: {{$val}}
  {{end}}
{{end}}
EOF

  # add command type goss server specs
  cat << 'EOF' >> "${TKG_GOSS_DIR}/goss-command.yaml"

{{range $name, $vers := index .Vars.tkg .Vars.OS "command"}}
  {{ $name }}:
  {{range $key, $val := $vers}}
    {{$key}}: {{$val}}
  {{end}}
{{end}}
EOF

  # add kernel-params type goss server specs
  cat << 'EOF' >> "${TKG_GOSS_DIR}/goss-kernel-params.yaml"

{{range $name, $vers := index .Vars.tkg .Vars.OS "kernel-param"}}
  {{ $name }}:
  {{range $key, $val := $vers}}
    {{$key}}: "{{$val}}"
  {{end}}
{{end}}
EOF

  # Create new goss-args file to refer to new tkg-goss folder
  # Created in capi folder to be consistent with vmwbuild.json & vmwisos.json location
  cat << EOF > "${TKG_GOSS_DIR}/goss-args.json"
{
    "goss_entry_file": "goss/goss.yaml",
    "goss_inspect_mode": "true",
    "goss_tests_dir": "${TKG_GOSS_DIR}",
    "goss_vars_file": "${TKG_GOSS_DIR}/goss-vars.yaml"
}
EOF

}