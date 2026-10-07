%% This script takes in a directory and removes edges of meshes before saving in an output directory
% dataDir = '<redacted original absolute path>';
dataDir = '';
fileName = 'mesh_ms_%0.6i.ply';
% outputFile = '<redacted original absolute path>';
outputFile = '';
fileRange = 50:85;
minCuts = [2,2,1];
maxCuts = [330, 331, 109];

%% Iterate, load, cut, and save
for currFileNum = fileRange
    
    currFile = sprintf(fileName, currFileNum);
    currMesh = read_ply_mod(fullfile(dataDir, currFile)) ;
    Vraw = currMesh.v ; Fraw = currMesh.f;
    
    [Fcut,Vcut] = meshSideRemove(Fraw,Vraw, minCuts, maxCuts);
    
    plywrite(fullfile(outputFile,['EdgeCut_' currFile]),Fcut,Vcut);
    
end

