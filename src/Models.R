#------------------------------------------------------
# Function that returns a given model
# INPUT:
#   input_filename: name of the file that contains input data in format: id_agent, timestamp, location_id
#   model: An string that indicates with kind of model has to be generated (markovian | adaptive)
#   order: the order of the markovian model
#   parallel: boolean variable. True if the computation has to use multiple cores
#   minimum_events: Minimum number of evets to consider the user
# OUTPUT:
#   edge_list: and edge_list from state nodes composed
#   n_order from and n_order to. And the number of times
#   that a transition between each element appears
#------------------------------------------------------
compute_model <- function(input_filename, model, order, parallel, minimum_events){
  message("Processing...")
  
  message("Loading data...")
  
  #Load data from an specified file
  #TODO: set input from arg
  input_data <- fread(input_filename)
  setnames(input_data, c("id", "datetime", "pos_id"))
  input_data <- input_data[order(id, datetime)]
  
  message("Loading data: OK!")
  
  message("Getting the user list version of dataset")
  
  data.poslist <- datasetUserList(input_data)
  data.poslist <- data.poslist[,.(pos_list, rle_list,len_values_rle = length(.SD$rle_list[[1]]$values), N),by=id]
  
  # Remove the original dataset from memory and run the garbage collector
  rm(input_data)
  gc()
  
  if (model == "markov") {
    message("Computing Markov model...")
    
    edgelist <- as.data.table(
      ldply(data.poslist[N >= minimum_events]$pos_list,
            getMarkovianModel,
            order,
            .parallel = parallel,
            .progress = "text")
    )
  }else{
    message("Computing Adaptive Memory model...")
    
    edgelist <- as.data.table(
      ldply(data.poslist[N >= minimum_events]$rle_list,
            getAdaptiveMemoryModel,
            order,
            .parallel = parallel,
            .progress = "text"
      )
    )
  }
  
  edgelist <- edgelist[ ,
                        .(N = sum(prob)),
                        by = c(getSrcLabels(order), getTargetLabels(order))
                        ]
  
  edgelist <- normalizeEdgeList(edgelist, order)
  
  return(edgelist)
}

#------------------------------------------------------
# Function that given a sequence of position and an order constructs
# a n-order markovian model
# INPUT:
#   pos_seq: sequence of position of a user
#   n_order: the order of the markovian model
# OUTPUT:
#   edge_list: and edge_list from state nodes composed
#   n_order from and n_order to. And the number of times
#   that a transition between each element appears
#------------------------------------------------------
getMarkovianModel <- function(pos_seq, n_order){
  # Gets a sequence of transitions between positions. The length of the sequence depends on the order of the model
  rep_seq <- getReplicatedSequence(pos_seq, n_order)
  trans_matrix <- matrix(rep_seq, ncol = n_order + 1)
  
  # Creates a matrix with that relates the sequents between transitions
  trans_matrix <- cbind(matrix(trans_matrix[, 1:n_order], ncol = n_order),
                        matrix(trans_matrix[, 2:(n_order + 1)], ncol = n_order))
  
  # Creats a dataframe with the previous information
  trans_dt <- as.data.table(matrix(trans_matrix, ncol = 2 * n_order))
  setnames(trans_dt, c(getSrcLabels(n_order), getTargetLabels(n_order)))
  
  # Group de dataframe by relations between transitions
  trans_dt <- trans_dt[, .N,
                       by = c(getSrcLabels(n_order), getTargetLabels(n_order))]
  
  # Normalize the results to get a probability
  return(normalizeEdgeList(trans_dt, n_order))
}


#------------------------------------------------------
# Function that computes the transition matrix of
# adaptive memory model
# INPUT:
#   rle_list: run encoding list for each agent
#   n_order: the order of the markovian model
# OUTPUT:
#   edge_list: and edge_list from state nodes composed
#   n_order from and n_order to. And the number of times
#   that a transition between each element appears
#------------------------------------------------------
getAdaptiveMemoryModel <- function(rle_list, n_order){
  #Get values and lengths for the rle_list
  values <- rle_list$values
  lengths <- rle_list$length
  
  if (length(values) <= n_order){
    diff_val <- (n_order + 1) - length(values)
    values <- c(rep(values[1], diff_val), values)
    lengths <- c(rep(2, diff_val), lengths)
  }
  
  l_n <- length(lengths)
  l_v <- length(values)
  
  #Subtrack 1 to the length in order to get the loop N
  lengths[1:(l_n - 1)] <- lengths[1:(l_n - 1)] - 1
  lengths[1] <- max(0, lengths[1] - min(lengths[1] + 1, n_order - 1))
  
  #Add inital memory states
  values <- c(rep(values[1], min(lengths[1] + 1, n_order) - 1), values)
  
  # Replicate the sequence
  rep_seq <- getReplicatedSequence(values, n_order)
  l_rep_seq <- length(rep_seq)
  
  matrix_lengths <- lengths[(n_order - (min(lengths[1] + 1, n_order) - 1)):l_n]
  
  rows <- l_rep_seq / (n_order + 1)
  
  trans_matrix <- matrix(rep_seq, nrow = rows)
  
  if (l_v > 1){
    trans_matrix <- rbind(cbind(matrix(trans_matrix[, 1:n_order], nrow = rows), matrix(trans_matrix[, 1:n_order], nrow = rows)), # Transition on the same state (Self-loop)
                          cbind(matrix(trans_matrix[rows, 2:(n_order + 1)], nrow = 1), matrix(trans_matrix[rows, 2:(n_order + 1)], nrow = 1)), # Last transition
                          cbind(matrix(trans_matrix[, 1:n_order], nrow = rows), matrix(trans_matrix[, 2:(n_order + 1)], nrow = rows))) # Transitions between different states
    
    times <- c(matrix_lengths, rep(1, rows))
    trans_matrix <- cbind(trans_matrix, times)
    
  }else{
    trans_matrix <- cbind(matrix(trans_matrix[, 1:n_order], nrow = rows),
                          matrix(trans_matrix[, 1:n_order], nrow = rows),
                          matrix_lengths + 1)
  }
  
  trans_dt <- data.table(trans_matrix)
  rm(trans_matrix)
  rm(matrix_lengths)
  rm(rep_seq)
  
  setnames(trans_dt, c(getSrcLabels(n_order), getTargetLabels(n_order), "N"))
  trans_dt <- trans_dt[, .(N = sum(.SD$N)),
                       by = c(getSrcLabels(n_order), getTargetLabels(n_order))]
  
  return(normalizeEdgeList(trans_dt[N > 0], n_order))
}
