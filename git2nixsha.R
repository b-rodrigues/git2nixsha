#* Return the sri hash of a path using `nix hash path --sri path`
#* @param repo_url URL to Github repository
#* @param branchName Branch to checkout
#* @param commit Commit hash
#* @get /hash
function(repo_url, branchName, commit) {
  hash_git <- function(repo_url, branchName, commit){
    path_to_repo <- paste0(tempdir(), "repo",
                           paste0(sample(letters, 5), collapse = ""))

    git2r::clone(
             url = repo_url,
             local_path = path_to_repo,
             branch = branchName
           )

    git2r::checkout(path_to_repo, branch = commit)

    unlink(paste0(path_to_repo, "/.git"), recursive = TRUE, force = TRUE)

    command <- paste0("nix hash path --sri ", path_to_repo)

    sri_hash <- system(command, intern = TRUE)

    deps <- get_imports(paste0(path_to_repo, "/DESCRIPTION"))

    unlink(path_to_repo, recursive = TRUE, force = TRUE)

    return(
      list(
      "sri_hash" = sri_hash,
      "deps" = deps)
      )
  }

  hash_cran <- function(repo_url){

    path_to_folder <- paste0(tempdir(), "repo",
                           paste0(sample(letters, 5), collapse = ""))

    dir.create(path_to_folder)

    path_to_tarfile <- paste0(path_to_folder, "/package.tar.gz")

    path_to_src <- paste0(path_to_folder, "/package_src")

    dir.create(path_to_src)

    download.file(url = repo_url,
                  destfile = path_to_tarfile)

    #untar(tarfile = path_to_tarfile, exdir = path_to_src)

    tar_command <- paste("tar", "-xvf", path_to_tarfile, "-C",
                         path_to_src, "--strip-components", 1)

    system(tar_command)

    command <- paste0("nix hash path --sri ", path_to_src)

    sri_hash <- system(command, intern = TRUE)

    deps <- get_imports(paste0(path_to_src, "/DESCRIPTION"))

    unlink(path_to_folder, recursive = TRUE, force = TRUE)

    return(
      list(
        "sri_hash" = sri_hash,
        "deps" = deps)
    )

  }

  if(grepl("github", repo_url)){
    hash_git(repo_url, branchName, commit)
  } else if(grepl("cran.*Archive.*", repo_url)){
    hash_cran(repo_url)
  } else {
    stop("repo_url argument is wrong. Please provide an url to a Github repo to install a package from Github, or to the CRAN Archive to install a package from the CRAN archive.")
  }

}


get_imports <- function(path){

  # remove string like ( >= 1.0.0) from listed packages
  remove_parentheses <- function(input_list) {
    output_list <- gsub("\\s*\\(.*?\\)", "", input_list)
    output_list
  }

  contents <- readLines(path)

  contents <- remove_parentheses(contents)

  imports_line <- grep("^Imports:", contents)


  input_string <- paste(trimws(contents[(imports_line+1):length(contents)]),
                        collapse = " ")

  output <- regmatches(input_string,
                       regexpr(".*?(?<!,)\\s", input_string, perl = TRUE))

  # put the output in vector format to allow removing of base packages
  output <- gsub(",", "\n", output) |>
    textConnection() |>
    readLines() |>
    trimws()

  remove_base(output)
}

remove_base <- function(list_imports){

  gsub("(base)|(compiler)|(datasets)|(grDevices)|(graphics)|(grid)|(methods)|(parallel)|(profile)|(splines)|(stats)|(stats4)|(tcltk)|(^tools)|(translations)|(utils)",
       NA_character_,
       list_imports) |>
    na.omit()  |>
    paste(collapse = " ")

}


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
