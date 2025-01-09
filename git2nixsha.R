#* Return the sri hash of a path using `nix hash path --sri path` if Nix is
#* available locally
#* @param repo_url URL to Github repository
#* @param commit Commit hash (SHA-1)
#* @get /hash
function(repo_url, commit) {
  rix:::nix_hash(repo_url, commit)
}

# to test in the terminal using curl
# curl -X GET "https://git2nixsha.dev/hash?repo_url=https%3A%2F%2Fgithub.com%2Feliocamp%2FmetR&commit=1dd5d391d5da6a80fde03301671aea5582643914" -H  "accept: */*"

# you should get

#{
#    "sri_hash": ["sha256-CLTX347KwwsNyuX84hw2/n/9HwQHBYQrGDu7jFctGO4="],
#    "deps": {
#        "package": ["metR"],
#        "imports": ["checkmate", "data_table", "digest", "Formula", "formula_tools", "ggplot2", "gtable", "memoise", "plyr", "scales", "sf", "stringr", "purrr", "isoband", "lubridate"],
#        "remotes": {}
#    }
#}
