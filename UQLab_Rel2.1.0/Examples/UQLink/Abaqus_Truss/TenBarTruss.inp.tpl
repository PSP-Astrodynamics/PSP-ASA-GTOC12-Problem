*************************************************
**
** UUQLAB referred HEADER HERE
** following the 3 bar truss example
** provided by James R. Rice
**
** last modified: 01/11/2017
** by: 
**
*************************************************
**
** brief description:
**
** A TrussExample.inp File for an ABAQUS Finite
** Element Solution
**
** Double astericks (at left) indicate a comment
** All such comments are ignored by the computer
** They are inserted for clarity only
**
**
*************************************************
**
** heading information
**
*************************************************
**
*HEADING
 Ten Bar Truss: Ref here
**
** the HEADING title (Three Bar...) will appear
** on any output files created by ABAQUS
**
** Note on capitalization: In general, you do
** not have to worry about case in input files.
** The exception is with the use of parameters,
** (not used in this file); parameter names are
** case sensitive.
**
*************************************************
**
** Parameter Definitions
**
*************************************************
**
*PARAMETER
 E = 1e7
 Load = -100000
 **
** E: Young's Modulus
** Load: concentrated load to be applied
**
** Note on Units: ABAQUS does not have a built-in
** system of units. All input data must be
** specified in consistent units. The units used
** here would be consistent for Steel with
** forces in lbf, and lengths in in.
**
*************************************************
**
** Node definitions
**
*************************************************
**
** The next statements give the locations of
** nodal points, corresponding in this example
** to the "joints" of the truss system. First
** entry is node number, and the next are its
** x1, x2, x3 coordinates.
**
*NODE
1,    0.0,    0.0
2,    0.0, -360.0
3, -360.0,    0.0
4, -360.0, -360.0
5, -720.0,    0.0
6, -720.0, -360.0
**
***********************************************
**
** Element Definitions
**
**********************************************
**
** Next, the elements (corresponding to truss
** bars in this case) are defined. Also, the
** type of element, from the element library
** available within ABAQUS, is defined. The
** first number shown is the element number,
** and the next two are the two nodes which
** that element joins. The set of elements is
** given the name "BARS." Note that this is a
** 2D element type (T2D2); for 3D analyses, use
** T3D2.
** Each bar is defined separately since their
** section areas will be modified independently
** within the uncertainty quantifiacation analysis
**
*ELEMENT, TYPE=T2D2, ELSET=BAR1
1,  1, 2
*ELEMENT, TYPE=T2D2, ELSET=BAR2
2,  1, 3
*ELEMENT, TYPE=T2D2, ELSET=BAR3
3,  1, 4
*ELEMENT, TYPE=T2D2, ELSET=BAR4
4,  2, 3
*ELEMENT, TYPE=T2D2, ELSET=BAR5
5,  2, 4
*ELEMENT, TYPE=T2D2, ELSET=BAR6
6,  3, 4
*ELEMENT, TYPE=T2D2, ELSET=BAR7
7,  3, 5
*ELEMENT, TYPE=T2D2, ELSET=BAR8
8,  3, 6
*ELEMENT, TYPE=T2D2, ELSET=BAR9
9,  4, 5
*ELEMENT, TYPE=T2D2, ELSET=BAR10
10, 4, 6
**
***********************************************
**
** Material Definitions
**
***********************************************
**
** We now describe properties of the material,
** beginning with the cross section area (0.1)
** and Young's modulus E (30.E6), in the units
** adopted. The Poisson ratio nu is irrelevant
** here.
** Each section is defined independently
*SOLID SECTION, ELSET=BAR1, MATERIAL=MAT1
<X0001>
*SOLID SECTION, ELSET=BAR2, MATERIAL=MAT1
<X0002>
*SOLID SECTION, ELSET=BAR3, MATERIAL=MAT1
<X0003>
*SOLID SECTION, ELSET=BAR4, MATERIAL=MAT1
<X0004>
*SOLID SECTION, ELSET=BAR5, MATERIAL=MAT1
<X0005>
*SOLID SECTION, ELSET=BAR6, MATERIAL=MAT1
<X0006>
*SOLID SECTION, ELSET=BAR7, MATERIAL=MAT1
<X0007>
*SOLID SECTION, ELSET=BAR8, MATERIAL=MAT1
<X0008>
*SOLID SECTION, ELSET=BAR9, MATERIAL=MAT1
<X0009>
*SOLID SECTION, ELSET=BAR10, MATERIAL=MAT1
<X0010>
*MATERIAL, NAME=MAT1
*ELASTIC
 <E>
**
**********************************************
**
** Boundary Conditions
**
**********************************************
**
** Next, come statements about fixed boundary
** points. The node number is given first, and
** then the first and last degree of freedom
** that is restrained at the node -- displacements
** U1, U2, and U3 are zero in this case. It was
** not really necessary to mention U3, since
** the problem is set up as 2D
**
*BOUNDARY
 5, 1, 3
 6, 1, 3
**
**********************************************
**
** Step 1: apply concentrated load
**
**********************************************
**
** Now we describe the loading, in this case
** as a single "step." Since this involves
** linear elastic material and we are content
** to neglect any effects of geometry change,
** due to deformation, on the writing of the
** equilibrium equations, our problem is a
** completely linear one.
**
** We indicate that the PERTURBATION procedure
** be followed to indicate that this is a linear
** perturbation step. (See discussion in "General
** and linear perturbation procedures," section
** 6.1.2 of the ABAQUS Analysis User's Manual)
**
**
*STEP, NAME=STEP-1, PERTURBATION
*STATIC
**
**********************************************
**
** Loads
**
**********************************************
**
** The following specifies that a concentrated
** load, <Load>, which was defined above as
** -10000 in the units adopted, is applied in
** the x2 direction at node 4 (i.e., 10000 is
** applied in the negative x2 direction).
**
*CLOAD
 2, 2, <Load>
 4, 2, <Load>
**
***********************************************
**
** OUTPUT REQUESTS
**
** Note about output: For large analyses, it is
** important to consider output requests carefully,
** as they can create very large files.
**
***********************************************
**
** The following option is used to write output
** to the output database file ( for plotting in
** ABAQUS/Viewer)
**
*OUTPUT, FIELD, VARIABLE=PRESELECT
**
** The following options are used to provide tabular
** printed output of element and nodal variables to
** the data and results files
**
*NODE PRINT
 U, COORD
**
************************************************
**
** End Step
**
************************************************
**
** The final statement tells ABAQUS that loading
** step is over.
**
*END STEP