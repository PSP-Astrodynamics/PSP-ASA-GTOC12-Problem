DATASET DESCRIPTION:
--------------------

Origin/references:
--------------------------
  Origin:
    Fisher's iris data consists of measurements on the sepal length, sepal 
    width, petal length, and petal width for 150 iris specimens. 
    The raw data set is available within matlab by:
    load fisheriris
  
  References:
    Fisher,R.A. (1936). The use of multiple measurements in taxonomic problems.
    Annual Eugenics, 7, Part II, 179-188.

Dataset description:
--------------------------
  The Fisher iris dataset is commonly used in the pattern recognition literature.
  The original dataset contains 3 classes of 50 instances each, where each class refers 
  to a type of iris plant. One class is linearly separable from the other 2; 
  the latter are not linearly separable from each other. NOTE: the pre-processed 
  version that is provided here only contains two classes (the setosa species 
  have  been removed). 
  
  Instead of 4 inputs that exist in the original dataset, only 2 are considered in this 
  reduced version (sepal length and sepal width) for better visualisation of the results. 

Description of inputs and outputs (ordered as provided in the dataset)
---------------------------
  Fisher_iris_reduced.mat:
  X             : Sepal length and sepal width of each sample (M=2, N=100)
  Y             : The specie class (-1: virginica, 1: versicolor)

  
