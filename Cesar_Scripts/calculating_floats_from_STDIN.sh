#!/bin/bash
read math
printf "%.3f\n" $(echo "$math" | bc -l)
# % --> insert a string .{x}f specify the amount of float residual range bc --> calculator