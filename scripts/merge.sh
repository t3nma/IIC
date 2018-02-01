#!/bin/bash

# edit metric files
sed -i '1s/.*/Betweenness Centrality/' betweenness.csv
sed -i '1s/.*/Closeness Centrality/' closeness.csv

# merge metric files to Nodes.csv
paste -d";" Nodes.csv betweenness.csv | while read str; do echo "${str}" >> tmp.csv; done

paste -d";" tmp.csv closeness.csv | while read str; do echo "${str}" >> tmp2.csv; done

mv tmp2.csv Nodes.csv
rm -f tmp.csv
rm -f tmp2.csv

