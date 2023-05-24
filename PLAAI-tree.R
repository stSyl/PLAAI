# PLAI-tree.R
#
#   Collapsible Tree view for PLAAI
#   The Sentient Syllabus Project
#
#   Based on Adeel Khan's "collapsibleTree" package
#
#   v. 2023-05-17
#
#   boris.steipe@utoronto.ca
# ==============================================================================
#

# == Packages  =================================================================
#
# https://adeelk93.github.io/collapsibleTree/
# https://cran.r-project.org/web/packages/collapsibleTree/collapsibleTree.pdf
if (! requireNamespace("collapsibleTree")) {
  install.packages("collapsibleTree")
}
library(collapsibleTree)

# data.tree::
# https://cran.r-project.org/web/packages/data.tree/vignettes/data.tree.html
# https://cran.r-project.org/web/packages/data.tree/data.tree.pdf
if (! requireNamespace("data.tree")) {
  install.packages("data.tree")
}

if (! requireNamespace("htmlwidgets")) {
  install.packages("htmlwidgets")
}

if (! requireNamespace("stringr")) {
  install.packages("stringr")
}

# == Definitions ===============================================================
TREEHEADER <- "assets/treeHeader.html"
TREEFOOTER <- "assets/treeFooter.html"


# === Functions ================================================================

#== JSON2treeDf() ==============================================================
JSON2treeDf <- function(parents   = "PARENT.KEY", # Relationship to use
                        labelType = "full",       # see makeLabel()
                        attribute = "DEF",        # Key to use for hovertext
                        attName =   "Def.",       # Name of hovertext contents
                        JSONdir   = "JSON"        # Input file directory
) {
# create a data-frame from JSON files as input to collapsibleTreeNetwork()

  # Make a file-list of all JSON files
  inFiles <- list.files(path = JSONdir, pattern = "^[A-Z0-9]{5}\\.json$")

  # Make a dataframe for input data
  l <- length(inFiles)
  DF <- data.frame(PARENT   = character(l),
                   KEY      = character(l),
                   LABEL    = character(l),
                   ATT      = character(l),
                   HTML      = character(l),
                   COLOR    = character(l),
                   SIZE     = character(l),
                   order    = integer(l),
                   showThis = logical(l)
                   )
  rownames(DF) <- gsub("\\.json", "", inFiles)

  # For each file
  for (fileName in inFiles) {
    # read JSON
    J <- jsonlite::fromJSON(file.path(JSONdir, fileName))

    # Parse required information
    STY <- parseStyle(J$STYLE)

    # Write it to the dataframe
    DF[J$KEY, "PARENT"]   <- J[1, parents]
    DF[J$KEY, "KEY"]      <- J$KEY
    DF[J$KEY, "LABEL"]    <- makeLabel(J, labelType)
    DF[J$KEY, "ATT"]      <- J[1, attribute]
    DF[J$KEY, "HTML"]      <- makeHTML(J[1, c("KEY", "TITLE", "DEF")])
    DF[J$KEY, "COLOR"]    <- STY$col
    DF[J$KEY, "SIZE"]     <- STY$size
    DF[J$KEY, "order"]    <- as.numeric(STY$order)
    DF[J$KEY, "showThis"] <- STY$show
  }

  # Remove nodes that should not appear in the tree
  DF <- DF[DF$showThis, ]

  # Re-order DF
  # Ordering information defines the order of nodes within one branch
  #
  # First, count the number of siblings for each node:
  DF$nSiblings <- integer(nrow(DF))
  for (key in DF$KEY) {
    DF[key, "nSiblings"] <- sum(DF$PARENT == DF[key, "PARENT"] , na.rm = TRUE)
  }

  # Nodes that are a single-child need no reordering
  DF[DF$nSiblings == 1, "order"] <- 1

  # Children of two or more need to be reordered. Extract
  #  and unique() the parent keys
  sel <- DF$nSiblings > 1
  needOrdering <- unique(DF$PARENT[sel])

  # For each branch that needs reordering ...
  for(parent in needOrdering) {
    iRows <- which(DF$PARENT == parent)                 # ... select,
    DF[iRows, ] <- DF[iRows[order(DF$order[iRows])], ]  # ... reorder,
    DF[iRows, "order"] <- 1:length(iRows)               # ... renumber,
    rownames(DF)[iRows] <- DF$KEY[iRows]                # ... rename.
  }

  # confirm:
  # print(DF[DF$PARENT == "PLAAI", c("KEY", "PARENT", "order")])
  # print(DF[DF$PARENT == "EDUIT", c("KEY", "PARENT", "order")])


  # Make labels unique
  iDup <- which(duplicated(DF$LABEL))
  if (length(iDup) != 0) {
    # Add unique integers to end.
    for (label in unique(DF$LABEL[iDup])) {
      iRe <- which(DF$LABEL == label)
      for (i in seq_along(iRel)) {
        DF[iRe[i], "LABEL"] <- sprintf("%s.$d", DF[iRe[i], "LABEL"], i)
      }
    }
  }

  # Confirm that all labels are unique
  if (anyDuplicated(DF$LABEL)) {
    stop("Generated labels are not all unique.")
  }

  # Rename attribute column to the desired name that is shown with
  # the hovertext.
  colnames(DF)[colnames(DF) == "ATT"] <- attName

  # check that there is only one "" parent, then set that to NA
  iRoot <- which(DF$PARENT == "")
  stopifnot(length(iRoot) == 1)
  DF[iRoot, "PARENT"] <- NA

  # Rename the keys to whetever should be shown on the Webpage:
  for (i in 1:nrow(DF)) {
    DF$PARENT[i] <- DF[DF$PARENT[i], "LABEL"]
    DF$KEY[i]    <- DF$LABEL[i]
  }

  return(DF)
}


