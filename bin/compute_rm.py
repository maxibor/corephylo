#!/usr/bin/env python

import sys

def compute_rm(cfml, basename):
    p = dict()
    with open(cfml, 'r') as f:
        next(f)
        for line in f:
            print(line)
            line = line.strip().split('\t')
            param = line[0]
            mean = line[1]
            p[param] = float(mean)
    print(p)
    rm = p['R/theta'] * 1/p['1/delta'] * p['nu']
    with open(f"{basename}_rm.tsv", 'w') as f:
        f.write("# CFML estimated r/m\n")
        f.write(f"# r/m = (R/theta) x delta x nu\n")
        f.write(str(rm))

if __name__ == '__main__':
    print(sys.argv[1])
    compute_rm(cfml = sys.argv[1], basename=sys.argv[2])
