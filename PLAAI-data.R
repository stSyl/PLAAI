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



# == json2md() =================================================================
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

  # Post-process: remove all lines that contain empty table cells which resulted
  # from empty strings in the DF. This is so that stub patterns don't get
  # crowded with empty placeholders. (CAUTION: don't put stuff you need on the
  # same line as a potentially empty tag in the markdown template.)
  sel <- grepl("<td></td>", md)
  md <- md[! sel]

  # Expand all tagged keys like "{{PTEST}}" to links.
  link <- sprintf("https://stsyl.github.io/PLAAI/md/%s.md", KEY)

  patt <- "\\{\\{([A-Z0-9]{5})\\}\\}"
  md <- gsub(patt,
             "([\\1](https://stsyl.github.io/PLAAI/md/\\1.html))",
             md)

  md <- paste0(c(md, ""), collapse = "\n")

  return(md)

}


# == key2linkedFull() ==========================================================
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




if (FALSE) {


# Format according to ISO 8601
format(Sys.time(), "%Y-%m-%dT%H:%M%z")



# === UTILITY: Write all JSONS to Markdown =====================================

# This is required e.g. when we update the Markdown template

  JSONdir <- "JSON"
  inFiles <- list.files(path = JSONdir, pattern = "^[A-Z0-9]{5}\\.json$")
  inKEYS <- stringr::str_extract(inFiles, "^[A-Z0-9]{5}")
  createLog <- character()

  for (KEY in inKEYS) {
    writeLines(json2md(KEY), sprintf("docs/md/%s.md", KEY))
    createLog <- c(createLog, KEY)
  }

print(createLog)


# === UTILITY: Translate a single pattern from JSON to Markdown ================
  KEY <- "PTEST"
  writeLines(json2md(KEY), sprintf("docs/md/%s.md", KEY))

  KEY <- "LECTR"
  writeLines(json2md(KEY), sprintf("docs/md/%s.md", KEY))

}


# [END]
