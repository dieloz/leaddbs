function [voxInd, uniqueInd, voxSub] = ea_mm2uniqueVoxInd(XYZmm, reference)
% Convert XYZ mm coordinates to unique voxel indices in reference nifti

if ~exist('reference', 'var') || ischar(reference)
    refnii = ea_load_nii([ea_space, 't1.nii']);
end

% Find unique voxel subscripts
[voxSub, uniqueInd] = unique(round(ea_mm2vox(XYZmm, refnii.mat)), 'rows');

% Remove all outliers
voxSub = voxSub(all(voxSub>0, 2) & all(voxSub<=refnii.dim, 2), :);

% Return the unique voxel indices
if ~isempty(voxSub)
    voxInd = sub2ind(refnii.dim, voxSub(:,1), voxSub(:,2), voxSub(:,3));
else
    voxInd = 0;
end