# == parseStyle() ==============================================================
parseStyle <- function(s) {
  # parse the "STYLE" value from the JSON format and return its components.
  s <- strsplit(s, "\\s*;\\s*")[[1]]
  s <- strsplit(s, "\\s*:\\s*")
  s <- t(matrix(unlist(s), ncol = 2, byrow = TRUE))
  colnames(s) <- s[1, ]
  sty <- data.frame(t(s[2, ]))
  sty$show <- as.logical(sty$show)
  return(sty)
}


# == makeLabel() ===============================================================
makeLabel <- function(J, type) {
  # Produce the various types of formatted labels to show in a tree
  # recognized types {key | short | title | full }


  if (type == "key") {
    label <- J$KEY
  } else if (type == "short") {
    label <- J$SHORT
  } else if (type == "title") {
    label <- J$TITLE
  } else if (type == "full"){
    label <- sprintf("%s: %s", J$KEY, J$TITLE)
  } else {
    stop(sprintf("Label type \"%s\" is not valid.", type))
  }

  return(label)

}


# == makeHTML() ================================================================
makeHTML <- function(D) {
  # Expand a dataframe record with D$TITLE, D$KEY, D$DEF into a Markdown
  # formatted link for use in tooltips.
  #
  # HTMLtemplate
  HTML <- sprintf("%%s <a href=\"%s%%s%s\" %s><b>(%%s)</b></a><br/>%%s",
                  "https://stsyl.github.io/PLAAI/md/",  # file path
                  ".html",                              # file extension
                  " target=\"_blank\"")                 # link target
  label <- sprintf(HTML, D$TITLE, D$KEY, D$KEY, D$DEF)
  return(label)
}





# == postProcessHTMLtree() =====================================================
postProcessHTMLtree <- function(filename,
                                headerfile = TREEHEADER,
                                footerfile = TREEFOOTER,
                                linkTips = FALSE) {
  html <- readLines(filename)
  header <- readLines(headerfile)
  footer <- readLines(footerfile)

  vers <- sprintf("<span style=\"color: #AAAAAA;\">%s%s</span>",
                  "Version: ",
                  format(Sys.time(), "%Y-%m-%d"))

  idx <- grep("<PLAAI-VERSION />", header)
  header[idx] <-  gsub("<PLAAI-VERSION />", vers, header[idx])

  # insert the footer
  iInsert <- grep("^</body>", html)
  stopifnot(length(iInsert) == 1)
  html <- c(html[1:(iInsert - 1)], footer, html[iInsert:length(html)])

  # insert the header
  iInsert <- grep("^<body ", html)
  stopifnot(length(iInsert) == 1)
  html <- c(html[1:iInsert], header, html[(iInsert + 1):length(html)])

  if (linkTips) {
    # Make links in the tooltip clickable by adding a special class
    # for anchors inside tooltips to the
    # CSS, right after the CSS for the tooltip itself
    iInsert <- grep("\\.collapsibleTree div\\.tooltip", html)
    stopifnot(length(iInsert) == 1)
    iInsert <- iInsert + 10
    stopifnot(grepl("^\\}$", html[iInsert]))
    txt <- ".collapsibleTree div.tooltip a {\npointer-events: all;\n}"
    html <- c(html[1:iInsert], txt, html[(iInsert + 1):length(html)])

    # edit the tooltip fade-out time to give users enough time to click it
    iEdit <- grep("// Hide tooltip on mouseout", html)
    stopifnot(length(iEdit) == 1)
    iEdit <- iEdit + 3
    stopifnot(grepl("\\.duration\\(500\\)", html[iEdit]))
    # increase the time from 500 to 3,000 ms
    html[iEdit] <- gsub("500", "3000", html[iEdit])
  }

  writeLines(html, filename)

  return(invisible(NULL))

}



# === Guarded Blocks ============
#
if (FALSE) {

  # ============================================================================
  # Workflow: make a collapsible tree from PLAAI - JSON directory

  myPar <- list()

  # parameters for local tree:
  myPar$type  <- "full"
  myPar$HTML   <- NULL
  myPar$font   <- 12;
  myPar$width  <- 1500;
  myPar$height <- 1200
  myPar$linkTips <- FALSE
  myPar$file   <- sprintf("PLAAI-reference-%s.html",
                          format(Sys.time(), "%Y-%m-%d_%H-%M"))

  # parameters for Web tree:
  myPar$type   <- "title"
  myPar$HTML   <- NULL
  myPar$font   <- 16
  myPar$width  <- 1000
  myPar$height <- 900
  myPar$linkTips <- FALSE
  myPar$file   <- sprintf("docs/PLAAI-reference.html")


  # parameters for clickable Web tree:
  myPar$type   <- "title"
  myPar$HTML   <- "HTML"
  myPar$font   <- 16
  myPar$width  <- 1000
  myPar$height <- 900
  myPar$linkTips <- TRUE
  myPar$file   <- sprintf("docs/PLAAI-reference.html")

  # ========
  PLAAItree <- JSON2treeDf(labelType = myPar$type)
  x <- collapsibleTreeNetwork(PLAAItree,
                              fill =      "COLOR",
                              attribute = "Def.",
                              tooltip = TRUE,
                              tooltipHtml = myPar$HTML,
                              fontSize =  myPar$font,
                              width =     myPar$width,
                              height =    myPar$height)
  htmlwidgets::saveWidget(x,
                          file = myPar$file,
                          title = "PLAAI Reference Tree",
                          selfcontained = TRUE)
  postProcessHTMLtree(myPar$file, linkTips = myPar$linkTips)



}

# [END]
