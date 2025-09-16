function Parameters = uq_uniform_MtoP( Moments )
% Parameters = UQ_UNIFORM_MTOP(Moments) returns the 
% value of the parameters of a uniform distribution based on
% its mean and standard deviation
   
mu = Moments(1);
sigma = Moments(2);

a = mu - sqrt(3)*sigma ;
b = mu + sqrt(3)*sigma ;
                    

Parameters = [a b] ;

