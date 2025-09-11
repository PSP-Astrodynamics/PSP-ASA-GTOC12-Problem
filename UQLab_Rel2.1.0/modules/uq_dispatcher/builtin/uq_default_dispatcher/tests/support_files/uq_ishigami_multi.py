#!/usr/bin/env python3

import sys
import numpy as np

def ishigami(X):
    Y = np.sin(X[:,0]) + 7*np.sin(X[:,1])**2 + 0.1*(X[:,2]**4) @ np.sin(X[:,0])
    return Y

def main():

    X1 = np.loadtxt(sys.argv[-4], delimiter=',', ndmin=2)
    X2 = np.loadtxt(sys.argv[-3], delimiter=',', ndmin=2)
    X3 = np.loadtxt(sys.argv[-2], delimiter=',', ndmin=2)
    X = np.concatenate((X1,X2,X3), axis=1)
    Y = ishigami(X)
    np.savetxt(sys.argv[-1],Y,delimiter=',')

if __name__ == "__main__":
    main()
