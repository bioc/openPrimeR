####
# Actions to perform on loading/attaching the package
######
#' @import ggplot2 lpSolveAPI methods
#' @importFrom reshape2 melt dcast
#' @importFrom plyr ddply summarize arrange . here catcolwise rbind.fill numcolwise
#' @importFrom foreach foreach %dopar% getDoParRegistered getDoParWorkers
#' @importFrom IRanges IRanges as.matrix Views findOverlaps overlapsAny CharacterList
#' @importFrom Biostrings DNAStringSet IUPAC_CODE_MAP extractAt reverseComplement mergeIUPACLetters DNAStringSetList vmatchPattern matchPattern width DNA_BASES
#' @importFrom pwalign nucleotideSubstitutionMatrix pairwiseAlignment mismatch compareStrings
#' @importFrom RColorBrewer brewer.pal 
#' @importFrom grDevices colorRampPalette
#' @importFrom S4Vectors metadata metadata<-
#' @importFrom BiocGenerics unlist start end
#' @importFrom magrittr %>%
#' @importFrom stats na.omit qnorm quantile sd ave fisher.test p.adjust as.formula reshape predict hclust
#' @importFrom utils head read.csv read.delim setTxtProgressBar tail txtProgressBar write.csv write.table
#' @importFrom GenomicRanges GRanges
NULL # need to have some evaluated code here

#' Determination if Selenium is installed.
#'
#' Checks whether selenium module for python is installed on the system.
#'
#' @return \code{TRUE} is selenium for python is available,
#' \code{FALSE} otherwise.
#'
#' @keywords internal
selenium.installed <- function() {
	if (Sys.which("python") == "") {
		# python not available
		return(FALSE)
	}
    cmd <- "python -c 'import selenium'"
    ret <- system(cmd, ignore.stdout = TRUE, ignore.stderr = TRUE)
    if (ret == 0) {
        # installed
        return(TRUE)
    } else {
        return(FALSE)
    }
}
#' Check Tool Installation
#'
#' Checks whether all required tools are installed.
#'
#' @param frontend Whether tool installation shall be checked for the frontend.
#' If \code{TRUE}, dependencies that are required only by the frontend are considered additionally.
#' @return \code{TRUE} for each installed tool, \code{FALSE} otherwise.
#' @keywords internal
check.tool.installation <- function(frontend = FALSE) {
    available.tools <- NULL
    # for melting temperatures
    available.tools["MELTING"] <- Sys.which("melting-batch") != ""
    # for secondary structures
    available.tools["ViennaRNA"] <- Sys.which("RNAfold") != ""
    # for DECIPHER
    available.tools["OligoArrayAux"] <- Sys.which("hybrid-min") != ""
     # for multiple sequence alignments
    available.tools["MAFFT"] <-  Sys.which("mafft") != "" 
    available.tools["Pandoc"] <- Sys.which("pandoc") != ""
    ## for IMGT data retrieval in frontend
    if (frontend) {
        available.tools["Selenium"] <- selenium.installed()
        available.tools["PhantomJS"] <- Sys.which("phantomjs") != ""
    }
    return(available.tools)
}
#' Check Functionality of Third-Party Tools.
#'
#' Checks whether all required tools should work.
#'
#' @param frontend Whether tool functionality shall be checked for the frontend.
#' @return \code{TRUE} for each functioning tool, \code{FALSE} for non-functioning tools.
#' @keywords internal
check.tool.function <- function(frontend = FALSE) {
    available.tools <- check.tool.installation(frontend)
    out <- NULL
    # check for oligoArrayAux
    if (available.tools["OligoArrayAux"]) {
        try(out <- system("hybrid-min -n DNA -t 50 -T 50 -N 0.05 -E -q ACAGGTGCCCACTCCCAGGTGCAG CTGCACCTGGGAGTGGGCACCTGT", 
                    intern = FALSE, ignore.stdout = TRUE))
       if (out != 0) {
            # there was an error
            warning("oligoArrayAux failed checks: disabled. Do you have the UNAFOLDDAT environment variable set?")
            available.tools["OligoArrayAux"] <- FALSE
        }
    }
    # check for Pandoc/Latex
    if (available.tools["Pandoc"] && Sys.which("pdflatex") == "") {
        # don't warn here, otherwise too many warnings are generated
        #warning("Cannot create reports with pandoc since LateX is missing.")
        available.tools["Pandoc"] <- FALSE
    }
    # check for ViennaRNA version
    if (available.tools["ViennaRNA"]) {
        # need to require a specific version (2.4.1) of viennaRNA for support of the used commands
	version <- NULL
    	try (version <- system2("RNAfold", "--version", stdout = TRUE, stderr = TRUE))
        if (!is(version, "try-error")) {
            # the command worked -> check the version string
            v <- strsplit(version, " ")[[1]]
            if (length(v) >= 2) {
                nbr <- try(as.numeric(gsub("\\.", "", v[2])))
                if (!is(nbr, "try-error")) {
                    if (nbr < 241) { # version smaller than 2.4.1
                        warning("ViennaRNA had version < 2.4.1. Disabling ViennaRNA.")
                        available.tools["ViennaRNA"] <- FALSE
                    }
                } else {
                    warning("ViennaRNA version unknown. Disabling.")
                    available.tools["ViennaRNA"] <- FALSE # unknown version
                }
            } else {
                warning("ViennaRNA version unknown. Disabling")
                available.tools["ViennaRNA"] <- FALSE # unknown version
            }
        } else {
            warning("ViennaRNA version unknown. Disabling")
            available.tools["ViennaRNA"] <- FALSE # could not get version info
        }
    }
    return(available.tools)
}
#' Copy MELTING Config File
#'
#' Copies modified MELTING tandem mismatch file to the MELTING data folder.
#'
#' @return TRUE if the file is available in the MELTING folder, FALSE otherwise.
#' @keywords internal
copy.melt.config <- function(melt.bin = NULL) {
    print("DEPRECATED")
	if (length(melt.bin) == 0) {
		melt.bin <- Sys.which("melting-batch")[1]
	}
    tandem.mm.file <- system.file("extdata", 
                        "AllawiSantaluciaPeyret1997_1998_1999tanmm_mod.xml",
                        package = "openPrimeR")
    if (tandem.mm.file == "") {
        warning("The MELTING config file is not present in the openPrimeR package.")
        return(FALSE)
    }
    if (melt.bin != "" ) {
        melt.config.file <- file.path(dirname(melt.bin),
                                "..", "Data", basename(tandem.mm.file))
        if (!file.exists(melt.config.file)) {
			message("Copying MELTING config to: ", melt.config.file)
            s <- file.copy(tandem.mm.file, melt.config.file)
            if (any(!s)) {
                warning("Could not copy MELTING config file to destination.")
            }
            return(all(s))
        } else {
            # file is available
            return(TRUE)
        }
    } else {
        return(FALSE)
    }
}
# actions to be performed when loading the package namespace
.onLoad <- function(libname, pkgname) {
    ################
    # Define package options
    #######
    # order in which constraints are computed (least runtime to highest)
    con.order <- c("primer_length", "gc_clamp", "gc_ratio", "no_runs", "no_repeats", 
               "melting_temp_range", "self_dimerization", "secondary_structure", 
               "primer_coverage", "primer_specificity", 
               "melting_temp_diff", "cross_dimerization")
    # order in which constraints are relaxed (start with least important constraint)
    relax.order <- c("primer_length", "primer_coverage", "no_repeats", "no_runs", "gc_clamp", "primer_specificity", "secondary_structure", "self_dimerization", "cross_dimerization", "gc_ratio", "melting_temp_range", "melting_temp_diff")
    available.constraints <- select.constraints(con.order) # select constraints that can be computed by installed software
    # message("Available constraints:", available.constraints)
    con.order <- con.order[con.order %in% available.constraints]
    relax.order <- relax.order[relax.order %in% available.constraints]
    plot.colors <- c("Constraint" = "Set1", "Group" = "Set2", 
                     "Run" = "Set3", "Primer" = "Accent")
    op <- options()
    op.openPrimeR <- list(
        openPrimeR.constraint_order = con.order,
        openPrimeR.relax_order = relax.order,
        openPrimeR.plot_colors = plot.colors,
        openPrimeR.plot_abbrev = 15 # limit label extent for plots
    )
    # only set options once:
    toset <- !(names(op.openPrimeR) %in% names(op))
    if (any(toset)) {
        options(op.openPrimeR[toset])
    }
    # do not provide any output, even if no var is assigned to this function: 
    invisible()
}

