%% Apply Poisson Disk Elimination to a collection of vertices
% Methods from 'Sample Elimination for Generating Poisson Disk Sample Sets'
% http://www.cemyuksel.com/research/sampleelimination/sampleelimination.pdf
% 2023/10/06

% meshDir = '<redacted original absolute path>';
meshDir = 'Session 45, Exp 3';
meshName = 'Time008_pointCloud.ply';

%%

currMesh = read_ply_mod(fullfile(meshDir,meshName));
vertices = currMesh.v;

%% knsearch for neighbors
volDims = max(vertices)+1;
rmax = (prod(volDims)/(4*sqrt(2)*size(vertices,1)))^(1/3);

%% Get distances of objects in neighborhood rmax
[neighbInds,neighbDists] = rangesearch(vertices,vertices,rmax);

%% Define weights
% neighbNumVec = cellIndSizes(neighbInds);
% Vectorize distances, then define individual weights
linearDists = [neighbDists{:}];
w_ijVec = (1 - linearDists/(2*rmax)).^8;


