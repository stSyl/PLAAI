# PLAAI-tools.R
#
#   Data and text conversion tools for PLAAI
#   The Sentient Syllabus Project
#
#   v. 2023-05-15
#
#   boris.steipe@utoronto.ca
# ==============================================================================
#

# == Packages  ======
if (! requireNamespace("jsonlite")) {
  install.packages("jsonlite")
}

if (! requireNamespace("data.tree")) {
  install.packages("data.tree")
}

if (! requireNamespace("yaml")) {
  install.packages("yaml")
}

if (! requireNamespace("stringr")) {
  install.packages("stringr")
}




# == Init

INFILE  <- "PLAAI.txt"
CSVFILE <- "PLAAI.csv"

# == Functions

# Fetch the latest version of PLAAI from the Google Sheets master
fetchPLAAIdf <- function() {
  url <- paste0(readLines("../PLAAI-master.url.txt"),
                "/gviz/tq?tqx=out:csv&sheet=PLAAI")
  x <- read.csv(url)
  rownames(x) <- x$KEY
  for (i in 1:ncol(x)) {
    x[is.na(x[ , i]), i] <- ""
  }

  stopifnot(all(x$STATUS %in% c("stub", "dev", "public")))

  return(x)
}

# == graph2list ==
# convert a edge-list representation of a tree to an indented list
#
graph2list <- function(DF, parents = "P_ISA", sep = "  ") {

  txt <- character(0)
  for(key in rownames(DF)) {
    anc <- getAncestors(DF, key, parents)
    txt <- c(txt, sprintf("%s%s %s",
                          paste0(rep(sep, length(anc)), collapse = ""),
                          key,
                          DF[key, "TITLE"]))
  }
  return(txt)
}


# == list2graph ==
# convert an indented list to an edge list (data frame) with columns
# PARENT, CHILD, and  TITLE.
#

list2graph <- function(txt, sep = "  ") {

  txt <- txt[! grepl("^\\s*$", txt)]  # remove empty lines
  txt <- txt[! grepl("^-", txt)]      # remove structuring lines

  EL <- data.frame(PARENT = character(length(txt)),
                   CHILD  = character(length(txt)),
                   TIITLE = character(length(txt)))
  # ancestor list
  lastAnc <- character(0)
  lastAnc[1] <- NA

  for (i in 1:length(txt)) {

    nSep  <- stringr::str_count(gsub("^([^A-Z]*).*", "\\1", txt[i]), sep)
    node  <- stringr::str_extract(txt[i], "[A-Z0-9]{5}")
    title <- gsub(".*[A-Z0-9]{5} (.*)$", "\\1", txt[i])

    EL[i, "PARENT"] <- lastAnc[nSep+1]  # get the last ancestor of that level
    EL[i, "CHILD"]  <- node
    EL[i, "TITLE"]  <- title

    lastAnc[nSep + 2] <- node # this is the last ancestor of any deeper node
  }
  return(EL)
}


# == DFreorder()
# reorder a DF according to a new edge list

DFreorder <- function(DF,
                      EL,
                      pDF = "P_ISA",
                      cDF = "KEY",
                      pEL = "PARENT",
                      cEL = "CHILD") {
  # Original DF is assumed to use the child node labels as rownames (cDF).
  # Ensure the root nodes are valid and identical
  iRootDF <- which(is.na(DF[ ,pDF]))
  iRootEL <- which(is.na(EL[ ,pEL]))
  stopifnot(length(iRootDF) == 1)
  stopifnot(length(iRootEL) == 1)
  stopifnot(DF[iRootDF, cDF] == EL[iRootEL, cEL])

  rDumm <- DF[1, ]
  for (i in 1:ncol(DF)) {
    rDumm[ , i] <- ""
  }

  DFnew <- DF[iRootDF, ]  # copy entire root row from DF
  if (iRootEL != 1) {
    EL <- rbind(EL[iRootEL, ],  EL[-iRootEL, ])    # move root to top of EL
  }
  for (i in 2:nrow(EL)) {
    key <- EL[i, "CHILD"]
    if (! key %in% rownames(DF)) {
      DFnew <- rbind(DFnew, rDumm)
      DFnew[i , cDF] <- key
    } else {
      DFnew <- rbind(DFnew, DF[key, ])
    }
    stopifnot(DFnew[i, cDF] == EL[i, cEL])
    DFnew[i, pDF] <- EL[i, pEL]
    DFnew[i, "TITLE"] <- EL[i, "TITLE"]
  }
  rownames(DFnew) <- DFnew[ , "KEY"]
  return(DFnew)
}


# == Validate tree


validateTree <- function(DF, parents = "P_ISA") {

  # There is exactly one node that has no parent (root).
  stopifnot(sum(is.na(DF[ , parents])) == 1)

  iRoot <- which(is.na(DF[ , parents]))

  # Every node label is correctly formatted
  stopifnot(all(grepl("^[A-Z0-9]{5}$", DF[, "KEY"])))
  stopifnot(all(grepl("^[A-Z0-9]{5}$", DF[ -iRoot, parents])))

  # No keys are duplicated.
  stopifnot(sum(anyDuplicated(DF[ , "KEY"])) == 0)

  # rownames must match keys
  stopifnot(all(rownames(DF) == DF[ , "KEY"]))

  # If there are cycles, getAncestors() will panic.
  # All lineages must lead to the root
  root <- DF[iRoot, "KEY"]
  for (key in DF[ -iRoot, "KEY"]) {
    anc <- getAncestors(DF, key, parents)
    if (anc[length(anc)] != root) {
      stop(sprintf("Ancestors of %s do not end at root (%s).",
                   key, root))
    }
  }

  # If we get to here, then ...
  print("Validated")

}




