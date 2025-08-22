function [ c ] = coVertex( v,n)
%coVertex return the correspondences vertex of the origin set of vertex

    [col,row] = myDivide(v,n);
    c = vertex(col,row,n);

end

