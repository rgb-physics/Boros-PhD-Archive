%% Get data info
% meshDir = '<redacted original absolute path>';
meshDir = '';
meshName = 'Rescaledmesh_ms_000063.ply';
sigPerc = .997;

%% Load mesh and extract vertex and face info
mesh = read_ply_mod(fullfile(meshDir, meshName)) ;

Fdata = mesh.f ;
Vdata = mesh.v ;

%% Compute DiscreteExteriorCalculus of surface
dec = DiscreteExteriorCalculus(Fdata, Vdata) ;

%% Define vertex normals and surface curvature from vertices
vtxNormals = per_vertex_normals(Vdata, Fdata) ;  % note that we add a negative sign to force normals to be inward facing
% mean curvature is the laplacian dotted with the normal
% this is mean curvature on VERTICES
HV = sum(vtxNormals .* dec.laplacian(Vdata), 2) * 0.5 ;

%% Close figs
close all

%% Triangulate and display curvature on surface
tri = triangulation(Fdata, Vdata) ;
trisurf(tri, HV, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(HV(:)), 90) ;
caxis([-cmax, cmax])
colormap bluewhitered
cb = colorbar ;
ylabel(cb, '$H$', 'interpreter', 'latex')
% sgtitle(sprintf('$H$, $t=%03d$', tidx), 'interpreter', 'latex')
xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
zlabel('z [$\mu$m]', 'interpreter', 'latex') ;
set(gca, 'FontSize',15)

%% Plot curvature distribution
[binCounts, binEdges] = histcounts(abs(HV));
totCounts = sum(binCounts);     cutOffCounts = 0; 
cutOffBin = 0;
while cutOffCounts < totCounts*sigPerc
   cutOffBin = cutOffBin + 1;
   cutOffCounts = sum(binCounts(1:cutOffBin));
    
end
figure
histogram(abs(HV))
scatter(binEdges(1:cutOffBin), log(binCounts(1:cutOffBin)))
xlabel('Curvature (1/pixels)')
ylabel('Log(Bin Counts)')
set(gca,'FontSize',15)
ylim([0 11])
xlim([-.01 .5])


%% Extract length scale as 1/Hmax