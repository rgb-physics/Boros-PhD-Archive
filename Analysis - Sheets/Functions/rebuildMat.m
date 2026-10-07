
% Additional function
% 2025-08-01
% Rémi Boros
function [outMat] = rebuildMat(inVerts,segVoxSize,segSize,dskStrel,pivMatSize)
        filtVcut = round(inVerts);
        vInds = sub2ind(round(segVoxSize.*segSize),filtVcut(:,2),filtVcut(:,1),filtVcut(:,3));
        imgMat = consMatLnB(ones(pivMatSize),vInds);
        % images will typically have artifacts from grid
        outMat = imerode(imdilate(imgMat,dskStrel),dskStrel);
end

