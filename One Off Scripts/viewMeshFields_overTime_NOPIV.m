
% baseMat = '<redacted original absolute path>';
baseMat = 'Session 63, Exp 4';
% ilSegDir = '<redacted original absolute path>';
ilSegDir = 'Session 63, Exp 4';
saveDir = fullfile(baseMat,'10 Quantitative Data\PIV Data - 2');
saveName = 'DataStoreStructT%03i_scatInt_Top.mat';
ilSegName = 'SplitRegions_Time%06i.mat';
ptCloudName = 'topskel_vertices_t%03i_AND.ply';
meshName = 'topskel_vertices_t%03i_AND.ply';

structFields = {'TopSheet'};
% structFields = {'TopSheet','BotSheet'};
segVar = 'regionStruct';
deltaT = .5;
selTimes = 1:40;
% load metadata from piv (Run3DPIV.m) and segmentation (h5toMesh_homeoAndSplit.m)
% load(fullfile(ilSegDir,'metadata.mat'));
segSize = [282 281 41];

%%  Load more data

% saveDir1 = '<redacted original absolute path>';
saveDir1 = 'Session 74, Exp 3';
saveName1 = 'T%03i.tif';


for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
storeStruct = load(fullfile(ilSegDir,sprintf(ilSegName,currT)),segVar).(segVar);
% segSize stored in metadata from segmentations of regionstructs
binSegs = struct2Mat_sheets(storeStruct,structFields,segSize);      

load(fullfile(saveDir,sprintf(saveName,currT)),'currStruct');
smoothHV = currStruct.curvV;
intsV = currStruct.intV;
filtFcut = currStruct.f;
filtVcut= currStruct.v;
scaleCenCoords = validCenCoords.*pivVoxSize;    % dist: pivVoxSize from PIV metadata
scaleShifts = shifts.*pivVoxSize/deltaT;        % dist/time; pivVoxSize from PIV metadata

%%
dec = DiscreteExteriorCalculus(filtFcut, filtVcut) ;
[V2F, F2V] = meshAveragingOperators(filtFcut, filtVcut);
%%
figure
flipHV = smoothHV;
vtxNormals = per_vertex_normals(filtVcut, filtFcut) ;  % normalized
if mean(vtxNormals(:,3)) > 0
    flipHV = -smoothHV;
end

currField = intsV;
% currField = F2V*currStruct.vel_face(:,3);

tri = triangulation(filtFcut,filtVcut);
trisurf(tri, (currField(:)), 'edgecolor','none');
cmax = prctile(abs(currField(:)),95);
% clim([-0 cmax]);
clim([0 25000])
axis equal
colorbar
xlabel('X')
ylabel('Y')
zlabel('Z')
set(gca,'FontSize',15)
% clim([-0.1 0.1])
xlim([0 750])
ylim([0 750])
zlim([0 80])
% title('Curvatures')

% %% Display quiver plot; validate by sheet
% % Seg - binSegs
% 

if ~exist(saveDir1,'dir')
    mkdir(saveDir1)
end
    exportgraphics(gca,fullfile(saveDir1,sprintf(saveName1,currT)));
    close();
end



