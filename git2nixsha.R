#* Return the sri hash of a path using `nix hash path --sri path` if Nix is
#* available locally
#* @param repo_url URL to Github repository
#* @param commit Commit hash (SHA-1)
#* @get /hash
function(repo_url, commit) {
  if (grepl("github", repo_url)) {
    hash_git(repo_url = repo_url, commit)
  } else if (grepl("cran.*Archive.*", repo_url)) {
    hash_cran(repo_url = repo_url)
  } else {
    stop(
      "repo_url argument is wrong. Please provide an url to a Github repo",
      "to install a package from Github, or to the CRAN Archive to install a",
      "package from the CRAN archive."
    )
  }
}


#' Return the SRI hash of an URL with .tar.gz
#' @param url String with URL ending with `.tar.gz`
hash_url <- function(url) {
  path_to_folder <- paste0(
    tempdir(), "repo",
    paste0(sample(letters, 5), collapse = "")
  )

  path_to_tarfile <- paste0(path_to_folder, "/package_tar_gz")
  path_to_src <- paste0(path_to_folder, "/package_src")

  dir.create(path_to_src, recursive = TRUE)
  path_to_src <- normalizePath(path_to_src)
  dir.create(path_to_tarfile, recursive = TRUE)
  path_to_tarfile <- normalizePath(path_to_tarfile)

  h <- curl::new_handle(failonerror = TRUE, followlocation = TRUE)

  # extra diagnostics
  extra_diagnostics <-
    c(
      "\nIf it's a Github repo, check the url and commit.\n",
      "Are these correct? If it's an archived CRAN package, check the name\n",
      "of the package and the version number."
    )

  tar_file <- file.path(path_to_tarfile, "package.tar.gz")

  try_download(
    url = url, file = tar_file, handle = h,
    extra_diagnostics = extra_diagnostics
  )

  untar(tar_file, exdir = path_to_src)

  # when fetching from GitHub archive; e.g.,
  # https://github.com/rap4all/housing/archive/1c860959310b80e67c41f7bbdc3e84cef00df18e.tar.gz")
  # package_src will uncompressed contents in
  # subfolder "housing-1c860959310b80e67c41f7bbdc3e84cef00df18e"
  path_to_source_root <- file.path(
    path_to_src,
    list.files(path_to_src)
  )

  sri_hash <- nix_sri_hash(path = path_to_source_root)

  paths <- list.files(path_to_src, full.names = TRUE, recursive = TRUE)
  desc_path <- grep("DESCRIPTION", paths, value = TRUE)

  deps <- get_imports(desc_path)

  unlink(path_to_folder, recursive = TRUE, force = TRUE)

  return(
    list(
      "sri_hash" = sri_hash,
      "deps" = deps
    )
  )
}

#' Obtain Nix SHA-256 hash of a directory in SRI format (base64)
#' 
#' @param path Path to directory to hash
#' @return string with SRI hash specification
#' @noRd
nix_sri_hash <- function(path) {
  if (!dir.exists(path)) {
    stop("Directory", path, "does not exist", call. = FALSE)
  }
  has_nix_shell <- TRUE
  if (isFALSE(has_nix_shell)) {
    stop_no_nix_shell()
  }

  cmd <- "nix-hash"
  args <- c("--type", "sha256", "--sri", path)
  proc <- sys::exec_internal(
    cmd = cmd, args = args
  )

  poll_sys_proc_blocking(
    cmd = paste(cmd, paste(args, collapse = " ")),
    proc = proc,
    what = cmd,
    message_type = "quiet"
  )

  sri_hash <- sys::as_text(proc$stdout)
  return(sri_hash)
}


#' Return the SRI hash of a CRAN package source using `nix hash path --sri path`
#' @param repo_url URL to CRAN package source
hash_cran <- function(repo_url) {

  # list contains `sri_hash` and `deps` elements
  list_sri_hash_deps <- hash_url(url = repo_url)

  return(list_sri_hash_deps)
}

