

%% Consider: remaking the smooth meshes after removing the walls 
% rm vertices on the "boundary" of the fudicial volume from rawMesh and
% then make a coarsened mesh from that 
Vraw = rawMesh.v ; Fraw = rawMesh.f;

badVertices  = find(Vraw(:, 1) < maxCuts(1) | Vraw(:, 1) > minCuts(1) | ...
    Vraw(:, 2) < maxCuts(2) | Vraw(:, 2) > minCuts(2) | ...
    Vraw(:, 3) < maxCuts(3) | Vraw(:, 3) > minCuts(3)) ;
    
[ Fcut, Vcut]  = ...
     remove_vertex_from_mesh(Fraw, Vraw, badVertices) ;
 % Then you can smooth these meshes and downsample them
 [Frecut, Vrecut] = isotropic_remeshing() ;
 bndVtx = freeBoundary(triangulation(Frecut, Vrecut)) ;
VrecutSmoothed = laplacian_smooth(Vrecut, Frecut, 'cotan', bndVtx, lambda, 'implicit', Vrecut, 1000);

 plywrite()

%(keep the old ones though they are ok!)
% use isotropic_remesh() in CGAL to downsample the vertices -- this is in
% imsane/external/CGALcodes/.cpp
% and use 
% laplacian_smooth() in gptoolbox to smooth the mesh. 
% Then use plywrite() to save it.
% if you want normals, per_vertex_normals()

%% Optional: Downsample the mesh to make this more tractable
if downsample 
    [Fnew, Vnew, Fnnew, Vnnew] = ...
           isotropic_remeshing(mesh.f, mesh.v, targetEdgeLength, numIterations) ;
else
    Fnew = mesh.f ;
    Vnew = mesh.v ;
end
