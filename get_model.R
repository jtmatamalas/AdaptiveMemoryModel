require(data.table)
require(plyr)
require(docopt)
source("src/Utils.R")
source("src/Models.R")

# Get Parameters
"
Usage:  
get_model (--adaptive | --markovian) --order <order> --input <input> --output <output> [--cores <num_cores> --minimum_events <events>]
get_model (-h | --help)

Description:  A program that construct either Markovian or Adaptive Memory models of a given order
Options:
  -h --help                             Show this screen.
  -i <input>, --input <input>           Three column input CSV FILE in the form of (agent id, timestamp, location id).
  -o <output>, --output <output>        Output file where to store the model.
  -a, --adaptive                        Adaptive memory model.
  -m, --markovian                       Markovian model.
  -n <order>, --order <order>           Order of the model.
  -c <num_cores>, --cores <num_cores>   Number of CPU cores used to compute the model [default: 1]
  --minimum_events <events>             Minimum number of evets to consider [default: 100]
" -> doc

opts <- docopt(doc)

input_filename <- opts$input
output_filename <- opts$output

order <- opts$order
if (!is.na(as.numeric(order))){
  order <- as.numeric(order)
}else{
  message("Order must be a number.")
  return(-1)
}

num_cores <- opts$cores
if (!is.na(as.numeric(num_cores))){
  num_cores <- as.numeric(num_cores)
}else{
  message("Cores must be a number.")
  return(-1)
}

min_events <- opts$"--minimum_events"
if (!is.na(as.numeric(min_events))){
  min_events <- as.numeric(min_events)
}else{
  message("the number of miniumum events must be a number.")
  return(-1)
}

parallel <- ifelse(num_cores > 1, T, F)

if (parallel){
  require(doMC)
  doMC::registerDoMC(cores = num_cores)
}

model <- ifelse(opts$adaptive, "adaptive", "markov")

edgelist <- compute_model(input_filename, model, order, parallel, min_events)

write.table(edgelist, output_filename, row.names = F, sep = ',')
