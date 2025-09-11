#!/usr/bin/env python3

import sys
import numpy as np

def ishigami(X):
    Y = np.sin(X[:,0]) + 7*np.sin(X[:,1])**2 + 0.1*(X[:,2]**4) @ np.sin(X[:,0])
    return Y.reshape((X.shape[0],1))

def main():
    X = np.loadtxt(sys.argv[-2], delimiter=',', ndmin=2)
    Y1 = ishigami(X)
    Y2 = 100*X[:,0]**3
    Y2 = Y2.reshape((1,1))
    Y3 = Y1;
    np.savetxt(sys.argv[-1],np.hstack((Y1,Y2,Y3)),delimiter=',')

if __name__ == "__main__":
    main()
