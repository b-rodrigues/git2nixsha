#!/bin/bash
while true
do
nix-shell /root/nix_hash_api/default.nix --run "Rscript -e 'plumber::pr_run(plumber::pr(\"/root/nix_hash_api/git2nixsha.R\"), host = \"0.0.0.0\", port=8000)'"
 sleep 10
done
