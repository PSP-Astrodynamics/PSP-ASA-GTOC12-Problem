#include <iostream> // for terminal output
#include <string> 
#include <fstream> // for file operations
#include <cstdlib> // for exit()
#include <sstream> // for stringstream
#include <cstring> // for strlen()

using namespace std;

// C++ implementation of the simply supported beam example from UQLAB: uq_SimplySupportedBeam()
//
// UQ_SIMPLYSUPPORTEDBEAM computes the midspan deflection of a simply supported beam under uniform loading
//%   Model with five input parameters  X= [b h L E p]
//%         b:   beam width
//%         h:   beam height
//%         L:   beam span
//%         E:   Young's modulus
//%         p:   uniform load
//%
//%   Output:  V = (5/32)*pL^4/(E*b*h^3)
//% 
//% See also: UQ_EXAMPLE_PCE_03_SIMPLYSUPPORTEDBEAM/


int main(int argc, char* argv[]) {

	// If input filename not given on command line
	if(argc < 3){
		cout << "Usage: " << argv[0] << " <input filename> <output filename>" << endl;
		cout << "Exiting..." << endl;
		exit(EXIT_FAILURE);
	}
	
	// Filenames given as a command line argument
	char* inputfilename = argv[1];
    char* outputfilename = argv[2];

	cout << "Input filename supplied on terminal : " << inputfilename << endl;
    cout << "Output filename supplied on terminal: " << outputfilename << endl;

	// Variables to be read
	double params[5];
    double beam_width;
	double beam_height;
	double beam_span;
	double youngs_modulus;
	double load;

	// Reading from input file
	ifstream inputfile(inputfilename);
	if(inputfile.is_open()){
        string line;
        getline(inputfile, line); // skip first line
        for(int p = 0; p < 5; ++p){ 
            getline(inputfile, line);
            istringstream iss(line);
            iss >> params[p];
    		if(iss.fail()){
    			cout << "Error while reading line " << p+1 << " from file " << inputfilename << "! Exiting..." << endl;
    			exit(EXIT_FAILURE);
    		}
        }
        beam_width = params[0];
        beam_height = params[1];
        beam_span = params[2];
        youngs_modulus = params[3];
        load = params[4];

		inputfile.close();
	} else {
		cout << "Error: Input file " << inputfilename << " not found! Exiting..." << endl;
		exit(EXIT_FAILURE);
	}

	cout << "Beam width      = " << beam_width << endl;
	cout << "Beam height     = " << beam_height << endl;
	cout << "Beam span       = " << beam_span << endl;
	cout << "Young's modulus = " << youngs_modulus << endl;
	cout << "Uniform load    = " << load << endl;

	// Compute midspan deflection
	double V = 5./32. * load * beam_span * beam_span * beam_span * beam_span / (youngs_modulus * beam_width * beam_height * beam_height * beam_height); 
	cout << endl << "Midspan deflection = " << V << endl;


	// Writing to the output file
	ofstream outputfile(outputfilename); 
	if (outputfile.is_open()){
		outputfile << V << endl;
		outputfile.close();
	} else {
		cout << "Error while opening output file " << outputfilename << "! Exiting..." << endl;
		exit(EXIT_FAILURE);
	}
	


	return 0;
}
