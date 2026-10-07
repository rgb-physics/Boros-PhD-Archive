%% Data Dir
% dataDir = '<redacted original absolute path>';
dataDir = '';
dataSet = 't2001.mat';

% ptCloudDir = '<redacted original absolute path>';
ptCloudDir = '';
ptCloudName = 'ptCloud1.ply';

% meshDir = '<redacted original absolute path>';
meshDir = '';
meshName = 'RescaledptCloud1.ply';

% Image dimension information
scaleFacts = [1 1 20/1.3];
% Used for bounding mesh and removing vertices that are out of bounds
minCuts = [1 1 1];
maxCuts = [700, 1800, 475];
% For vertex subsampling
subSampFrac = .1;

% Change this
% meshLabDir = '<redacted original absolute path>';
meshLabDir = '';
% Keep this, though the "funcName" is one of three others. You can try them
% and compare if you're not satisfied with the way the meshes are being
% generated. 
ply2Mesh = 'batch_pointCloud2Mesh - MATLABexec.py';    
funcName = 'Ray_PointCloud2Mesh_ScreenedPoisson.mlx';

%% Load
load(fullfile(dataDir,dataSet));

%% Crop and get perimeter
% I'd do this separately...
precropped = bw2(:,50:1850,:);

% Find largest object and isolate
bwlabels = bwlabeln(precropped);
uniqueCountsArr = groupcounts(bwlabels(bwlabels ~= 0));
labelNum = find(uniqueCountsArr == max(uniqueCountsArr));
singObj = consMatLnB(ones(size(precropped)),bwlabels == labelNum);

% Rescale object (Often rescaling down a factor of 2 in all dimensions will
% greatly increase computation efficiency without losing you significant
% information).
rescaledObj = imresize3(singObj, size(singObj).*scaleFacts);

% Generate point cloud from boundary
ptCloud = xor(rescaledObj,imdilate(rescaledObj,strel('sphere',strelRad)));
vertinds = find(ptCloud);
subInds = randsample(1:numel(vertinds),round(subSampFrac*numel(vertinds)));
subCloud = consMatLnB(ones(size(ptCloud)),vertinds(subInds));

%% Save as ply
logic2Ply(subCloud, fullfile(ptCloudDir,ptCloudName));      %plywrite comes from Noah's library Tubular

%% Convert to mesh with faces
scriptLoc = fullfile(meshLabDir, ply2Mesh);
funcLoc = fullfile(meshLabDir, funcName);
% The following will require you to have MATLAB setup to run Python:
% https://www.mathworks.com/help/matlab/ref/pyenv.html
pyrunfile(scriptLoc, dataDir = ptCloudDir, saveDir = meshDir, scriptName = funcLoc)

%% Load your mesh
currMesh = read_ply_mod(fullfile(meshDir,meshName));

%% Trim edges, calculate bcs and curvatures
%load vertices and faces
Vraw = currMesh.v ; Fraw = currMesh.f;
%Cut mesh
[Fcut, Vcut] = meshSideRemove(Fraw, Vraw, minCuts, maxCuts);
[filtFcut,  filtVcut] = remove_isolated_mesh_components(Fcut,Vcut);

%Get barycenter coords
bcs = barycenter(filtVcut, filtFcut);
% Compute DiscreteExteriorCalculus of surface
dec = DiscreteExteriorCalculus(filtFcut, filtVcut) ;

% Get surface normals, ensuring to flip sign s.t. normal points toward MTs
vtxNormals = per_vertex_normals(filtVcut, filtFcut) ;  % normalized
[V2F, F2V] = meshAveragingOperators(filtFcut, filtVcut);

% Curvatures - NOTE: you can replace HV with any field. Use gridded or
% scattered interpolant objects to query values on your vertices and/or
% your barycenters
HV = sum(vtxNormals .* dec.laplacian(filtVcut), 2) * 0.5 ;

%% Smooth your field
lapSmooth = 50;
[smoothHV, ~] = laplacian_smooth(filtVcut,filtFcut,'cotan',[],.1,'implicit',HV,lapSmooth);

%% Display your field on your triangulated mesh
tri = triangulation(filtFcut, filtVcut);
trisurf(tri,smoothHV(:),'edgecolor','none')
axis equal
cmax = prctile(abs(smoothHV),95);
clim([-cmax cmax])

%% 
% %% Rescale verts
% currMesh = read_ply_mod(fullfile(saveDir,saveName));
% plywrite(currMesh, fullfile(saveDir,'Rescaled_'+saveName));





