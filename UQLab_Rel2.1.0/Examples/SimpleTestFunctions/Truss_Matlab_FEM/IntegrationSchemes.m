function t = IntegrationSchemes()
%
%     Compute the Gauss and Hammer points coordinates
%     and associated weights for numerical integration
%
%     The integration schemes are stored in a cell array, each cell
%     containing the following information :
%
%     dim   : dimension of the mutilfold integration (e.g 1 or 2)
%     size  : number of integration points
%     pts   : array of size (size * dim) containing the Gauss points
%             coordinates  
%     wgh   : array of length 'size' containing the associated weights 
  
  NumberOfSchemes = 2 ;
  t = cell(NumberOfSchemes);
  
%%------------------------------------------------------------%%
%     Two-dimensional 2*2 Gauss Integration for quadrangles
%%------------------------------------------------------------%%

  t{1}.dim = 2 ;
  t{1}.size = 4 ;
  sq3 = 1/sqrt(3);
  t{1}.pts(1 , :) = [ -sq3 , -sq3];
  t{1}.pts(2 , :) = [ -sq3 ,  sq3];
  t{1}.pts(3 , :) = [  sq3 , -sq3];
  t{1}.pts(4 , :) = [  sq3 , sq3];
  t{1}.wgh = ones([1 ,4]);
  
%%------------------------------------------------------------%%
%     Two-dimensional 3*3 Gauss Integration for quadrangles
%%------------------------------------------------------------%%
%     One-dimensional weights are :
%              8/9 for x =0.
%              5/9 for x =sqrt(0.6)
%
%     Two-dimensional weights are products of the latter


  t{2}.dim = 2 ;
  t{2}.size = 9 ;
  sqsix = sqrt(0.6) ; 
  t{2}.pts(1 , :) = [ -sqsix , -sqsix];
  t{2}.pts(2 , :) = [ -sqsix ,    0  ];
  t{2}.pts(3 , :) = [ -sqsix ,  sqsix];
  t{2}.pts(4 , :) = [    0   , -sqsix];
  t{2}.pts(5 , :) = [    0   ,    0  ];
  t{2}.pts(6 , :) = [    0   ,  sqsix];
  t{2}.pts(7 , :) = [  sqsix , -sqsix];
  t{2}.pts(8 , :) = [  sqsix ,    0  ];
  t{2}.pts(9 , :) = [  sqsix ,  sqsix];
  
  for  i = 1 : 4
	t{2}.wgh(2*i)   = 40. /81. ; 
  end;
  for  i = 1 : 5
	t{2}.wgh(2*i - 1)   = 25. /81.  ; 
  end;
  t{2}.wgh(5) = 64. / 81. ;
