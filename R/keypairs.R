#' @rdname keypairs
#' @title EC2 Keypairs
#' @description Get, create, delete, and import EC2 keypairs
#' @template keypair
#' @param filter \dots
#' @param publickey \dots
#' @template dots
#' @return A list of class \dQuote{ec2_keypair} or list of such objects.
#' @examples
#' \dontrun{
#' k <- create_keypair("test_keypair")
#' describe_keypairs()
#' delete_keypair(k)
#' }
#' @keywords security
#' @export
describe_keypairs <-
function(
  keypair = NULL,
  filter = NULL,
  ...
) {
    query <- list(Action = "DescribeKeyPairs")
    if (!is.null(keypair)) {
        if (inherits(keypair, "ec2_keypair")) {
            keypair <- list(get_keypairname(keypair))
        } else if (is.character(keypair)) {
            keypair <- as.list(get_keypairname(keypair))
        } else {
            keypair <- lapply(keypair, get_keypairname)
        }
        names(keypair) <- paste0("KeyName.", 1:length(keypair))
        query <- c(query, keypair)
    }
    if (!is.null(filter)) {
        vfilter <- c("fingerprint", "key-name")
        if (any(!names(filter) %in% vfilter)) {
            stop("'filter' must be in: ", paste0(vfilter, collapse = ", "))
        }
        query <- c(query, .makelist(filter, type = "Filter"))
    }
    r <- ec2HTTP(query = query, ...)
    out <- unname(lapply(r$keySet, function(z) {
        structure(flatten_list(z), class = "ec2_keypair")
    }))
    names(out) <- unlist(lapply(out, `[[`, "keyName"))
    return(out)
}

#' @rdname keypairs
#' @param path A character string specifying a filepath (or filename) to use as a .pem file for the keypair.
#' @export
create_keypair <-
function(
  keypair,
  path = NULL,
  ...
) {
    query <- list(Action = "CreateKeyPair")
    keypair <- get_keypairname(keypair)
    if (nchar(keypair) > 255) {
        stop("'keypair' must be <= 255 characters")
    }
    query[["KeyName"]] <- keypair
    r <- ec2HTTP(query = query, clean_response = FALSE, ...)
    out <- structure(flatten_list(r), class = "ec2_keypair")
    if (!is.null(path)) {
        cat(out[["keyMaterial"]], file = path)
    }
    return(out)
}

#' @rdname keypairs
#' @export
delete_keypair <-
function(
  keypair,
  ...
) {
    query <- list(Action = "DeleteKeyPair")
    keypair <- get_keypairname(keypair)
    if (nchar(keypair) > 255) {
        stop("'keypair' must be <= 255 characters")
    }
    query$KeyName <- keypair
    r <- ec2HTTP(query = query, ...)
    if (r$return[[1]] == "true") {
        return(TRUE)
    } else { 
        return(FALSE)
    }
}

#' @rdname keypairs
#' @importFrom base64enc base64encode
#' @export
import_keypair <-
function(
  keypair,
  publickey,
  ...
) {
    query <- list(Action = "ImportKeyPair")
    if (nchar(keypair) > 255) {
        stop("'keypair' must be <= 255 characters")
    }
    query$KeyName <- keypair
    query$PublicKeyMaterial <- base64encode(charToRaw(publickey))
    r <- ec2HTTP(query = query, ...)
    return(r)    
}

#' @export
print.ec2_keypair <- function(x, ...) {
    cat("keyName:        ", x$keyName[[1]], "\n")
    cat("keyFingerprint: ", x$keyFingerprint[[1]], "\n")
    invisible(x)
}
