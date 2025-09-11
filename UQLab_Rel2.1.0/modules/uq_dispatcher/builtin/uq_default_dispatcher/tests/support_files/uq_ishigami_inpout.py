#!/usr/bin/env python3

import sys
import numpy as np

def ishigami(X):
    Y = np.sin(X[:,0]) + 7*np.sin(X[:,1])**2 + 0.1*(X[:,2]**4) @ np.sin(X[:,0])
    return Y

def main():
    X = np.loadtxt(sys.argv[-1], delimiter=',', ndmin=2, skiprows=1)
    Y = ishigami(X)
    with open(sys.argv[-1]) as f:
        output_file = f.readline().strip()
    np.savetxt(output_file,Y,delimiter=',')

if __name__ == "__main__":
    main()
