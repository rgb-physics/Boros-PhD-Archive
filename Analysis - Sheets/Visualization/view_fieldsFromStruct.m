%% Data Info
% homeDir = '<redacted original absolute path>';
homeDir = 'Session 45, Exp 3';
dataDir = fullfile(homeDir,'11 Quantitative Data');
dataName = 'DataStoreStructT%03i.mat';

selectTimes = 165;
desField = 'intV';

%% Load data
currT = selectTimes(1);
load(fullfile(dataDir,sprintf(dataName,currT)),'currStruct');

%% Triangulate
currV = currStruct.v;   currF = currStruct.f;
tri = triangulation(currF,currV);

%% Load field on mesh
currField = currStruct.(desField);
trisurf(tri, currField(:),'edgecolor','none');
axis equal
cmax = prctile(currField(:), 90);
clim([0 cmax]);
colorbar

