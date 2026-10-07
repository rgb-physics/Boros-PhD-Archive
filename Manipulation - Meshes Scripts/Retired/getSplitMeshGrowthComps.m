%%
%%% The following script assumes that mesh objects have been smoothed,
%%% rescaled, split, and oriented (normals) prior to running. One can
%%% remove edges below. I typically do all of this in MeshLab. 

%% Parameters
scaling = 1;
totChannels = 2;
channelNum = 1;
EdgeLength = 4;
windowSize = 8;
selectTimes = 92;
edgeRemove = 0;

%% Define boundary cutoffs
maxCuts = [329, 330, 109] ;
minCuts = [3, 3, 0] ;

%% Directories and files of interest
% meshDir = '<redacted original absolute path>';
meshDir = '';
% pivDir = '<redacted original absolute path>';
pivDir = '';
% dataDir = '<redacted original absolute path>';
dataDir = '';
meshNameForm = 'EdgeCut_Rescaledmesh_ms_%0.6i.ply';
pivNameForm = 'edge_%0.3i_window_%0.3i_vel_%0.3i.mat';
imgNameForm = 'Tiny_T%i.tif';

%% Load in image (tif), piv file, and mesh
firstMesh = sprintf(meshNameForm, selectTimes(1));
firstPIV  = sprintf(pivNameForm, EdgeLength, windowSize, selectTimes(1));
firstImg  = sprintf(imgNameForm, selectTimes(1));

imageVol = imresize(tiffreadVolume(fullfile(dataDir, firstImg)),scaling,'bicubic');
imageVol = imageVol(:,:,channelNum:totChannels:end);
load(fullfile(pivDir, firstPIV));
meshLoad = read_ply_mod(fullfile(meshDir, firstMesh)) ;

%% Removes edges from loaded mesh, if required by edgeRemove boolean
if edgeRemove
    Vraw = meshLoad.v ; Fraw = meshLoad.f;
    [Fcut, Vcut] = meshSideRemove(Fraw,Vraw, minCuts, maxCuts);
    [filtFcut,  filtVcut, ~,objNum] = remove_isolated_mesh_components(Fcut,Vcut);
    plywrite(fullfile(meshDir,['EdgeCut_' firstMesh]),filtFcut,filtVcut);
else
    filtVcut = meshLoad.v; filtFcut = meshLoad.f;
end

%% Barycenters
bcs = barycenter(filtVcut, filtFcut) ;
% make interpolation object of the velocities
[rowMat,colMat,depthMat] = ndgrid(EdgeLength/2:EdgeLength:size(imageVol,1)-EdgeLength/2, ...
    EdgeLength/2:EdgeLength:size(imageVol,2)-EdgeLength/2, ...
    EdgeLength/2:EdgeLength:size(imageVol,3)-EdgeLength/2); 
%Define tif intensities at these locations
allCoords = [colMat(:) rowMat(:) depthMat(:)];
intVals = imageVol( min(rowMat(:)):EdgeLength:max(rowMat(:)), ...
    min(colMat(:)):EdgeLength:max(colMat(:)), ...
    min(depthMat(:)):EdgeLength:max(depthMat(:)) );

%% Query 3d velocities on barycenters

% CHECK THIS WITH ASSYMETRIC MATRICES
ginterpx = griddedInterpolant(rowMat, colMat, depthMat, permute(VX, [2 1 3])) ;
ginterpy = griddedInterpolant(rowMat, colMat, depthMat, permute(VY, [2 1 3])) ;
ginterpz = griddedInterpolant(rowMat, colMat, depthMat, permute(VZ, [2 1 3])) ;
% query the interp objects at the faces
vx_faces = ginterpx(bcs(:, 1), bcs(:, 2), bcs(:, 3)) ;
vy_faces = ginterpy(bcs(:, 1), bcs(:, 2), bcs(:, 3)) ;
vz_faces = ginterpz(bcs(:, 1), bcs(:, 2), bcs(:, 3)) ;

% make a #faces x 3 float array of velocities
vfaces = [vx_faces, vy_faces, vz_faces] ;

%% Get intensities at barycenters
ginterpInts = griddedInterpolant(rowMat, colMat, depthMat, permute(im2double(intVals), [2 1 3])) ;
intsFaces = ginterpInts(bcs(:, 1), bcs(:, 2), bcs(:, 3)) ;

%% Take tangential and normal components
% Note: DEC should be able to handle this projection "on the fly" but in 
% my hands it is more accurate to do this manually. The projection method
% in DEC is a bit different than this more robust version (something I'll
% fix soon). 
% velocities on Faces -- tangential / normal components
[vF_n, vF_t] = resolveTangentNormalVector(filtFcut, filtVcut, vfaces) ;

%% Compute DiscreteExteriorCalculus of velocities
dec = DiscreteExteriorCalculus(filtFcut, filtVcut) ;

%% by default, divv will be #verts x 1 scalar field on mesh
divv = dec.divergence(vF_t) ;