# actions to be performed when attaching the package
.onAttach <- function(libname, pkgname) {
    # add start up message
    available.tools <- check.tool.function()
    if (any(!available.tools)) {
        tool.df <- build.tool.overview(available.tools)
        out <- paste0("There are missing/non-functioning external tools.\n",
                "To use the full potential of openPrimeR, please make sure\n",
                "that the required versions of the speciied tools are\n 
                installed and that they are functional:\n")
        idx <- which(!available.tools)
        tools <- paste0("o ", names(available.tools)[idx], 
              " (", tool.df$URL[match(names(available.tools[idx]), tool.df$Tool)], ")", 
              collapse = "\n")
        out <- paste(out, tools, sep = "")
        packageStartupMessage(out)
		# special warning for Pandoc (latex dependency)
		if (Sys.which("pdflatex") == "") {
			warning("'Pandoc' is non-functional, since 'pdflatex' is not installed on your system.")
		}
    }
    # set the default number of cores to use
    foreach.available <- requireNamespace("foreach", quietly = TRUE)
    # register parallel backend if not registered already
    if (foreach.available && !getDoParRegistered()) { 
        default.nbr.cores <- 2
        if (Sys.info()["sysname"] != "Windows") {
            # do not call parallel_setup for windows machines
            # it seems that registering parallel workers leads to
            # firewall issues -> TIMEOUT when loading the package
		    parallel_setup(default.nbr.cores)
        }
    }
}
