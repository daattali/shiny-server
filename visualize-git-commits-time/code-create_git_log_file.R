#' Create a data file with all the git commit info of a particular user for some repos
#' 
#' In order to create this data file, all the git repos specified have to be cloned to your
#' local machine (this happens automatically). The result of this function is a data file with
#' information about git commits, and this file can be used as input for `plot_git_commit_time()`
#' (which will visualize the times of day commits were made)
#' 
#' @param username The GitHub username of the user you want to track their commits
#' @param repos A list of all the GitHub repos you want to analyze (all these repos will get cloned locally
#' @param dir The directory where all the git repos will 
#' @param logfile THe name of the data file (the file with all the git lgs
create_git_log_file <- function(
  username = "daattali",
  repos = c("beautiful-jekyll",
            "shinyjs",
            "timevis",
            "jennybc/bingo"),
  dir ="git_repos_vis",
  logfile = "project-logs.csv") {
  
  if (!requireNamespace("git2r", quietly = TRUE)) {
    stop("You need to install the 'git2r' package", call. = FALSE)
  }
  
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  dir <- normalizePath(dir)
  
  # clone all the git repos into one folder
  for (repo in repos) {
    if (!grepl("/", repo)) {
      repo <- paste0(username, "/", repo)
    }
    repo_name <- sub(".*/(.*)", replacement = "\\1", repo)
    if (dir.exists(file.path(dir, repo_name))) {
      message("Note: Not cloning ", repo, " because a folder with that name already exists")
      next
    } else {
      message("Cloning ", repo) 
    }
    repo_url <- paste0("https://github.com/", repo)
    git2r::clone(url = repo_url, local_path = file.path(dir, repo_name), progress = FALSE)
  }
  
  # create a shell script to get the commit logs of all repos
  sh_script_log <- paste0(
    'cd ', dir, ' 
    TMPLOG=$(pwd)/tmp-project-log.csv; 
    echo "project,timestamp" > $TMPLOG;
    for repo in *; do 
      if [ -d $repo ] && [ -d $repo/.git ]; then
        cd $repo;
        git log --author="', username, '" --pretty=format:"$repo,%ai" >> $TMPLOG;
        echo "" >> $TMPLOG;
        cd ..;
      fi
    done
    grep . $TMPLOG > ', logfile, ';
    rm $TMPLOG;')
  system(sh_script_log)
  
  logfile <- file.path(dir, logfile)
  if (file.exists(logfile)) {
    message("Created logfile at ", normalizePath(logfile))
  } else {
    stop("The git log file could not get creatd for some reason", call. = FALSE)
  }
  
  return(logfile)
}