#' Return the SRI hash of a GitHub repository at a given unique commmit ID
#' 
#' @details `hash_git` will retrieve an archive of the repository URL
#' <https://github.com/<user>/<repo> at a given commit ID. It will fetch 
#' a .tar.gz file from
#' <https://github.com/<user>/<repo>/archive/<commit-id>.tar.gz. Then, it will
#' ungzip and unarchive the downloaded `tar.gz` file. Then, on the extracted
#' directory, it will run `nix-hash`
#' (NAR) hash 
#' NAR
#' @param repo_url URL to GitHub repository
#' @param commit Commit hash
hash_git <- function(repo_url, commit) {

  trailing_slash <- grepl("/$", repo_url)
  if (isTRUE(trailing_slash)) {
    slash <- ""
  } else {
    slash <- "/"
  }
  url <- paste0(repo_url, slash, "archive/", commit, ".tar.gz")

  # list contains `sri_hash` and `deps` elements
  list_sri_hash_deps <- hash_url(url)

  return(list_sri_hash_deps)
}


#' Get the SRI hash of the NAR serialization of a Github repo, if nix is not
#' available locally
#' @param repo_url A character. The URL to the package's Github repository or to
#' the `.tar.gz` package hosted on CRAN.
#' @param commit A character. The commit hash of interest, for reproducibility's
#' sake, NULL for archived CRAN packages.
#' @return list with following elements:
#' - `sri_hash`: string with SRI hash of the NAR serialization of a Github repo
#' - `deps`: string with R package dependencies separarated by space.
#' @noRd
nix_hash_online <- function(repo_url, commit) {
  # handle to get error for status code 404
  h <- curl::new_handle(failonerror = TRUE)

  url <- paste0(
    "http://git2nixsha.dev:1506/hash?repo_url=",
    repo_url, "&commit=", commit
  )

  # extra diagnostics
  extra_diagnostics <-
    c(
      "\nIf it's a Github repo, check the url and commit.\n",
      "Are these correct? If it's an archived CRAN package, check the name\n",
      "of the package and the version number."
    )

  req <- try_get_request(
    url = url, handle = h,
    extra_diagnostics = extra_diagnostics
  )

  # plumber endpoint delivers list with
  # - `sri_hash`: string with SHA256 hash in base-64 and SRI format of a
  # GitHub repository at a given commit ID
  # - `deps`: string with R package dependencies separated by `" "`
  sri_hash_deps_list <- jsonlite::fromJSON(rawToChar(req$content))

  return(sri_hash_deps_list)
}

#' Return the sri hash of a path using `nix-hash --type sha256 --sri <path>` 
#' with local Nix, or using an online API service (equivalent
#' `nix hash path --sri <path>`) if Nix is not available
#' @param repo_url A character. The URL to the package's Github repository or to
#' the `.tar.gz` package hosted on CRAN.
#' @param commit A character. The commit hash of interest, for reproducibility's
#' sake, NULL for archived CRAN packages.
#' @return list with following elements:
#' - `sri_hash`: string with SRI hash of the NAR serialization of a Github repo
#'      at a given deterministic git commit ID (SHA-1)
#' - `deps`: string with R package dependencies separarated by space.
get_sri_hash_deps <- function(repo_url, commit) {
  # if no `options(rix.sri_hash=)` is set, default is `"check_nix"`
  sri_hash_option <- get_sri_hash_option()
  has_nix_shell <- TRUE
  if (isTRUE(has_nix_shell)) {
    switch(sri_hash_option,
      "check_nix" = nix_hash(repo_url, commit),
      "locally" = nix_hash(repo_url, commit),
      "api_server" = nix_hash_online(repo_url, commit)
    )
  } else {
    switch(sri_hash_option,
      "check_nix" = nix_hash_online(repo_url, commit),
      "locally" = {
        if (isFALSE(has_nix_shell)) {
          stop(
            'You set `options(rix.sri_hash="locally")`, but Nix seems not',
            "installed.\n", "Either switch to",
            '`options(rix.sri_hash="api_server")`', "to compute the SRI hashes",
            "through the http://git2nixsha.dev API server, or install Nix.\n",
            no_nix_shell_msg,
            call. = FALSE
          )
        }
      },
      "api_server" = nix_hash_online(repo_url, commit)
    )
  }
}

