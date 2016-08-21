#' Plot the time or date of your git commits
#' 
#' IMPORTANT: Before calling this function, you must use the `create_git_log_file()` function
#' to generate the data file that is used to make the plot!
#' You also need to have 'foreach', dplyr', 'git2r', 'ggplot2', 'ggExtra' and 'scales' packages installed.
#' 
#' @param logfile The output from `create_git_log_file()`. This is a file containing all the 
#'   necessary info for generating the activity plots. You must call `create_git_log_file()`
#'   first to create the data file, and then you can call this plot function to
#'   plot the data based on that file
#' @param num_months How many months back to look at your commits
#' @param plot_type What type of plot to output ("plotly", "ggplot", or "density")
#'   if you choose "density" then the result will be a ggplot2 plot with marginal density plots
#' @param x The variable to plot along the x axis (one of "repo", "time", "date", or "weekday") 
#' @param y The variable to plot along the y axis (one of "repo", "time", "date", or "weekday") 
plot_git_commits <- function(logfile, num_months = 6,
                             plot_type = c("plotly", "ggplot", "density"),
                             x = "date", y = "time") {
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("You need to install the 'dplyr' package", call. = FALSE)
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("You need to install the 'ggplot2' package", call. = FALSE)
  }
  if (!requireNamespace("scales", quietly = TRUE)) {
    stop("You need to install the 'scales' package", call. = FALSE)
  }
  if (!requireNamespace("ggExtra", quietly = TRUE)) {
    stop("You need to install the 'ggExtra' package", call. = FALSE)
  }
  
  plot_type <- match.arg(plot_type)
  
  if (!is.numeric(num_months) || num_months < 1) {
    stop("num_months must be a positive integer", call. = FALSE)
  }
  
  if (x == y || !all(c(x, y) %in% c("repo", "time", "date", "weekday"))) {
    stop('x and y must each be one of "repo", "time", "date" or "weekday" and must be unique', call. = FALSE)
  }
  
  # read the logfile and transform it into a useful dataframe
  gitdata <- get_git_df(logfile, num_months)
  
  # plot the result
  plot_git_commits_helper(gitdata, plot_type, x, y)
}

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
create_git_log_file <- function(
  username = "daattali",
  repos = c("beautiful-jekyll",
            "shinyjs",
            "timevis",
            "jennybc/bingo"),
  dir ="git_repos_vis") {
  
  if (!requireNamespace("git2r", quietly = TRUE)) {
    stop("You need to install the 'git2r' package", call. = FALSE)
  }
  
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  #dir <- normalizePath(dir)
  
  require(foreach)
  
  # clone all the git repos into one folder
  logdata <- foreach(repo = repos, .combine = 'rbind') %do% {
    if (!grepl("/", repo)) {
      repo <- paste0(username, "/", repo)
    }
    repo_name <- sub(".*/(.*)", replacement = "\\1", repo)
    dir_repo <- file.path(dir, repo_name)
    if (dir.exists(dir_repo)) {
      message("Note: Not cloning ", repo, " because a folder with that name already exists")
    } else {
      message("Cloning ", repo) 
      repo_url <- paste0("https://github.com/", repo)
      git2r::clone(url = repo_url, local_path = dir_repo, 
                   progress = FALSE)
    }
    repo <- git2r::repository(dir_repo)
    commits <- git2r::commits(repo)
    dates <- sapply(commits, function(commit) as(commit@author@when, "POSIXct"))
    data.frame(repo = rep(repo_name, length(commits)), timestamp = dates)
  }
  
  return(logdata)
}

#--- Helper functions ---#

get_git_df <- function(gitdata, num_months) {
  library(dplyr)
  
  date_cutoff <- as.POSIXct(seq(Sys.Date(), length = 2, 
                                by = paste0(-num_months, " months"))[2])
  
  gitdata %<>%
    dplyr::mutate(ts = as.POSIXct(timestamp, origin = "1970-01-01", tz = "UTC")) %>%
    dplyr::filter(ts >= date_cutoff) %>%
    dplyr::mutate(
      date = as.Date(ts),
      time_short = format(ts, format = "%H:%M"),
      time = as.POSIXct(time_short, format = "%H:%M", tz = "UTC"),
      weekday = factor(weekdays(date), 
                       levels = weekdays(as.Date("2000-01-03") + 0:6))
    ) %>%
    dplyr::select(repo, date, time_short, time, weekday) %>%
    droplevels()
  gitdata
}

