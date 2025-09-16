function Moments = uq_triangular_PtoM( Parameters )
% Moments = UQ_TRIANGULAR_PTOM(Parameters) returns the values of the
% first two moments (mean and standard deviation) of a triangular 
% distribution based on the specified parameters

if length(Parameters) ~= 3
   error('There are exactly 3 parameters required for defining a triangular distribution!') 
end
a = Parameters(1);
b = Parameters(2);
c = Parameters(3);


%% Mean
M1=(a+b+c)/3;

%% Standard deviation
M2=(a.^2+b.^2+c.^2-a.*b-a.*c-b.*c)/18;
M2 = sqrt(M2);

Moments = [M1, M2];
