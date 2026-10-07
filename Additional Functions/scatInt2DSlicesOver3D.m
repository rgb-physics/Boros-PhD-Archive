function [outInterp] = scatInt2DSlicesOver3D(inMat,logicMat)
%SCATINT2DSLICESOVER3D Uses a scattered interpolant object to fill in
%indices of inMat stored in logicMat. If logicMat is not passed, it is
%generated and defined as set of all zeros in inMat.

%Define logic mat if not passed
if nargin == 1
    logicMat = inMat == 0;
end
%Instantiate permuted matrix and storage matrices
orthMat = permute(inMat, [2 1 3]);
orthLogic = permute(logicMat, [2,1,3]);
storeMat1 = zeros(size(inMat));
storeMat2 = zeros(size(orthMat));
%Iterate over slices, interpolate, and store
for rInd = 1:max(size(inMat,[1,2]))
        
    if rInd <= size(inMat,1)
        currSlice = squeeze(inMat(rInd, :,:));
        currLogic = squeeze(logicMat(rInd, :,:));
        storeMat1(rInd,:,:) = fillin2D(currSlice,currLogic);
    end
    if rInd <= size(orthMat,1)
        currSlice = squeeze(orthMat(rInd, :,:));
        currLogic = squeeze(orthLogic(rInd, :,:));
        storeMat2(rInd,:,:) = fillin2D(currSlice,currLogic);
    end
end
%Permute second store matrix again
storeMat2 = permute(storeMat2, [2 1 3]);
%Take average of two matrices
outInterp = (storeMat1 + storeMat2)/2;

end

