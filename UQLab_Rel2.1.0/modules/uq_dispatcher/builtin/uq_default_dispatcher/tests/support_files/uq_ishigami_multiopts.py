#!/usr/bin/env python3

import sys
import numpy as np
import argparse


def ishigami(X):
    Y = np.sin(X[:,0]) + 7*np.sin(X[:,1])**2 + 0.1*(X[:,2]**4) @ np.sin(X[:,0])
    return Y

def main():

    # Create the parser
    my_parser = argparse.ArgumentParser(description='The Ishigami function')

    # Add the arguments
    my_parser.add_argument('-i1',
                           '--input1',
                           type=str,
                           help='input file1')
    my_parser.add_argument('-i2',
                           '--input2',
                           type=str,
                           help='input file2')
    my_parser.add_argument('-i3',
                           '--input3',
                           type=str,
                           help='input file3')
    my_parser.add_argument('-o',
                           '--output',
                           type=str,
                           help='input file')

    args = my_parser.parse_args()

    X1 = np.loadtxt(args.input1, delimiter=',', ndmin=2)
    X2 = np.loadtxt(args.input2, delimiter=',', ndmin=2)
    X3 = np.loadtxt(args.input3, delimiter=',', ndmin=2)
    X = np.concatenate((X1,X2,X3), axis=1)

    Y = ishigami(X)
    np.savetxt(args.output,Y,delimiter=',')

if __name__ == "__main__":
    main()
