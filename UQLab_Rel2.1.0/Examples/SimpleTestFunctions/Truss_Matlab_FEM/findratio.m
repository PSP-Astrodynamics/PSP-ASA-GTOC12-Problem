function r = findratio(d0, L, N)
  
  optimset.Display = 'off';
  
  % MMC version
  optimset.TolX=1e-7;
  
  opti = optimset;
  if (abs(d0 - L/N) < 1e-8)
	r=1;
  else 
	if (d0 > L/N)
	  intv = [0 0.9999];
	else 
	  intv = [1.0001 3];
  end
  %	Syntax 5.2
  %r = fzero('RatioEqn' , intv,[],[],d0, L, N);
  %	Syntax 5.3
  %r = fzero('RatioEqn' , intv,opti,d0, L, N);
  %	MMC version
  %r = fzero('RatioEqn' , intv,opti,d0, L, N);
  x0 = 0.5*(intv(1)+intv(2)) ;
  r = fzero(@(x) RatioEqn(x, d0, L, N), x0, opti) ;
  %fzero(@(x) myfunc(x,2.0), 1.0)
end
