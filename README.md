[![Build Status](https://travis-ci.org/matdoering/openPrimeR.svg?branch=master)](https://travis-ci.org/matdoering/openPrimeR)[![codecov](https://codecov.io/gh/matdoering/openPrimeR/branch/master/graph/badge.svg)](https://codecov.io/gh/matdoering/openPrimeR) 

# openPrimeR

## Synopsis
openPrimeR is an R package providing methods for designing, evaluating,and
comparing primer sets for multiplex polymerase chain reaction (PCR). The package provides a primer design
function that generates novel primer setes by solving a
set cover problem such that the number of covered template sequences is
maximized with the smallest possible set of primers. Moreover, existing primer sets can be evaluated
according to their coverage and their fulfillment of constraints on the
PCR-relevant physicochemical properties. For PCR tasks for which multiple
possible primer sets exist, openPrimeR can facilitate the selection of the
most suitable set by performing comparative analyses. The R package includes a Shiny application that
provides a comprehensive and intuitive user interface for the core functionalites of the package.

## More information
There is a [Conda repository for openPrimeR available](https://anaconda.org/bioconda/bioconductor-openprimer/badges).
A [Docker container](https://hub.docker.com/r/mdoering88/openprimer/) for running openPrimeR/openPrimeRui is available. Usage:

```
docker pull mdoering88/openprimer
# for openPrimeRui
docker run -rm -p 3838:3838 mdoering88/openprimer
# to work with openPrimeR via the CLI
docker run -rm -it mdoering88/openprimer bash
```

For more information on how to install openPrimeR, we refer to the corresponding [user-space repository](https://github.com/matdoering/openPrimeR-User), which provides installation routines.

## Changelog

Take a look at the [CHANGELOG](inst/NEWS) to view recent changes to the project.

