source("incl/start.R")
library("listenv")


message("*** batchjobs_multicore() ...")

for (cores in 1:min(2L, availableCores("multicore"))) {
  if (!supportsMulticore()) next
  
  ## FIXME: 
  if (!fullTest && cores > 1) next

  ## CRAN processing times:
  ## On Windows 32-bit, don't run these tests
  if (!fullTest && isWin32) next

  message(sprintf("Testing with %d cores ...", cores))
  options(mc.cores=cores-1L)

  for (globals in c(FALSE, TRUE)) {
    message(sprintf("*** batchjobs_multicore(..., globals=%s) without globals", globals))
  
    f <- batchjobs_multicore({
      42L
    }, globals=globals)
    stopifnot(inherits(f, "BatchJobsFuture") || ((cores == 1 || !supportsMulticore()) && inherits(f, "SequentialFuture")))
  
    print(resolved(f))
    y <- value(f)
    print(y)
    stopifnot(y == 42L)
  
  
    message(sprintf("*** batchjobs_multicore(..., globals=%s) with globals", globals))
    ## A global variable
    a <- 0
    f <- batchjobs_multicore({
      b <- 3
      c <- 2
      a * b * c
    }, globals=globals)
    print(f)
  
  
    ## A multicore future is evaluated in a separated
    ## forked process.  Changing the value of a global
    ## variable should not affect the result of the
    ## future.
    a <- 7  ## Make sure globals are frozen
  ##  if ("covr" %in% loadedNamespaces()) v <- 0 else ## WORKAROUND
    if (globals) {
      v <- value(f)
      print(v)
      stopifnot(v == 0)
    } else {
      res <- tryCatch({ value(f) }, error=identity)
      print(res)
      stopifnot(inherits(res, "simpleError"))
    }
  
  
    message(sprintf("*** batchjobs_multicore(..., globals=%s) with globals and blocking", globals))
    x <- listenv()
    for (ii in 1:3) {
      message(sprintf(" - Creating batchjobs_multicore future #%d ...", ii))
      x[[ii]] <- batchjobs_multicore({ ii }, globals=globals)
    }
    message(sprintf(" - Resolving %d batchjobs_multicore futures", length(x)))
  ##  if ("covr" %in% loadedNamespaces()) v <- 1:3 else ## WORKAROUND
    if (globals) {
      v <- sapply(x, FUN=value)
      stopifnot(all(v == 1:3))
    } else {
      v <- lapply(x, FUN=function(f) tryCatch(value(f), error=identity))
      stopifnot(all(sapply(v, FUN=inherits, "simpleError")))
    }
  } # for (globals ...)

  message(sprintf("Testing with %d cores ... DONE", cores))
} ## for (cores ...)


message("*** batchjobs_multicore(..., workers=1L) ...")

a <- 2
b <- 3
yTruth <- a * b

f <- batchjobs_multicore({ a * b }, workers=1L)
rm(list=c("a", "b"))

v <- value(f)
print(v)
stopifnot(v == yTruth)

message("*** batchjobs_multicore(..., workers=1L) ... DONE")


## CRAN processing times:
## On Windows 32-bit, don't run these tests
if (fullTest || !isWin32) {
  message("*** batchjobs_multicore() and errors ...")
  f <- batchjobs_multicore({
    stop("Whoops!")
    1
  })
  print(f)
  v <- value(f, signal=FALSE)
  print(v)
  stopifnot(inherits(v, "simpleError"))

  res <- try(value(f), silent=TRUE)
  print(res)
  stopifnot(inherits(res, "try-error"))

  ## Error is repeated
  res <- try(value(f), silent=TRUE)
  print(res)
  stopifnot(inherits(res, "try-error"))
  
  message("*** batchjobs_multicore() and errors ... DONE")
}

message("*** batchjobs_multicore() ... DONE")

source("incl/end.R")
