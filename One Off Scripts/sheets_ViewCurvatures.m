% Look at curvatures from analyzed sheet meshes
% After storeMeshProps_Combined.m
% 2025-08-15 - Rémi Boros

superStr = 'top';
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 28, Exp 6';
dataDir = fullfile(baseDir,'10 Data on Meshes');        
dataName = 'DataStoreStructT%03i_scatInt_%s.mat';

selTimes = 150:280;
dataVar = 'currStruct';

outDir = fullfile(baseDir,'Consolidated Curvatures');

%% Consolidate curvature data

allCurvs = []; 
countMat = zeros(numel(selTimes),3); 
allVerts = []; allFaces = []; 
for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    % Load data
    currStruct = load(fullfile(dataDir,sprintf(dataName,currT,superStr)),dataVar).(dataVar);
    allCurvs = vertcat(allCurvs, currStruct.curvV);
    % allVerts = vertcat(allVerts, currStruct.v);
    % allFaces = vertcat(allFaces, currStruct.f);
    % Append times
    countMat(tInd,1) = currT;
    countMat(tInd,2) = size(currStruct.v,1);
    countMat(tInd,3) = size(currStruct.f,1);

end
if ~exist(outDir,'dir')
    mkdir(outDir);
end
save(fullfile(outDir,sprintf('Consolidated_T%i-T%i_%s.mat',min(selTimes),max(selTimes),superStr)),...
    'countMat','allCurvs');

%% Histogram of curvatures over all time
load(fullfile(outDir,sprintf('Consolidated_T%i-T%i_%s.mat',min(selTimes),max(selTimes),superStr)));
hvBin = -.15:.002:.15;


% histogram(allCurvs,hvBin);
[counts,~,inds] = histcounts(allCurvs,hvBin);
countsPlus = histcounts(allCurvs(allCurvs>0),hvBin);
countsMinus = histcounts(allCurvs(allCurvs<=0),hvBin);

rsPlus = histcounts(1./allCurvs(allCurvs>0),-150:150);
rsMinus = histcounts(1./allCurvs(allCurvs<=0),-150:150);

% Normalized difference of curvatures
figure
% plot(1./hvBin(2:end),countsPlus - fliplr(countsMinus))
% plot(-150:149,rsPlus - fliplr(rsMinus));
% plot(hvBin(2:end),countsPlus/sum(countsPlus) - fliplr(countsMinus)/sum(countsMinus))

%% Select time
currT = 175;
hvBins = -.15:.002:.15;
rBins = -150:150;
% Get valid vertex indices from countMat
findInd = find(countMat(:,1) == currT);
cumsumMat = [0 0; cumsum(countMat(:,2:3))];
indBnds = [cumsumMat(findInd,1)+1, cumsumMat(findInd + 1,1)];
fcBnds = [cumsumMat(findInd,2)+1, cumsumMat(findInd + 1,2)];
% Valid curvatures
currCurvs = allCurvs(indBnds(1):indBnds(2));

countsPlus = histcounts(currCurvs(currCurvs>0),hvBins);
countsMinus = histcounts(currCurvs(currCurvs<=0),hvBins);

rsPlus = histcounts(1./currCurvs(currCurvs>0),rBins);
rsMinus = histcounts(1./currCurvs(currCurvs<=0),rBins);

valFaces = allFaces(fcBnds(1):fcBnds(2),:);
valVerts = allVerts(indBnds(1):indBnds(2),:);
dispVerts = valVerts;   dispVerts(:,3) = -dispVerts(:,3);
tri = triangulation(valFaces,dispVerts);
trisurf(tri, currCurvs, 'edgecolor','none');
    % tri = triangulation(filtFcut,filtVcut);

