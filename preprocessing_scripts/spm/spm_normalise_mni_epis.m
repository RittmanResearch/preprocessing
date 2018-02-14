function spm_normalise_mni_epis(template,inflowfield,inepiimages,instructural)
%Warp inepiimages images using flowfield inflowfield and template. Also warp the corresponding structural.

clear matlabbatch
 
matpath='/applications/spm/spm12_6909';
addpath(genpath(matpath));
% disp('The path is')
% path

spm('defaults','pet');
 spm_jobman('initcfg');
 
fprintf('\nTemplate is %s', template);
%disp(['Mean is ' inmeanimage]);
disp(['Flowfield is ' inflowfield]);
disp(['Structural is ' instructural]);

vox=[2 2 2];
bbox= [-90 -126 -72
        90 90 108];
sk1=[0 0 0];  
sk2=[0 0 0]; 

preservewhat=0; %0=conc;1=amount

[apath,inepiimage,anext]=fileparts(inepiimages);

disp(['path is ' apath])
%disp(inepiimagesimagesexp)

%For 3D
%inepiimagesimages=spm_select('FPList',apath,inepiimagesimagesexp);
%For 4D
%inepiimagesimages=spm_select('ExtFPList',apath,inepiimagesimagesexp,1:1000);
inepiimages_all=spm_select('ExtFPList',apath,strcat(inepiimages,'.nii'),1:1000);
disp(inepiimages_all)

nimages=size(inepiimages_all,1);
%Do everything together
%images=deblank(char(inmeanimage,inepiimagesimages));
%disp(images)

% template=template(1:end-2);
% inflowfield=inflowfield(1:end-2);
% instructural=instructural(1:end-2);

%-----------------------------------------------------------------------
% Job saved on 01-Oct-2014 13:34:11 by cfg_util (rev $Rev: 5797 $)
% spm SPM - SPM12b (5892)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
%for ii=1:nimages
ib = 1;

matlabbatch{ib}.spm.tools.dartel.mni_norm.template = {template};
matlabbatch{ib}.spm.tools.dartel.mni_norm.data.subj.flowfield = {inflowfield};
matlabbatch{ib}.spm.tools.dartel.mni_norm.data.subj.images = cellstr(inepiimages);
matlabbatch{ib}.spm.tools.dartel.mni_norm.vox = vox;
matlabbatch{ib}.spm.tools.dartel.mni_norm.bb = bbox;
matlabbatch{ib}.spm.tools.dartel.mni_norm.preserve = preservewhat;
matlabbatch{ib}.spm.tools.dartel.mni_norm.fwhm = sk1;
ib=ib+1;

matlabbatch{ib}.spm.tools.dartel.mni_norm.template = {template};
matlabbatch{ib}.spm.tools.dartel.mni_norm.data.subj.flowfield = {inflowfield};
matlabbatch{ib}.spm.tools.dartel.mni_norm.data.subj.images = cellstr(instructural);
matlabbatch{ib}.spm.tools.dartel.mni_norm.vox = vox;
matlabbatch{ib}.spm.tools.dartel.mni_norm.bb = bbox;
matlabbatch{ib}.spm.tools.dartel.mni_norm.preserve = preservewhat;
matlabbatch{ib}.spm.tools.dartel.mni_norm.fwhm = sk2;

% job.template = {template};
% job.data.subj.flowfield = {inflowfield};
% job.data.subj.images = cellstr(instructural);
% job.vox = vox;
% job.bb = bbox;
% job.preserve = preservewhat;
% job.fwhm = sk2;
spm_jobman('run',matlabbatch);
% spm_dartel_norm_fun(job);
%end

disp('Finished warping')