%% Compare to bending: 2H*vn
vtxNormals = per_vertex_normals(filtVcut, filtFcut) ;  % note that we add a negative sign to force normals to be inward facing
% mean curvature is the laplacian dotted with the normal
% this is mean curvature on VERTICES
HV = sum(vtxNormals .* dec.laplacian(filtVcut), 2) * 0.5 ;

% push the normal component of the velocities to vertices
[V2F, F2V] = meshAveragingOperators(filtFcut, filtVcut) ;
% velocities on Vertices -- normal component: vV_n
vV_n = F2V * vF_n ;

H2vn_onVertices = 2 * HV .* vV_n ;

%% Check orientation of mesh
tri = triangulation(filtFcut, filtVcut) ;
clf
trisurf(tri, vtxNormals(:, 2), 'edgecolor', 'none')
axis equal
xlabel('x')
title('x component of vertex normals -- check that they are inward!!')

%% Alternatively, for comparison, we can compute 2Hvn on faces
HF = V2F * HV ;
H2vn_onFaces = 2 * HF .* vF_n ;

%% What is the Tr[gdot g^{-1}] == "metric growth"
growth = divv - H2vn_onVertices ;

%% Plot the two
clf
scatter(divv(:), H2vn_onVertices(:)) ; hold on;
plot([-1,1], [-1, 1], 'k--')

% fit to 
keepVtx = ~isnan(HV(:)) ;
pp = polyfit(divv(keepVtx), H2vn_onVertices(keepVtx), 1) ;
ylabel('$2H v_n$', 'interpreter', 'latex')
xlabel('$\nabla \cdot v_t$', 'interpreter', 'latex')
titleString = ['$\nabla \cdot v_t = ', sprintf('%0.2f H v_n + %0.2f$ ', 2*pp(1), pp(2))] ;
title(titleString, 'interpreter', 'latex')
axis equal

%% Plot intensities on barycenters
trisurf(tri, intsFaces, 'edgecolor', 'none');
axis equal


%% Check smoothness of fields
trisurf(tri, HV, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(HV(:)), 90) ;
caxis([-cmax, cmax])
colormap bluewhitered
cb = colorbar ;
ylabel(cb, '$H$', 'interpreter', 'latex')
sgtitle(sprintf('$H$, $t=%03d$', tidx), 'interpreter', 'latex')
xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
zlabel('z [$\mu$m]', 'interpreter', 'latex') ;

saveas(gcf, fullfile(outDir, sprintf('meanCurvature_T%03d.png', tidx)))


%% Check smoothness of fields
clf
tri = triangulation(filtFcut, filtVcut) ;
trisurf(tri, HV, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(HV(:)), 90) ;
caxis([-cmax, cmax])
color1 = [110 191 139]; color2 = [21 29 59]; color3 = [216 33 72];
cmapWatermelon = meldNcolors([color1; color2; color3], 200);
colormap(cmapWatermelon)
cb = colorbar ;
ylabel(cb, '$v_n$', 'interpreter', 'latex')
sgtitle(sprintf('$H$, $t=%03d$', tidx), 'interpreter', 'latex')
xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
zlabel('z [$\mu$m]', 'interpreter', 'latex') ;

saveas(gcf, fullfile(outDir, sprintf('meanCurvature_T%03d.png', tidx)))

%% Check smoothness of fields
clf
trisurf(tri, vV_n, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(vV_n(:)), 90) ;
caxis([-cmax, cmax])
colormap bluewhitered
cb = colorbar ;
ylabel(cb, '$2Hv_n$', 'interpreter', 'latex')
sgtitle(sprintf('$2Hv_n$, $t=%03d$', tidx), 'interpreter', 'latex')
xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
zlabel('z [$\mu$m]', 'interpreter', 'latex') ;
saveas(gcf, fullfile(outDir, sprintf('vn_T%03d.png', tidx)))


%% Check smoothness of fields
clf
trisurf(tri, H2vn_onVertices, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(H2vn_onVertices(:)), 90) ;
caxis([-cmax, cmax])
colormap bluewhitered
cb = colorbar ;
ylabel(cb, '$2Hv_n$', 'interpreter', 'latex')
sgtitle(sprintf('$2Hv_n$, $t=%03d$', tidx), 'interpreter', 'latex')
xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
zlabel('z [$\mu$m]', 'interpreter', 'latex') ;
saveas(gcf, fullfile(outDir, sprintf('H2vn_T%03d.png', tidx)))


%% Correlate this to other observables
plot(HV(:), growth(:), '.')
ylabel('growth')
xlabel('mean curvature')

%% Wait which way is the normal???
subplot(3, 1, 1)
trisurf(tri, vtxNormals(:, 1),'edgecolor','none') ;
subplot(3, 1, 2)
trisurf(triangulation(Fnew, Vnew), vtxNormals(:, 2),'edgecolor','none') ;
subplot(3, 1, 3)
trisurf(triangulation(Fnew, Vnew), vtxNormals(:, 3),'edgecolor','none') ;

% If there is bad orientation issues
Fnew = reorient_facets(Vnew, Fnew) ;

