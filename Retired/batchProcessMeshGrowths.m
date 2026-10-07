% may or may not need to run setup.m in imsane FROM IMSANE DIR (ie cd
% to imsane/ first).

%% Parameters
scaling = 1;
totChannels = 2;
channelNum = 1;
EdgeLength = 10;

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
firstMesh = 'Rescaledmesh_ms_000063.ply';
firstPIV  = 'vel_063.mat';
firstImg  = 'Tiny_T63.tif';


%% Load in image (tif), piv file, and mesh
imageVol = imresize(tiffreadVolume(fullfile(dataDir, firstImg)),scaling,'bicubic');
imageVol = imageVol(:,:,channelNum:totChannels:end);
load(fullfile(pivDir, firstPIV));
mesh = read_ply_mod(fullfile(meshDir, firstMesh)) ;

%% Consider: remaking the smooth meshes after removing the walls 
% rm vertices on the "boundary" of the fudicial volume from rawMesh and
% then make a coarsened mesh from that 
Vraw = mesh.v ; Fraw = mesh.f;
[Fcut, Vcut] = meshSideRemove(Fraw,Vraw, minCuts, maxCuts);
[filtFcut,  filtVcut, ~,objNum] = remove_isolated_mesh_components(Fcut,Vcut);
plywrite(fullfile(meshDir,['EdgeCut_' firstMesh]),filtFcut,filtVcut);

%% Optional: Downsample the mesh to make this more tractable
if downsample 
    [Fnew, Vnew, Fnnew, Vnnew] = ...
           isotropic_remeshing(mesh.f, mesh.v, targetEdgeLength, numIterations) ;
else
    Fnew = mesh.f ;
    Vnew = mesh.v ;
end

%% MAKE SURE NORMALS ARE INWARD
% by hook or crook. Here we know they start out outward
Fnew = [Fnew(:, 2), Fnew(:, 1), Fnew(:, 3)] ;

%% Remove walls
minCuts = [328, 330, 110] ; %[331, 332, 110] ;
maxCuts = [2, 2, 0] ;
badVertices  = find(Vnew(:, 1) < maxCuts(1) | Vnew(:, 1) > minCuts(1) | ...
    Vnew(:, 2) < maxCuts(2) | Vnew(:, 2) > minCuts(2) | ...
    Vnew(:, 3) < maxCuts(3) | Vnew(:, 3) > minCuts(3)) ;
    
[ Fnew, Vnew]  = ...
     remove_vertex_from_mesh(Fnew, Vnew, badVertices) ;

%% Query 3d velocities on barycenters
bcs = barycenter(Vnew, Fnew) ;
% make interpolation object of the velocities
[rowMat,colMat,depthMat] = ndgrid(EdgeLength/2:EdgeLength:size(imageVol,1)-EdgeLength/2, ...
    EdgeLength/2:EdgeLength:size(imageVol,2)-EdgeLength/2, ...
    EdgeLength/2:EdgeLength/1:size(imageVol,3)-EdgeLength/2); 
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

%% Take tangential and normal components
% Note: DEC should be able to handle this projection "on the fly" but in 
% my hands it is more accurate to do this manually. The projection method
% in DEC is a bit different than this more robust version (something I'll
% fix soon). 
% velocities on Faces -- tangential / normal components
[vF_n, vF_t] = resolveTangentNormalVector(Fnew, Vnew, vfaces) ;

%% Compute DiscreteExteriorCalculus of velocities
dec = DiscreteExteriorCalculus(Fnew, Vnew) ;

%% by default, divv will be #verts x 1 scalar field on mesh
divv = dec.divergence(vF_t) ;

%% Compare to bending: 2H*vn
vtxNormals = per_vertex_normals(Vnew, Fnew) ;  % note that we add a negative sign to force normals to be inward facing
% mean curvature is the laplacian dotted with the normal
% this is mean curvature on VERTICES
HV = sum(vtxNormals .* dec.laplacian(Vnew), 2) * 0.5 ;

% push the normal component of the velocities to vertices
[V2F, F2V] = meshAveragingOperators(Fnew, Vnew) ;
% velocities on Vertices -- normal component: vV_n
vV_n = F2V * vF_n ;

H2vn_onVertices = 2 * HV .* vV_n ;

%% Check orientation of mesh
tri = triangulation(Fnew, Vnew) ;
clf
trisurf(tri, vtxNormals(:, 1), 'edgecolor', 'none')
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
tri = triangulation(Fnew, Vnew) ;
trisurf(tri, HV, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(HV(:)), 90) ;
caxis([-cmax, cmax])
colormap bluewhitered
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

%% Is there a correlation with something else that makes physical sense?


%% Wait which way is the normal???
subplot(3, 1, 1)
trisurf(tri, vtxNormals(:, 1),'edgecolor','none') ;
subplot(3, 1, 2)
trisurf(triangulation(Fnew, Vnew), vtxNormals(:, 2),'edgecolor','none') ;
subplot(3, 1, 3)
trisurf(triangulation(Fnew, Vnew), vtxNormals(:, 3),'edgecolor','none') ;

% If there is bad orientation issues
Fnew = reorient_facets(Vnew, Fnew) ;




%% Could point match to get time info (rough but good method since it is parameter-free!)
% [] = pointMatch(V_t0, V_t1)



%%

 % Then you can smooth these meshes and downsample them
 [Frecut, Vrecut] = isotropic_remeshinging() ;
 bndVtx = freeBoundary(triangulation(Frecut, Vrecut)) ;
VrecutSmoothed = laplacian_smooth(Vrecut, Frecut, 'cotan', bndVtx, lambda, 'implicit', Vrecut, 1000)

 plywrite(filename,faces,verts)

%(keep the old ones though they are ok!)
% use isotropic_remesh() in CGAL to downsample the vertices -- this is in
% imsane/external/CGALcodes/.cpp
% and use 
% laplacian_smooth() in gptoolbox to smooth the mesh. 
% Then use plywrite() to save it.
% if you want normals, per_vertex_normals()

