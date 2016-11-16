function ea_fnirt(varargin)
% Wrapper for FSL FNIRT nonlinear registration

fixedimage = varargin{1};
movingimage = varargin{2};
outputimage = varargin{3};

% Do linear registration first, generate the affine matrix 'fslaffine*.mat'
movingimage_flirt = [ea_niifileparts(movingimage), '_flirt'];
if isempty(dir([movingimage_flirt,'.nii*']))
    ea_flirt(fixedimage, movingimage, movingimage_flirt, 1);
end

fixedimage_bet_mask = [ea_niifileparts(fixedimage), '_bet_mask'];
movingimage_bet_mask = [ea_niifileparts(movingimage), '_bet_mask'];

volumedir = [fileparts(ea_niifileparts(movingimage)), filesep]; 

% Determine the affine matrix to be used
if nargin >= 4
    affine = varargin{4};
else
    [~, mov] = ea_niifileparts(movingimage);
    [~, fix] = ea_niifileparts(fixedimage);
    xfm = [mov, '2', fix];
    affine = dir([volumedir, xfm, '_flirt*.mat']);

    if numel(affine) == 0
        error(['Initial affine matrix is missing!\nPlease delete ', ...
               movingimage_flirt, '.nii and try again.']);
    else
        affine = [volumedir, affine(end).name];
    end
end

[~, warpprefix] = ea_niifileparts(outputimage);

% template config
% fnirtstage = [' --subsamp=4,4,2,2,1,1' ...
%               ' --warpres=8,8,8' ...
%               ' --miter=5,5,5,5,5,10' ...
%               ' --infwhm=8,6,5,4.5,3,2' ...
%               ' --reffwhm=8,6,5,4,2,0' ...
%               ' --lambda=300,150,100,50,40,30' ...
%               ' --estint=1,1,1,1,1,0' ...
%               ' --ssqlambda=1' ...
%               ' --regmod=bending_energy' ...
%               ' --intmod=global_non_linear_with_bias' ...
%               ' --intorder=5' ...
%               ' --biasres=50,50,50' ...
%               ' --biaslambda=10000' ...
%               ' --refderiv=0' ...
%               ' --applyrefmask=1,1,1,1,1,1' ...
%               ' --applyinmask=1'];


fnirtstage = [' --ref=', ea_path_helper(fixedimage), ...
              ' --in=', ea_path_helper(movingimage), ...
              ' --refmask=', ea_path_helper(fixedimage_bet_mask), ...
              ' --inmask=', ea_path_helper(movingimage_bet_mask), ...
              ' --aff=', ea_path_helper(affine) ...
              ' --iout=', ea_path_helper(outputimage), ...
              ' --cout=', ea_path_helper(volumedir), warpprefix, 'WarpCoef.nii' ...
              ' --fout=', ea_path_helper(volumedir), warpprefix, 'WarpFiled.nii' ...
              ' --subsamp=4,2' ...
              ' --warpres=8,8,8' ...
              ' --miter=5,10' ...
              ' --infwhm=8,2' ...
              ' --reffwhm=4,0' ...
              ' --lambda=300,30' ...
              ' --estint=1,0' ...
              ' --ssqlambda=1' ...
              ' --regmod=bending_energy' ...
              ' --intmod=global_non_linear_with_bias' ...
              ' --intorder=5' ...
              ' --biasres=50,50,50' ...
              ' --biaslambda=10000' ...
              ' --refderiv=0' ...
              ' --applyrefmask=1,1' ...
              ' --applyinmask=1,1' ...
              ' --verbose'];

invwarpstage = [' --warp=', ea_path_helper(volumedir), warpprefix, 'WarpFiled.nii' ...
                ' --out=', ea_path_helper(volumedir), warpprefix, 'InverseWarpFiled.nii' ...
                ' --ref=', ea_path_helper(movingimage), ...
                ' --verbose'];

basedir = [fileparts(mfilename('fullpath')), filesep];
if ispc
    FNIRT = [basedir, 'fnirt.exe'];
    INVWARP = [basedir, 'invwarp.exe'];
else
    FNIRT = [basedir, 'fnirt.', computer('arch')];
    INVWARP = [basedir, 'invwarp.', computer('arch')];
end

fnirtcmd = [FNIRT, fnirtstage];
invwarpcmd = [INVWARP, invwarpstage];

setenv('FSLOUTPUTTYPE','NIFTI');
if ~ispc
    system(['bash -c "', fnirtcmd, '"']);
    system(['bash -c "', invwarpcmd, '"']);
else
    system(fnirtcmd);
    system(invwarpcmd);
end