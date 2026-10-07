function [hannFunc] = generateNDHannBorder(matDims,borderRad)
%GENERATENDHANNBORDER Takes in matrix dimensions and returns a 2D or 3D 
%matrix of ones with a border scaled by the Hann function

%% UNFINISHED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Generate Hann function of bordered values
hannFunc = generateNDHann(repmat(2*borderRad,[numel(matDims),1]));

hannFuncBordered = ones(matDims);
cornerBounds = {1:borderRad, (matDims(1)-borderRad+1):matDims(1), 1:borderRad, (matDims(2)-borderRad+1):matDims(2)};
quadInds = zero(4, borderRad^2);
if numel(matDims) == 2

    for currQuad = 1:4

        rowInd = mod(currQuad + 1, 2) + 1;
        colInd = ceil(currQuad/2) + 2;
        quadInds = sub2ind(matDims, cornerBounds{rowInd}, cornerBounds{colInd});
    end

    [rowMat, colMat] = ndgrid(1:(2*borderRad), 1:(2*borderRad));
    quad1 = sub2ind(matDims,1:borderRad,1:borderRad);
    quad2 = sub2ind(matDims,1:borderRad,(matDims(2)-borderRad+1):matDims(2));
    quad3 = sub2ind(matDims,(matDims(1)-borderRad+1):matDims(1),1:borderRad);
    quad4 = sub2ind(matDims,(matDims(1)-borderRad+1):matDims(1),(matDims(2)-borderRad+1):matDims(2));
else
    [rowMat, colMat, depthMat] = ndgrid(1:(2*borderRad), 1:(2*borderRad), 1:(2*borderRad));
    quad1 = sub2ind(matDims,1:borderRad,1:borderRad,1:borderRad);
    quad2 = sub2ind(matDims,1:borderRad,(borderRad+1):(2*borderRad),1:borderRad);
    quad3 = sub2ind(matDims,(borderRad+1):(2*borderRad),1:borderRad,1:borderRad);
    quad4 = sub2ind(matDims,(borderRad+1):(2*borderRad),(borderRad+1):(2*borderRad),1:borderRad);
    quad5 = sub2ind(matDims,1:borderRad,1:borderRad,(borderRad+1):(2*borderRad));
    quad6 = sub2ind(matDims,1:borderRad,(borderRad+1):(2*borderRad),1:borderRad,(borderRad+1):(2*borderRad));
    quad7 = sub2ind(matDims,(borderRad+1):(2*borderRad),1:borderRad,1:borderRad,(borderRad+1):(2*borderRad));
    quad8 = sub2ind(matDims,(borderRad+1):(2*borderRad),(borderRad+1):(2*borderRad),1:borderRad,(borderRad+1):(2*borderRad));
end


quad1 = sub2ind(matDims,1:borderRad,1:borderRad);
quad1 = sub2ind(matDims,1:borderRad,1:borderRad);
quad1 = sub2ind(matDims,1:borderRad,1:borderRad);
quad1 = sub2ind(matDims,1:borderRad,1:borderRad);

if numel(matDims) == 2
    hannFunc = vec1.*vec2';
else
    vec3 = hann(matDims(3));
    hannFunc = vec1.*vec2'.*permute(vec3,[3 2 1]);
end

end

