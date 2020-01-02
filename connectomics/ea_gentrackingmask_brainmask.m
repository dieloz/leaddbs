function ea_gentrackingmask_brainmask(options,threshold)
directory=[options.root,options.patientname,filesep];

%ea_newseg(directory,options.prefs.prenii_unnormalized,0,options);
copyfile([ea_space,'brainmask.nii.gz'],[directory,'brainmask.nii.gz']);
gunzip([directory,'brainmask.nii.gz']);
ea_delete([directory,'brainmask.nii.gz']);
ea_apply_normalization_tofile(options, {[directory,'brainmask.nii']}, {[directory,'wbrainmask.nii']}, directory, 1, 0);

ea_delete([directory,'brainmask.nii']);

b0_anat = [ea_stripext(options.prefs.b0),'_',ea_stripext(options.prefs.prenii_unnormalized)];

if exist([directory,'ea_coreg_approved.mat'], 'file')
    isapproved = load([directory,'ea_coreg_approved.mat']);
    if isfield(isapproved, b0_anat)
        isapproved = isapproved.(b0_anat);
    else
        isapproved = 0;
    end
else
    isapproved = 0;
end

if ~isapproved
    fprintf(['\nCoregistration between b0 and anat not done or not approved yet!\n', ...
             'Will do the coregistration using the method chosen from GUI.\n\n'])
    if exist([directory,'ea_coregmrmethod_applied.mat'], 'file')
        coregmrmethod = load([directory,'ea_coregmrmethod_applied.mat']);
    end
    coregmrmethod.(b0_anat) = options.coregmr.method;
    save([directory,'ea_coregmrmethod_applied.mat'],'-struct','coregmrmethod');
    docoreg = 1;
else
    if exist([directory,'ea_coregmrmethod_applied.mat'], 'file')
        coregmrmethod = load([directory,'ea_coregmrmethod_applied.mat']);
        if isfield(coregmrmethod, b0_anat) && ~isempty(coregmrmethod.(b0_anat))
            transform = [ea_stripext(options.prefs.prenii_unnormalized), '2', ea_stripext(options.prefs.b0), ...
                         '_', lower(strrep(coregmrmethod.(b0_anat), 'Hybrid SPM & ', '')), '\d*\.(mat|h5)$'];
            transform = ea_regexpdir(directory, transform, 0);

            if isempty(transform) % Approved but the transformation file not found
                fprintf(['\nThe coregistration between b0 and anat using ''%s'' has been approved.\n', ...
                         'But the tranformation file doesn''t exist!\n', ...
                         'Will redo the coregistration using ''%s''.\n\n'], ...
                         coregmrmethod.(b0_anat), coregmrmethod.(b0_anat));
                docoreg = 1;
            else % Approved and the transformation file found
                transform = transform{end};
                fprintf(['\nThe coregistration between b0 and anat using ''%s'' has been approved.\n', ...
                         'Will use this transform to generate the fiber tracking mask:\n', ...
                         '%s\n\n'], coregmrmethod.(b0_anat), transform);
                docoreg = 0;
            end
            options.coregmr.method = coregmrmethod.(b0_anat);
        else % 'ea_coregmrmethod_applied.mat' found but method not set, redo coreg use method from GUI
            fprintf(['\nThe coregistration between b0 and anat has been approved.\n', ...
                     'But it is not clear which method has been used.\n', ...
                     'Will redo the coregistration using the method chosen from GUI.\n\n']);
            coregmrmethod.(b0_anat) = options.coregmr.method;
            save([directory,'ea_coregmrmethod_applied.mat'],'-struct','coregmrmethod');
            docoreg = 1;
        end
    else % 'ea_coregmrmethod_applied.mat' not found, redo coreg use method from GUI
        fprintf(['\nThe coregistration between b0 and anat has been approved.\n', ...
                 'But it is not clear which method has been used.\n', ...
                 'Will redo the coregistration using the method chosen from GUI.\n\n']);
        coregmrmethod.(b0_anat) = options.coregmr.method;
        save([directory,'ea_coregmrmethod_applied.mat'],'-struct','coregmrmethod');
        docoreg = 1;
    end
end

if docoreg
    copyfile([directory,'wbrainmask.nii'],[directory,'wcbrainmask.nii']);
    affinefile = ea_coreg2images(options, ...
        [directory,options.prefs.prenii_unnormalized], ... % moving
        [directory,options.prefs.b0], ... % fix
        [directory,'c',options.prefs.prenii_unnormalized], ... % out
        {[directory,'wcbrainmask.nii']}, ... % other
        1); % writeout transform

    % Rename saved transform for further use: canat2b0*.mat to anat2b0*.mat,
    % and b02canat*.mat to b02anat*.mat
    [~, anat] = ea_niifileparts(options.prefs.prenii_unnormalized);
    if ~isempty(affinefile)
        for i = 1:numel(affinefile)
            movefile(affinefile{i}, strrep(affinefile{i}, ['c',anat], anat));
        end
    end

    movefile([directory,'wcbrainmask.nii'],[directory,'trackingmask.nii']);
    delete([directory,'c',options.prefs.prenii_unnormalized]);
else
    % Reuse approved coregistration
    copyfile([directory,'wbrainmask.nii'],[directory,'wcbrainmask.nii']);
    %    spm_smooth([directory,'cc2',options.prefs.prenii_unnormalized],[directory,'cc2',options.prefs.prenii_unnormalized],[6 6 6]);
    
    ea_apply_coregistration([directory,options.prefs.b0], [directory,'wcbrainmask.nii'], ...
        [directory,'trackingmask.nii'], transform);
end
ea_delete([directory,'wcbrainmask.nii']);
ea_delete([directory,'wbrainmask.nii']);

tr=ea_load_nii([options.root,options.patientname,filesep,'trackingmask.nii']);
if threshold
    tr.img=tr.img>0.1;
    tr.fname=[options.root,options.patientname,filesep,'ttrackingmask.nii'];
    ea_write_nii(tr);
end

% Transform anat to b0 to generate checkreg image:
ea_apply_coregistration([directory,options.prefs.b0], [directory,options.prefs.prenii_unnormalized], ...
                        [directory,b0_anat,'.nii'], strrep(options.coregmr.method, 'Hybrid SPM & ', ''));
