function M=ea_initializeM
M=struct;
M.patient.list={};
M.patient.group=[];

M.clinical.vars={};
M.clinical.labels={};
M.vilist={};
M.fclist={};
M.ui=struct;
M.ui.listselect=1;
M.ui.elrendeting=1;
M.ui.clinicallist=1;
M.ui.hlactivecontcheck=0;
M.ui.showpassivecontcheck=1;
M.ui.showactivecontcheck=1;
M.ui.showisovolumecheck=0;
M.ui.isovscloudpopup=1;
M.ui.atlassetpopup=1;
M.ui.fiberspopup=3;
M.ui.labelpopup=1;
M.ui.volumeintersections=1;
M.ui.fibercounts=1;
M.ui.elrendering=1;
M.ui.statvat=0;
M.ui.elmodelselect=1;
M.ui.detached=0;
M.ui.normregpopup=1;
M.ui.colorpointcloudcheck=0;
M.ui.lc.graphmetric=1;
M.ui.lc.normalization=1;
M.ui.lc.smooth=1;

M.S=[];
M.vatmodel=[];