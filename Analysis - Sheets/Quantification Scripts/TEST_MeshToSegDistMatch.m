% This script takes in segmentations/probability fields and queries the 
% distances of all points above a threshold probability to the nearest
% barycenter of faces corresponding to a mesh of the bounding surface of
% said segmentation. Used for relating curvature of mesh to intensity in
% segmentation

% segDir = '<redacted original absolute path>';
segDir = 'Session 28, Exp 6';
segName = 'Time%06i_regionsStruct.mat';
segFields = {'bot', 'top'};
% plyDir = '<redacted original absolute path>';
plyDir = 'Session 28, Exp 6';
plySubs = {'Bot Layer', 'Top Layer'};
plyName = '%sDataStoreStructT%03i.mat';

% imgDir = '<redacted original absolute path>';
imgDir = 'Session 28, Exp 6';
imgName = 't%03i_illCorr8bit.tif';
selectTimes = 150;

%% Load data structures
load(fullfile(plyDir, plySubs{1}, sprintf(plyName,segFields{1},selectTimes(1))),'currStruct');
load(fullfile(segDir, sprintf(segName, selectTimes(1))));
% filtSeg = 
currTif = tiffreadVolume(fullfile(imgDir, sprintf(imgName, selectTimes(1))));

%% Isolate segmentation and vertices of interest
filtSeg = outputStruct.botInds;
meshVerts = currStruct.bcs;
% vertsInMat = mesh2mat(mesh.v, size(filtSeg));

%% Assign nearest mesh point to each point in segmentation
[xCoords, yCoords, zCoords] = ind2sub(size(filtSeg), find(filtSeg));
tic
meshSegConn = dsearchn( meshVerts, [xCoords, yCoords, zCoords]);
% meshSegConn = dsearchn([xCoords, yCoords, zCoords], meshVerts);
toc
% Consider running on 8x  by 8x subselection of points

%% 
% save(fullfile('<redacted original absolute path>','t150_meshSegConnectivity.mat'),'meshSegConn','filtSeg','meshVerts');
save(fullfile('Session 28, Exp 6','t150_meshSegConnectivity.mat'),'meshSegConn','filtSeg','meshVerts');

%% Plot 
outVol = zeros(size(filtSeg));

outVol(filtSeg) = meshSegConn;

% validVerts = meshVerts;
% for currDim = 1:size(meshVerts,2)
%     validVerts(:,currDim) = max(min(validVerts(:,currDim),size(filtSeg,currDim)),0);
% end
% finalVerts = round(validVerts(min(round(validVerts),[],2) > 0,:));
% 
% validInds = sub2ind(size(outVol), finalVerts(:,1), finalVerts(:,2), finalVerts(:,3));
% outVol(validInds) = meshSegConn(min(round(validVerts),[],2) > 0);

%% Plot curvature vs. binned intensity
figure
meshCurves = currStruct.curvV
for currInd = 1:size(meshVerts,3)
    scatter()
end

%% Permute vectors and select first nth fraction
subFrac = 10;

randOrder = randperm(size(meshVerts,1));
vertIndMax = round(size(meshVerts,1)/subFrac);
subVerts = meshVerts(randOrder(1:vertIndMax),:);

segInds = find(filtSeg == 1);
randOrder = randperm(numel(segInds));
segIndMax = round(numel(segInds)/subFrac);
subSeg = segInds(randOrder(1:segIndMax));
[xCoordsSub, yCoordsSub, zCoordsSub] = ind2sub(size(filtSeg), subSeg);

%%  

