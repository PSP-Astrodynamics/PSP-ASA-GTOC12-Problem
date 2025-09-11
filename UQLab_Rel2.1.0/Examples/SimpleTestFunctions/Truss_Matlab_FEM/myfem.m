function U = myfem(Model)
  
%%------------------------------------------------------------%%
%     Computing the data for numerical integration
%%------------------------------------------------------------%%


%%------------------------------------------------------------%%
%     Assembling
%%------------------------------------------------------------%%
%fprintf('\n  * Assembling the global stiffness matrix :\n      ');
[ StifMatrix , EltForce ] = assemble(Model);



%fprintf('       took %6.2f seconds', t);
% add the prescribed nodal loads
LOADS = Model.LOADS ;
EltForce = reshape(LOADS',Model.Nddl,1) + EltForce;    
                                                       

%%------------------------------------------------------------%%
%     Taking into account boundary conditions
%
%     !!!!!! Limited to zero imposed displacements so far
%%------------------------------------------------------------%%
%fprintf('\n  * Imposing the boundary conditions');
[StifMatrix , EltForce]  = ...
	boundary_conditions(StifMatrix, EltForce,Model.BC);

%%------------------------------------------------------------%%
%     Resolution
%%------------------------------------------------------------%%
%fprintf('\n  * Solving the linear system');

%tic;
U = StifMatrix \ EltForce ;
%fprintf('\n    Total time for analysis :%6.2f seconds\n',t);

%plot_output(1,Model.COORD, Model.CONEC,U,0)
%print_output(1,'Disp',U);

