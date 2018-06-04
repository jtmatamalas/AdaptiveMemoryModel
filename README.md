# AdaptiveMemoryModel

This script provides a way to build the models used in [^1], either markovian or adaptive memory model of any order [^2].

## Requirements

The software is written in R and it uses the following packages:

- data.table
- plyr
- docopt

If you want to run it using multi core capabilities, the execution requires the use of the package doMC.

To install the required packages make use of the following instruction.

```R
install.packages("data.table", "plyr", "docopt", "doMC")
```
[^1]: Matamalas, Joan T., Manlio De Domenico, and Alex Arenas. "Assessing reliable human mobility patterns from higher order memory in mobile communications." Journal of The Royal Society Interface 13.121 (2016): 20160203.

[^2]: In the case of the adaptive memory model, the order has to be at least 2.
