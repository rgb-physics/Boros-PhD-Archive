%% Get directory info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 11, Exp 7';
dataNameForm = 'T%0.2i.obj';
timeRange = 12:41;
saveDir = fullfile(dataDir, 'Mesh Info');
pixDim = .3667;       %In um/pix
flipNorms = 1;

%% Iterate through each object and store info: surface area, volume, euler characteristic, ismanifold
tic
allInfopls = [];
for tInd = 1:numel(timeRange)
    
    currObj = readObj(fullfile(dataDir, sprintf(dataNameForm,timeRange(tInd))));
    currMesh.f = currObj.f.v; currMesh.v = currObj.v;
    currInfo = getMeshDims(currMesh, pixDim, flipNorms);
    currInfo.timeStamp = timeRange(tInd);
    allInfo = [allInfopls; currInfo];
    
end
toc

%% Iterate through each object and store info: surface area, volume, euler characteristic, ismanifold
tic
allInfoCell = cell(numel(timeRange),1);
for tInd = 1:numel(timeRange)
    
    currObj = readObj(fullfile(dataDir, sprintf(dataNameForm,timeRange(tInd))));
    currMesh.f = currObj.f.v; currMesh.v = currObj.v;
    allInfoCell{tInd} = getMeshDims(currMesh, pixDim, flipNorms);
    
end
toc

%% Plot mesh volumes and surface areas over time
close all
figure
scatter(allInfo.timeStamp,allInfo.Volume,'filled' )
hold on
scatter(allInfo.timeStamp,allInfo.SurfaceArea,'filled' )
set(gca, 'FontSize', 15);
xlabel('Time (frames)')
legend('Volume (\mum^3)','Surface Area (\mum^2)')

figure
scatter(log(allInfo.timeStamp),log(allInfo.Volume),'filled' )
hold on
scatter(log(allInfo.timeStamp),log(allInfo.SurfaceArea),'filled' )
set(gca, 'FontSize', 15);
xlabel('Time (frames)')
legend('Volume (\mum^3)','Surface Area (\mum^2)')
grid on