#' Retrieve validated value for options(rix.sri_hash=)
#' @return validated `rix.sri_hash` option. Currently, either `"check_nix"` 
#' if option is not set, `"locally"` or `"api_server"` if the option is set.
#' @noRd
get_sri_hash_option <- function() {
  sri_hash_options <- c(
    "check_nix",
    "locally",
    "api_server"
  )
  sri_hash <- getOption(
    "rix.sri_hash",
    default = "check_nix"
  )

  valid_vars <- all(sri_hash %in% sri_hash_options)

  if (!isTRUE(valid_vars)) {
    stop("`options(rix.sri_hash=)` ",
      "only allows the following values:\n",
      paste(sri_hash_options, collapse = "; "),
      call. = FALSE
    )
  }

  return(sri_hash)
}

#' Try download contents of an URL onto file on disk
#'
#' Fetch if available and stop with propagating the curl error. Also show URL
#' for context
#' @noRd
try_download <- function(url,
                         file,
                         handle = curl::new_handle(failonerror = TRUE),
                         extra_diagnostics = NULL) {
  tryCatch(
    {
      req <- curl::curl_fetch_disk(url, path = file, handle = handle)
    },
    error = function(e) {
      stop("Request `curl::curl_fetch_disk()` failed:\n",
        e$message[1], extra_diagnostics,
        call. = FALSE
      )
    }
  )
}


get_imports <- function(path) {
  tmp_dir <- tempdir()

  # Some packages have a Description file in the testthat folder
  # (see jimhester/lookup) so we need to get rid of that
  path <- Filter(function(x)!grepl("testthat", x), path)

  # Is the path pointing to a tar.gz archive
  # or directly to a DESCRIPTION file?
  if (grepl("\\.tar\\.gz", path)) {
    untar(path, exdir = tmp_dir)
    paths <- list.files(tmp_dir, full.names = TRUE, recursive = TRUE)
    desc_path <- grep("DESCRIPTION", paths, value = TRUE)
  } else if (grepl("DESCRIPTION", path)) {
    desc_path <- path
  } else {
    stop("Path is neither a .tar.gz archive, nor pointing to a DESCRIPTION file directly.")
  }

  columns_of_interest <- c("Depends", "Imports", "LinkingTo")

  imports <- as.data.frame(read.dcf(desc_path))

  existing_columns <- intersect(columns_of_interest, colnames(imports))

  on.exit(unlink(tmp_dir, recursive = TRUE))

  imports <- imports[, existing_columns, drop = FALSE]

  output <- unname(trimws(unlist(strsplit(unlist(imports), split = ","))))

  # Remove version of R that may be listed in 'Depends'
  output <- Filter(function(x) !grepl("R \\(.*\\)", x), output)

  # Remove minimum package version for example 'packagename ( > 1.0.0)'
  output <- trimws(gsub("\\(.*?\\)", "", output))

  output <- remove_base(unique(output))

  gsub("\\.", "_", output)
}

poll_sys_proc_blocking <- function(cmd, proc,
                                   what = c("nix-build", "expr", "nix-hash"),
                                   message_type = 
                                     c("simple", "quiet", "verbose")
                                   ) {
  what <- match.arg(what, choices = c("nix-build", "expr", "nix-hash"))
  message_type <- match.arg(message_type,
                            choices = c("simple", "quiet", "verbose"))
  is_quiet <- message_type == "quiet"
  
  status <- proc$status
  if (isFALSE(is_quiet)) {
    if (status == 0L) {
      cat(paste0("\n==> ", sys::as_text(proc$stdout)))
      cat(paste0("\n==> `", what, "` succeeded!", "\n"))
    } else {
      msg <- nix_build_exit_msg()
      cat(paste0("`", cmd, "`", " failed with ", msg))
    }
  }
  
}

remove_base <- function(list_imports) {
  imports_nobase <- gsub(
    "(^base$)|(^compiler$)|(^datasets$)|(^grDevices$)|(^graphics$)|(^grid$)|(^methods$)|(^parallel$)|(^profile$)|(^splines$)|(^stats$)|(^stats4$)|(^tcltk$)|(^tools$)|(^translations$)|(^utils$)",
    NA_character_,
    list_imports
  )

  paste(na.omit(imports_nobase), collapse = " ")
}



# to test in the terminal using curl
# curl -X GET "http://127.0.0.1:5471/hash?repo_url=https%3A%2F%2Fgithub.com%2Feliocamp%2FmetR&commit=1dd5d391d5da6a80fde03301671aea5582643914" -H  "accept: */*"

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
