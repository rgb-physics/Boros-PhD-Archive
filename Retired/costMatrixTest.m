%% Load data
% motherDir = '<redacted original absolute path>';
motherDir = 'Session 11, Exp 7';
dataDirForm = 'Time %0.6i';
timeRange = 5:6;
fileFormat = 'meshInfoTime%0.6i.mat';
cutOffDist = 60;

%%
for currT = 1:numel(timeRange)-1
    
    
    % load data
    load(fullfile(motherDir, sprintf(dataDirForm, timeRange(currT)), sprintf(fileFormat, timeRange(currT))));
    centers1 = allDataTable.Centroid;
    load(fullfile(motherDir, sprintf(dataDirForm, timeRange(currT+1)), sprintf(fileFormat, timeRange(currT+1))));
    centers2 = allDataTable.Centroid;
    xDiff = (centers2(:,1) - centers1(:,1)');
    yDiff = (centers2(:,2) - centers1(:,2)');
    zDiff = (centers2(:,3) - centers1(:,3)');

    diffMat = sqrt( xDiff.^2 + yDiff.^2 + zDiff.^2 );
    
    % Get nearest object at t2 for each obect at t1
    [minValsT1,rowCoords] = min(diffMat, [], 1);
    minCoordsT1 = [1:numel(rowCoords); rowCoords]';
    % Get nearest object at t1 for each obect at t2
    [minValsT2,colCoords] = min(diffMat, [], 2);
    minCoordsT2 = [colCoords'; 1:numel(colCoords)]';
    
    
    %Real pair indices
    dummyMat = triu(ones(size(diffMat)),1);
    diffMatClone = diffMat;
    diffMatClone(~logical(dummyMat)) = Inf;
    diffMatClone(diffMat > cutOffDist) = Inf;
    [~, pairIndices] = min(diffMatClone,[],2);
    nearestPairs = [1:size(diffMat,1); pairIndices']';
    
    pairCoords = diffMat ~= 0;
    
    %By default, centroid coords should be in pixels
    
%     hist(diffMat ~= 0)
%     pause(.1)

end
%% Load specific mesh object
currDir = fullfile(motherDir, sprintf(dataDirForm, 5));
tempMesh = read_ply_mod(fullfile(currDir, 'Mesh000480.ply'));
meshInfo = getMeshDims(tempMesh, 1, 1);
meshCenter = meshInfo.Centroid;
