# AdaptiveMemoryModel

This script provides a way to build the models used in<sup id="ref1">[1]</sup>, either markovian or adaptive memory model of any order. 

## Requirements

### Packages

The software is written in R and it uses the following packages:
- data.table
- plyr
- docopt

If you want to run it using multi core capabilities, the execution requires the use of the package doMC.

To install the required packages make use of the following instruction.

```R
install.packages("data.table", "plyr", "docopt", "doMC")
```

### Input file

The input file must be provided in CSV format and it must contain records of the position of an agent or multiple agents over time. It has to be composed by the following columns:
- **agentId**: The id of the agent who has generated the record. 
- **timestamp**: information about the moment when the position has been recorded. Any sortable format will work.
- **localizationId**: id of the location.

## Usage

The call to the script has to fulfill the following format:
```bash
Rscript get_model.R (--adaptive | --markovian) --order <order> --input <input> --output <output> [--cores <num_cores> --minimum_events <events>]
```
### Parameters
```
  -h --help                             Show this screen.
  -i <input>, --input <input>           Three column input CSV FILE in the form of (agent id, timestamp, location id).
  -o <output>, --output <output>        Output file where to store the model.
  -a, --adaptive                        Adaptive memory model.
  -m, --markovian                       Markovian model.
  -n <order>, --order <order>           Order of the model.
  -c <num_cores>, --cores <num_cores>   Number of CPU cores used to compute the model [default: 1]
  --minimum_events <events>             Minimum number of evets to consider [default: <order> + 1]
```
### Output

The output of the execution will be stored in the in a CSV file with the following format:
- **The first _norder_ columns**: contain the encoding of the source following the format described in<sup id="ref1">[1]</sup>.
- **The next _norder_ columns**: contain the encoding of the destination following the format described in<sup id="ref1">[1]</sup>.
- **Transition probability**: the last column contain the transition from source to destination.

### Example

As an example of the usage, let's consider the following command to generate an adaptive memory model of second order using the data stored in *test/data.csv* and store the results in a file called test.csv:
```bash
Rscript get_model.R -i test/data.csv -o test.csv -a -n 2
```

## References
1. <small id="ref1">Matamalas, Joan T., Manlio De Domenico, and Alex Arenas. "Assessing reliable human mobility patterns from higher order memory in mobile communications." Journal of The Royal Society Interface 13.121 (2016): 20160203.</small>
