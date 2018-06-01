#------------------------------------------------------
# Function that given an order optains the duplicated
# sequence. Useful to apply a reshape
# INPUT:
#   pos_seq: the sequence of positions
#   n_order: the order of the output model
# OUTPUT:
#   rep_seq: a sequence where all the positions are
#   replicated according to a given order
#------------------------------------------------------
getReplicatedSequence <- function(pos_seq, n_order){
  length_s <- length(pos_seq)
  
  rep_seq <- c()
  for (i in 1:(n_order + 1)){
    rep_seq <- c(rep_seq, pos_seq[i:(length_s - n_order + (i - 1))])
  }
  return(rep_seq)
}

#------------------------------------------------------
# Function that given a order returns a set of labels
# with the structure 'srcX' where x is the order
# INPUT:
#   n_order: the order of the output model
# OUTPUT:
#   sequence of labels with the structure 'srcX'
#------------------------------------------------------
getSrcLabels <- function(n_order){
  return(sapply(1:n_order, function(x) {
    return(paste0("src", x))
  }
  ))
}

#------------------------------------------------------
# Function that given a order returns a set of labels
# with the structure 'targetX' where x is the order
# INPUT:
#   n_order: the order of the output model
# OUTPUT:
#   sequence of labels with the structure 'targetX'
#------------------------------------------------------
getTargetLabels <- function(n_order){
  return(sapply(1:n_order, function(x){
    return(paste0('target', x))
  }
  ))
}

#------------------------------------------------------
# Normalize the edge_list in order to optain a transition
# probability
# INPUT:
#   edge_list: from -> to edges with a N specifing the
#   number of times that a edge is visited
# OUTPUT:
#   edge_list of the transition matrix
#------------------------------------------------------
normalizeEdgeList <- function(edge_list,n_order){
  norm_factor <- edge_list[, .(nfactor = sum(.SD$N)),
                           by = c(getSrcLabels(n_order))]
  
  edge_list <- merge(edge_list, norm_factor, by = getSrcLabels(n_order))
  edge_list$prob <- edge_list$N / edge_list$nfactor
  
  return(edge_list[, c(getSrcLabels(n_order), getTargetLabels(n_order), "prob"), with = F])
}

#------------------------------------------------------
# Get the dataset with the call sequence in a list
# INPUT:
#   dataset: dataset of calls in a format, user, datatime
#   arr_id
# OUTPUT:
#   A dataset where the call sequence is specified by
#   each user in a list
#------------------------------------------------------
datasetUserList <- function(dataset){
  list_seq <- dataset[ ,
                       .(
                         pos_list = list(.SD$pos_id),      # List containing the ordered position sequence for a given id
                         rle_list = list(rle(.SD$pos_id)), # Run Length Encoding for the position sequence
                         .N                                # Number of positions in the sequence
                       ),
                       by = id]
  
  return(list_seq)
}