# get the ancestors for a node
getAncestors <- function(DF, key, parents = "PARENT.KEY", anc) {
  if (missing(anc)) { anc <- character(0) }
  if (length(anc) > 100) {
    stop("PANIC: recursed 100 deep - that can't be right.")
  }
  if (DF[key, parents] == "" ||
      is.na(DF[key, parents])) {  # base case
    return (character(0))
  } else {
    anc <- c(DF[key, parents],
             getAncestors(DF, DF[key, parents], parents, anc))
    return(anc)
  }
}


# Select a branch
selBranch <- function(DF, root, parents = "PARENT.KEY") {
# Return a seletion of all nodes that have "root" as
# their ancestor, and the root node itself, using the tree structure
# defined in the "parents" column
  sel <- logical(0)
  for (key in DF$KEY) {
    anc <- getAncestors(DF, key, parents)
    if (DF[key, "KEY"] == root ||
        (length(anc) > 0 && any(anc == root))) {
      sel <- c(sel, TRUE)
    } else {
      sel <- c(sel, FALSE)
    }
  }
  return(sel)
}


# Create a nested text representation of a branch
tree2nest <- function(DF, root, nSep = 3, parents = "P_ISA") {
  # convert a tree in the dataframe to a nested list using the parents found
  # in column P_ISA and all nodes that have "root" as
  # their ancestor. Alternative categories can be printed by adding a different
  # parents' column and referencing it in the call.
  txt <- character(0)
  myDF <- DF[selBranch(DF, root, parents), ]
  for (key in myDF$KEY) {
    anc <- getAncestors(myDF, key, parents)
    if (myDF[key, "KEY"] == root) {
      l <- 0
    } else {
      l <- length(anc) - 1
    }
    txt <- c(txt, sprintf("%*s%s: %s",
                          l * nSep, "",
                          DF[key, "KEY"],
                          DF[key, "TITLE"]))
  }
  return(txt)
}






# === Guarded execution block
if (FALSE) {
  # initialize
  PLAAIdf <- fetchPLAAIdf()
  # validate
  validateTree(PLAAIdf)
  anyDuplicated(PLAAIdf$KEY)
  PLAAIdf$KEY[nchar(PLAAIdf$KEY) != 5]  # character(0)
  PLAAIdf$KEY[nchar(PLAAIdf$P_ISA) != 5]  # [1] "PLAAI" (The root element)

  # test functions

  # getAncestors()
  getAncestors(PLAAIdf, "PLAAI")  # root: length 0
  getAncestors(PLAAIdf, "xxxxx")  # No such key: length 0
  getAncestors(PLAAIdf, "PSPEC")  # Meta branch
  getAncestors(PLAAIdf, "PLDSN")  # Concept branch
  getAncestors(PLAAIdf, "COGRA")  # Construct branch
  getAncestors(PLAAIdf, "LSTYL")  # Resource branch

  # selBranch()
  sel <- selBranch(PLAAIdf, "NDPRO")
  PLAAIdf[sel, "KEY"]

  # tree2nest()
  cat(sprintf("\n%s", tree2nest(PLAAIdf, "CORNM")))
  cat(sprintf("\n%s", tree2nest(PLAAIdf, "NOTTK")))
  cat(sprintf("\n%s", tree2nest(PLAAIdf, "STSKL")))
  cat(sprintf("\n%s", tree2nest(PLAAIdf, "XCONT")))
  cat(sprintf("\n%s", tree2nest(PLAAIdf, "MODUL")))
  cat(sprintf("\n%s", tree2nest(PLAAIdf, "PLAAI")))


  # graph2list()
  cat(sprintf("\n%s", graph2list(PLAAIdf[selBranch(PLAAIdf, "XCONT"), ])))

if (FALSE) {

  # ==== Full edit workflow ===================================================
  PLAAIdf <- fetchPLAAIdf()    # make sure the version is up to date
  textFile <- "tmp.txt"
  writeLines(graph2list(PLAAIdf), textFile)

  # Edit the text file and save
  # ...

  # Convert to edge list
  EL <- list2graph(readLines(textFile), sep = "  ")
  # Convert back to master spreadsheet format
  DFnew <- DFreorder(PLAAIdf, EL)
  validateTree(DFnew)
  write.csv(DFnew,
            sprintf("PLAAI_%s.csv",format(Sys.time(), "%Y-%m-%d_%H-%M")),
            row.names = FALSE,
            na = "")
}

NewTree <- master2treeDf(DFnew)

x <- collapsibleTreeNetwork(NewTree,
                            fill = "COLOR",
                            attribute = "TASK",
                            width = 600,
                            height = 600)

(outFile <- sprintf("PLAAI-reference-%s.html",
                   format(Sys.time(), "%Y-%m-%d_%H-%M"))) # copy this to load
htmlwidgets::saveWidget(x,
                        file = outFile,
                        title = "PLAAI Tree View",
                        selfcontained = TRUE)

# Postprocess:
#   <h2>PLAAI - A Pattern Language for AI-Augmented Instruction</h2>
# {"viewer":{"width":450,"height":450,"padding":0,"fill":true},"browser":{"width":960,"height":600,"padding":40,"fill":false}}
#
# add version, Author, link.
#

# ================
# Convert Google Sheet to MD files.

PLAAIdf <- fetchPLAAIdf()

for (key in PLAAIdf$KEY) {

}






}


# [END]
