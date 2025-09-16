function K = uq_matlab_kernel_wrapper(X1,X2)
global matlab_theta matlab_kernelOpts
theta = matlab_theta ;
KernelOptions = matlab_kernelOpts ;
evalK_handle = KernelOptions.Handle ;

K = evalK_handle(X1,X2,theta, KernelOptions) ;
end