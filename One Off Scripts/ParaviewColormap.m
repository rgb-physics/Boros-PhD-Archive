% Load pre-existing Paraview colormap from .json, edit/make a new colormap,
% and export as .json
% 2026-05-28 - Rémi Boros

%% Load a generic map
% mapDir = '<redacted original absolute path>';
mapDir = '';
mapName = 'rainbowOUT.json';
fid = fopen(fullfile(mapDir,mapName)); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
val = jsondecode(str);
% the map is stored as a vector that in turn is a reshaped 4xN array.
% Column 1 of the array is a linear mapping from 0 to 1
% Columns 2-4 of the array represent RGB
% Reshaping can be done with            reshape(vector,[4,numel(vector)/4])'
% A 4xN array converts to vector via    reshape(matrix',[numel(matrix), 1])

%% Make your own map
% Variables
outMap = val;
crName = 'Remi Boros';
mpName = 'RdPu7';
mapLen = 256;
jsonOutName = sprintf('%s_%i.json',mpName,mapLen);

% Generate the map
mapVals = zeros(mapLen, 4);
mapVals(:,2:end) = othercolor(mpName,mapLen);
mapVals(:,1) = (0:(mapLen - 1))/mapLen;

% Reshape the map
mapVec = reshape(mapVals',[numel(mapVals), 1]);

% Format as .json
outMap.Creator = crName;
outMap.Name = 'Turbo';
outMap.RGBPoints = mapVec;
% outMap.DefaultMap = 0;

% Export as .json
fileID = fopen(fullfile(mapDir,jsonOutName),'w');
encodedJSON = jsonencode(outMap); 
fprintf(fileID, encodedJSON); 
fclose('all'); 
