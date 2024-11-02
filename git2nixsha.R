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

# {
#"sri_hash": [
#  "sha256-CLTX347KwwsNyuX84hw2/n/9HwQHBYQrGDu7jFctGO4="
#  ],
#"deps": [
#  "checkmate data_table digest Formula formula_tools ggplot2 gtable memoise plyr scales sf stringr purrr isoband lubridate"
#  ]
#}

#testthat::expect_equal(
#            get_imports("https://github.com/tidyverse/dplyr",
#                        "1832ffbbdf3a85145b1545b84ee7b55a99fbae98"),
#            "cli generics glue lifecycle magrittr pillar R6 rlang tibble tidyselect vctrs"
#          )
#
#testthat::expect_equal(
#            get_imports("https://github.com/rap4all/housing/",
#                        "1c860959310b80e67c41f7bbdc3e84cef00df18e"),
#            "dplyr ggplot2 janitor purrr readxl rlang rvest stringr tidyr"
#          )
