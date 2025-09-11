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
    my_parser.add_argument('-i',
                           '--input',
                           type=str,
                           help='input file')
    my_parser.add_argument('-o',
                           '--output',
                           type=str,
                           help='input file')

    # Execute the parse_args() method
    args = my_parser.parse_args()
    input_file = args.input
    output_file = args.output

    X = np.loadtxt(input_file, delimiter=',', ndmin=2)
    Y = ishigami(X)
    np.savetxt(output_file, Y, delimiter=',')


if __name__ == "__main__":
    main()
