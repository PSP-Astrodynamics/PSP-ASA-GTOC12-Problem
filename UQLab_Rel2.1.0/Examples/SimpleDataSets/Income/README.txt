DATASET DESCRIPTION:
--------------------
 
Origin/references:
--------------------------
  Origin:
    The census income dataset Î¿riginates from Kohavi 1996 and is 
    publicly available at the UCI machine learning repository: https://archive.ics.uci.edu/ml/.
    It is also known as the "Adult" dataset. It originates from weighted census data extracted
    from the 1994 and 1995 Current Population Surveys conducted by the U.S. Census Bureau.     
  
  References:
    Kohavi, R. (1996). Scaling Up the Accuracy of Naive-Bayes Classifiers: a Decision-Tree Hybrid, 
    Proceedings of the Second International Conference on Knowledge Discovery and Data Mining.
    
    https://archive.ics.uci.edu/ml/datasets/Census+Income

Dataset description:
--------------------------
  The input variables are related to attributes of a person (e.g. age, marital status, occupation). The raw 
  samples contain both categorical and real-valued inputs. The pre-processed dataset contains binary valued inputs
  that "encode" the values of categorical variables using the one-hot-encoding method. In addition, the raw samples
  that contain missing values have been removed. 
 
  The output of interest is binary value related a person's yearly salary, 
  -1 corresponding to <50k per year and 1 to >50k per year. 
 
Description of inputs and outputs (ordered as provided in the dataset)
---------------------------
  adult.mat:
  X             : A set of N=30,162 samples of M=104 real-valued and binary input variables
  Y             : The binary value associated to the person's income
  

