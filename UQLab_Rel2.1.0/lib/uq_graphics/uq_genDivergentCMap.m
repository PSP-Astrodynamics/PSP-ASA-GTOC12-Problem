function cc = uq_genDivergentCMap(C1,C2,m)

if ~exist('C1','var') || ~exist('C2','var')
    error('Both colors of the divergent colormap need to be specified!')
end

if ~exist('m','var') , m = 256; end

% Divergent colormap!
RR=[C1(1) 255 C2(1)]/255;
GG=[C1(2) 255 C2(2)]/255;
BB=[C1(3) 255 C2(3)]/255;
xx=linspace(0,1,length(RR));

% Interpolate the requested colors
xint=linspace(0,1,m);
rr = interp1(xx,RR,xint);
gg = interp1(xx,GG,xint);
bb = interp1(xx,BB,xint);

% Return the RGB triplet
cc = [rr.' gg.' bb.']; 