plot_git_commits_helper <- function(gitdata, plot_type = "plotly", x = "repo", y = "time") {
  # Define a large set of distinct colours
  all_cols <- c(
    "#FFFF00", "#1CE6FF", "#FF34FF", "#FF4A46", "#008941", "#006FA6", "#A30059", "#000000", 
    "#FFDBE5", "#7A4900", "#0000A6", "#B79762", "#004D43", "#8FB0FF", "#63FFAC", "#997D87",
    "#5A0007", "#809693", "#FEFFE6", "#1B4400", "#4FC601", "#3B5DFF", "#4A3B53", "#FF2F80",
    "#61615A", "#BA0900", "#6B7900", "#00C2A0", "#FFAA92", "#FF90C9", "#B903AA", "#D16100",
    "#DDEFFF", "#000035", "#7B4F4B", "#A1C299", "#300018", "#0AA6D8", "#013349", "#00846F",
    "#372101", "#FFB500", "#C2FFED", "#A079BF", "#CC0744", "#C0B9B2", "#C2FF99", "#001E09",
    "#00489C", "#6F0062", "#0CBD66", "#EEC3FF", "#456D75", "#B77B68", "#7A87A1", "#788D66",
    "#885578", "#FAD09F", "#FF8A9A", "#D157A0", "#BEC459", "#456648", "#0086ED", "#886F4C",
    "#34362D", "#B4A8BD", "#00A6AA", "#452C2C", "#636375", "#A3C8C9", "#FF913F", "#938A81",
    "#575329", "#00FECF", "#B05B6F", "#8CD0FF", "#3B9700", "#04F757", "#C8A1A1", "#1E6E00",
    "#7900D7", "#A77500", "#6367A9", "#A05837", "#6B002C", "#772600", "#D790FF", "#9B9700",
    "#549E79", "#FFF69F", "#201625", "#72418F", "#BC23FF", "#99ADC0", "#3A2465", "#922329",
    "#5B4534", "#FDE8DC", "#404E55", "#0089A3", "#CB7E98", "#A4E804", "#324E72", "#6A3A4C")
  
  library(ggplot2)
  
  p <- ggplot(gitdata, aes_string(x, y, label = "time_short")) +
    geom_point(aes(fill = repo), col = "#555555", size = 5,
               shape = 21, position = position_jitter()) +
    theme_bw(20) + 
    xlab(NULL) + ylab(NULL) +
    scale_fill_manual(values = all_cols[seq_along(unique(gitdata$repo))]) +
    theme(legend.position = "bottom")
  
  if (x == "date") {
    p <- p +
      scale_x_date()
  } else if (x == "time") {
    p <- p +
      scale_x_datetime(labels = scales::date_format("%H:00"), date_breaks = "2 hour")
  } else {
    p <- p + ggExtra::rotateTextX()
  }
  
  if (y == "date") {
    p <- p +
      scale_y_date()
  } else if (y == "time") {
    p <- p +
      scale_y_datetime(labels = scales::date_format("%H:00"), date_breaks = "2 hour")
  }
  
  if (plot_type == "plotly") {
    if (!requireNamespace("plotly", quietly = TRUE)) {
      stop("You need to install the 'plotly' package", call. = FALSE)
    }
    if (x == "time") {
      tooltip <- c("fill", "label", "y")
    } else if (y == "time") {
      tooltip <- c("fill", "x", "label")
    } else {
      tooltip <- c("fill", "x", "y")
    }
    
    p <- plotly::ggplotly(p, tooltip = tooltip)
  } else if (plot_type == "density") {
    p <- ggExtra::ggMarginal(p)
  }
  
  p
}