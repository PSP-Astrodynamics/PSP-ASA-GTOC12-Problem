function  varargout = plot_output(ID,COORD, CONEC,U,MAGN,varargin)

%      plot_output(ID,COORD, CONEC,U,MAGN)
%    
%      Plot the mesh and the deformed shape 
%      
%      ID   : figure number
%      COORD: mesh nodal coordinates
%      CONEC: mesh connectivity table
%      U    : displacement vector
%      MAGN : magnitude factor for deformed shape
%             use 0 for automatic selection
%    	 
	
[NbNodes , DdlPerNode] =  size(COORD);
[NbElts , NodePerElt ] =  size(CONEC);

% figure(ID);
% 
% clf;

subplot(1,2,1)

% Find boundaries of the mesh and select zooming on the structure
xmin = min(COORD(:,1));
xmax = max(COORD(:,1));
ymin = min(COORD(:,2));
ymax = max(COORD(:,2));
MeshMaxSize = max((xmax-xmin) , (ymax -ymin));
set(gca,'Xlim', [xmin-0.15*MeshMaxSize , xmax + 0.15 * MeshMaxSize]);
set(gca,'Ylim', [ymin-0.15*MeshMaxSize , ymax + 0.15 * MeshMaxSize]);
set(gca,'DataAspectRatio', [1 1 1]);

% Plot original structure

for elnum = 1 : NbElts
  for node = 1 : NodePerElt
	theCoords(node , : ) = COORD(CONEC(elnum,node) , :);
  end;
  theCoords(NodePerElt + 1 , : ) = theCoords(1 , : ) ;% close the quadrangle
  if (nnz(U) ~=0)
     TheStyle= '--';
  else
     TheStyle = '-';
     end
%   line(theCoords(: ,1 ) , theCoords(: ,2 ), 'color' , 'b', 'LineStyle' , TheStyle);
line(theCoords(: ,1 ) , theCoords(: ,2 ), 'color' , 'k', 'LineStyle' , '-');
end;

% if (nnz(U) ~=0) 
%   if (MAGN == 0)
% 	% Compute automatically magnification facto for displacement field
% 	% and grapfical deformed shape
% 	MaxDisp = max(abs(U));
% 	MAGN =  (0.1 * MeshMaxSize) /MaxDisp ;
%   end;
%  MAGN = 75 ;

% Plot deformed shape
%   DeformedShape = COORD + reshape(U, 2 , NbNodes)' * MAGN ; 
%   for elnum = 1 : NbElts
% 	for node = 1 : NodePerElt
% 	  theCoords(node , : ) = DeformedShape(CONEC(elnum,node) , :);
% 	end;
% 	theCoords(NodePerElt + 1 , : ) = theCoords(1 , : ) ;% close the quadrangle
% %     line(theCoords(: ,1 ) , theCoords(: ,2 ), 'color' , 'r');
% 	line(theCoords(: ,1 ) , theCoords(: ,2 ), 'color' , 'k');
%   end
% end
hold off;


% Return deformed shape coordinates
if nargout==1
    varargout{1} = DeformedShape ;
end;

