# PLAAI-data.R
#
#   Data management for PLAAI
#   The Sentient Syllabus Project
#
#   v. 2023-05-17
#
#   boris.steipe@utoronto.ca
# ==============================================================================
#

# == Packages ==================================================================
if (! requireNamespace("jsonlite")) {
  install.packages("jsonlite")
}

if (! requireNamespace("stringr")) {
  install.packages("stringr")
}

# == json2md ===================================================================
json2md <- function(KEY,
                    mdFile = "assets/TEMPLATE.md",
                    path = "JSON") {
  # Convert pattern in JSON <KEY>.json to markdown using the
  # template in "mdFile".

  # read the template
  stopifnot(file.exists(mdFile))
  md <- readLines(mdFile)

  # read the JSON
  inFile <- file.path(path, sprintf("%s.json", KEY))
  stopifnot(file.exists(inFile))
  DF <- jsonlite::fromJSON(inFile)

  # Pre-process array elements. All elements that could need expanding are
  # labelled as .KEY or .KEYS ...

  keyNames <- colnames(DF)[grep("\\.KEYS?$", colnames(DF))]

  for (thisCol in keyNames) {
    txt <- DF[1, thisCol]
    txt <- gsub("\\s+", "", txt)
    txt <- unlist(strsplit(txt, ";"))
    if (length(txt) > 0) {
      x <- character()
      for (s in txt) {
        if (grepl("^[A-Z0-9]{5}$", s)) {
          x <- c(x, sprintf("<li>%s</li>\n", key2linkedFull(s)))
        }
      }
      DF[1, thisCol] <- paste0(x, collapse = "")
    }
  }

  # write all elements into their template target slot

  for (TAG in colnames(DF)) {
    patt <- sprintf("\\{\\{%s\\}\\}", TAG)
    iTAG <- grep(patt, md)

    if (length(iTAG) == 0) {
      next
    } else if (length(iTAG) == 1) {
      # if (DF[1, TAG] != "") { # Don't write empty TAG contents
      #   txt <- sprintf("<!--%s-->%s<!--/%s-->", TAG, DF[1, TAG], TAG)
      # } else {
      #   txt <- ""
      # }
      md[iTAG] <- gsub(patt,  DF[1, TAG], md[iTAG])
    } else {
      stop(sprintf("tag \"%s\" appears more than once in the Markdown template.", TAG))
    }
  }

  # Post-process: remove all lines that contain empty table cells which
  # resulted from empty strings in the DF. (CAUTION: don't put stuff you need
  # on the same line as a potentially empty tag in the markdown template.)
  sel <- grepl("<td></td>", md)
  md <- md[! sel]

  # Expand all tagged keys in the text to links.
  link <- sprintf("https://stsyl.github.io/PLAAI/md/%s.md", KEY)

  patt <- "\\{\\{([A-Z0-9]{5})\\}\\}"
  md <- gsub(patt,
                   "([\\1](https://stsyl.github.io/PLAAI/md/\\1.md))",
                   md)

  md <- paste0(c(md, ""), collapse = "\n")

  return(md)

}



# expandTag <- function(line, patt, J, TAG, devmode = FALSE) {
#   # expand the pattern "patt" in the markdown "line" with contents
#   # in the JSON derived list J according to pattern
#
#   if (length(J[[TAG]]) == 0) {
#     txt <- "NA"
#   } else if (length(J[[TAG]]) == 1) {
#     txt <- as.character(J[[TAG]])
#   } else {
#     # these are arrays of keys. Iterate over them, expand, and
#     # put them into an <ul> list (need to do this in HTML - mixed HTML
#     # and markdown won't handle links properly inside HTML blocks like
#     # tables and divs.)
#     txt <- "<ul>"
#     for (i in seq_along(J[[TAG]])) {
#       txt <- c(txt, sprintf("<li>%s</li>", key2linkedFull(J[[TAG]][i])))
#     }
#     txt <- c(txt, "</ul>")
#     txt <- paste0(txt, collapse = "\n")
#   }
#
#   line <- gsub(patt, txt, line)
#
#   return(line)
#
# }


key2linkedFull <- function(KEY) {
  # returns the full KEY (Title) string, with a link to the MD of KEY.
  # use HTML links, so we can use them inside of tables (HTML and MD don't
  # mix.)
  J <- jsonlite::fromJSON(sprintf("JSON/%s.json", KEY))
  link <- sprintf("https://stsyl.github.io/PLAAI/md/%s.md", KEY)
  full <- sprintf("<a href=\"%s\">%s</a> (%s)",
                  link,
                  KEY,
                  J$TITLE)
  return(full)
}


validateDF <- function(DF, spec = jsonlite::read_json("JSON/PSPEC.json")){
  # Validate that the dataframe DF conforms to the pattern specification
  # found in PSPEC.json
  if (any(colnames(DF) !=  names(spec))) {
    print("PANIC: names mismatch between data frame and JSON")
    print(sprintf("JSON: %s", paste(names(spec), collapse = " | ")))
    print(sprintf("DF: %s", paste(colnames(DF), collapse = " | ")))
    stop()
  }

  # Todo: fetch version from PMETA and check against PLSPEC.json
  return(TRUE)

}



df2JSON <-function(DF, KEY) {
  # Write one row from DF identified by KEY into a JSON format

  stopifnot(KEY %in% rownames(DF))
  x <- DF[KEY, ]
  rownames(x) <- NULL  # Need to clear the rowname, otherwise toJSON()
                       # creates an extra key/value which breaks the schema
                       # and I don't know why they would silently do that
                       # but here we are ...
  json <- jsonlite::toJSON(x, pretty = TRUE)
  return(json)

}




if (FALSE) {

  KEY <- "DEV-LECTR"

  myJ <- jsonlite::read_json(sprintf("JSON/%s.json", KEY))
  myK <- jsonlite::fromJSON(sprintf("JSON/%s.json", KEY))

  myMd <- json2md(jsonlite::read_json(sprintf("JSON/%s.json", KEY)),
                  devmode = TRUE)

  writeLines(myMd, "docs/md/test.md")


  cat(jsonlite::validate("JSON/DEV-LECTR.json"))
  x <- jsonlite::read_json("JSON/DEV-LECTR.json")


# Format according to ISO 8601
format(Sys.time(), "%Y-%m-%dT%H:%M%z")

# == PREP: create the style column ====
  # PLAAIdf <- fetchPLAAIdf()
  #
  # style <- character(nrow(PLAAIdf))
  # col <- getDFcolour(PLAAIdf)
  #
  # for (i in 1:nrow(PLAAIdf)) {
  #   # show:false; col:#CCCCCC; size:10; order:999
  #   style[i] <- sprintf("show:%s; col:%s; size:10; order:%i",
  #                       as.character(as.logical(PLAAIdf$IN.REFERENCE[i])),
  #                       col[i],
  #                       i)
  # }




# === Update all patterns to a new Markdown template

  JSONdir <- "JSON"
  inFiles <- list.files(path = JSONdir, pattern = "^[A-Z0-9]{5}\\.json$")
  inKEYS <- stringr::str_extract(inFiles, "^[A-Z0-9]{5}")
  createLog <- character()

  for (KEY in inKEYS) {
    writeLines(json2md(KEY), sprintf("docs/md/%s.md", KEY))
    createLog <- c(createLog, KEY)
  }


# === Translate a single pattern from JSON to Markdown
  KEY <- "PTEST"
  writeLines(json2md(KEY), sprintf("docs/md/%s.md", KEY))


  KEY <- "LECTR"
  writeLines(json2md(KEY), sprintf("docs/md/%s.md", KEY))


}


# [END]
