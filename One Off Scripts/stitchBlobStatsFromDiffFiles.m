% Takes in data sets analyzed using blobPropsFrom_R_Intertia.m broken up
% over times and concatenates, sorts, and saves them as one file
% 2026-05-26 - Rémi Boros

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 84';
saveDir = dataDir;
dataName1 = 'T1-29_trajSorted_BlobVolsInts.mat';
dataName2 = '29-50_trajSorted_BlobVolsInts.mat';
rData1 = 'T1-29_trajSorted_RMin_Anisotropy.mat';
rData2 = '29-50_trajSorted_RMin_Anisotropy.mat';

%% Load data sets

load(fullfile(dataDir,rData1));
rData1 = statStruct;
load(fullfile(dataDir,rData2));
rData2 = statStruct;

load(fullfile(dataDir,dataName1));
sortData1 = sortedMat;
load(fullfile(dataDir,dataName2));
sortData2 = sortedMat;

%% Concatenate
startInd = numel(rData1) + 1;
endInd = startInd + numel(rData2) - 1;
concatRs = rData1;
concatRs(startInd:endInd) = rData2;

concatSorted = [sortData1; sortData2];

%% Resort by blobID
[~,sortOrder] = sort(concatSorted(:,1));
firstPassSorted = concatSorted(sortOrder,:);
unqIDs = unique(firstPassSorted(:,1));
% Look for duplicate entries, then replace them
remainInds = [];
for index = 1:numel(unqIDs)
    currID = unqIDs(index);
    currIndices = find(firstPassSorted(:,1) == currID);
    [~,unqInds,~] = unique(firstPassSorted(currIndices,2));
    remainInds = [remainInds; currIndices(unqInds)];
end
catResorted = firstPassSorted(remainInds,:);
% use same indices to resort concatenated structures
firstSortRs = concatRs(sortOrder);
rsResorted = firstSortRs(remainInds);

%% Save data sets
sortedMat = catResorted;    statStruct = rsResorted;
save(fullfile(saveDir,'ALL_trajSorted_BlobVolsInts'),'sortedMat', 'imgDims', 'imgVoxSize', 'timeStep', "labelDims", 'labelVoxSize'  );
save(fullfile(saveDir,'ALL_trajSorted_RMin_Anisotropy.mat'),'statStruct');

