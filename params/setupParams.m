function [ params ] = setupParams(mode)
    % mode is one of {'s10e', 'holoLens1', 'holoLens2'}
    % NOTE: the number after 'holoLens' is a sequence number, not a version of HoloLens glasses!

thisScriptPath = fileparts(mfilename('fullpath'));
addpath([thisScriptPath, '../environment']);

params = struct();
env = environment();

if strcmp(env, 'laptop')
    params.dataset.dir = '/Volumes/GoogleDrive/Můj disk/ARTwin/InLocCIIRC_dataset';
    params.netvlad.dataset.dir = '/Volumes/GoogleDrive/Můj disk/ARTwin/InLocCIIRC_dataset/NetVLAD';
elseif strcmp(env, 'cmp')
    params.dataset.dir = '/mnt/datagrid/personal/lucivpav/InLocCIIRC_dataset';
    params.netvlad.dataset.dir = '/mnt/datagrid/personal/lucivpav/NetVLAD';
elseif strcmp(env, 'ciirc')
    params.dataset.dir = '/home/lucivpav/InLocCIIRC_dataset';
    params.netvlad.dataset.dir = '/home/lucivpav/NetVLAD';
else
    error('Unrecognized environment');
end

params.netvlad.dataset.pretrained = fullfile(params.netvlad.dataset.dir, 'vd16_pitts30k_conv5_3_vlad_preL2_intra_white.mat');

if strcmp(mode, 's10e')
    params = s10eParams(params);
elseif strcmp(mode, 'holoLens1')
    params = holoLens1Params(params);
elseif strcmp(mode, 'holoLens2')
    params = holoLens2Params(params);
else
    error('Unrecognized mode');
end

params.mode = mode;
params.spaceName = 'B-315'; % TODO: this should be a  propery of the queries - where they were taken
params.dataset.models.dir = fullfile(params.dataset.dir, 'models');
params.pointCloud.path = fullfile(params.dataset.models.dir, params.spaceName, 'cloud - rotated.ply');
params.projectPointCloudPy.path = [thisScriptPath, '../projectPointsCloud/projectPointCloud.py'];
params.reconstructPosePy.path = [thisScriptPath, '../reconstructPose/reconstructPose.py'];
params.dataset.query.dir = fullfile(params.dataset.dir, params.dataset.query.dirname);
params.projectedPointCloud.dir = fullfile(params.dataset.query.dir, 'projectedPointCloud');
params.poses.dir = fullfile(params.dataset.query.dir, 'poses');
params.queryDescriptions.path = fullfile(params.dataset.query.dir, 'descriptions.csv');
params.rawPoses.path = fullfile(params.dataset.query.dir, 'rawPoses.csv');
params.inMap.tDiffMax = 1.3;
params.inMap.rotDistMax = 10; % in degrees
params.renderClosestCutouts = false;
params.closest.cutout.dir = fullfile(params.dataset.query.dir, 'closestCutout');
params.vicon.origin.wrt.model = [-0.13; 0.04; 2.80];
params.vicon.rotation.wrt.model = deg2rad([90.0 180.0 0.0]);

params.camera.K = eye(3);
params.camera.K(1,1) = params.camera.fl;
params.camera.K(2,2) = params.camera.fl;
params.camera.K(1,3) = params.camera.sensor.size(2)/2;
params.camera.K(2,3) = params.camera.sensor.size(1)/2;

%database
params.dataset.db.space_names = {'B-670', 'B-315'};
%%scan
params.dataset.db.scan.dir = 'scans';
params.dataset.db.scan.matformat = '.ptx.mat';
%%cutouts
params.dataset.db.cutout.dirname = 'cutouts';
params.dataset.db.cutouts.dir = fullfile(params.dataset.dir, params.dataset.db.cutout.dirname);
params.dataset.db.cutout.imgformat = '.jpg';
params.dataset.db.cutout.matformat = '.mat';

%%alignments
params.dataset.db.trans.dir = fullfile(params.dataset.dir, 'alignments');
%query
params.dataset.query.imgformat = '.jpg';

%input
params.input.dir = fullfile(params.dataset.dir, 'inputs');

params.input.dblist.path = fullfile(params.input.dir, 'cutout_imgnames_all.mat');%string cell containing cutout image names
params.input.qlist.path = fullfile(params.input.dir, 'query_imgnames_all.mat');%string cell containing query image names
params.input.scores.path = fullfile(params.input.dir, 'scores.mat');%retrieval score matrix

params.input.feature.dir = fullfile(params.input.dir, 'features');
params.input.feature.db_matformat = '.features.dense.mat';
params.input.feature.q_matformat = '.features.dense.mat';
params.input.feature.db_sps_matformat = '.features.sparse.mat';
params.input.feature.q_sps_matformat = '.features.sparse.mat';
params.input.projectMesh_py_path = fullfile([thisScriptPath, '../projectMesh/projectMesh.py');

%output
params.output.dir = fullfile(params.dataset.dir, 'outputs');
params.output.gv_dense.dir = fullfile(params.output.dir, 'gv_dense');%dense matching results (directory)
params.output.gv_dense.matformat = '.gv_dense.mat';%dense matching results (file extention)
params.output.gv_sparse.dir = fullfile(params.output.dir, 'gv_sparse');%sparse matching results (directory)
params.output.gv_sparse.matformat = '.gv_sparse.mat';%sparse matching results (file extention)

params.output.pnp_dense_inlier.dir = fullfile(params.output.dir, 'PnP_dense_inlier');%PnP results (directory)
params.output.pnp_dense.matformat = '.pnp_dense_inlier.mat';%PnP results (file extention)
params.output.pnp_sparse_inlier.dir = fullfile(params.output.dir, 'PnP_sparse_inlier');%PnP results (directory)
params.output.pnp_sparse_inlier.matformat = '.pnp_sparse_inlier.mat';%PnP results (file extention)

params.output.pnp_sparse_origin.dir = fullfile(params.output.dir, 'PnP_sparse_origin');%PnP results (directory)
params.output.pnp_sparse_origin.matformat = '.pnp_sparse_origin.mat';%PnP results (file extention)

params.output.synth.dir = fullfile(params.output.dir, 'synthesized');%View synthesis results (directory)
params.output.synth.matformat = '.synth.mat';%View synthesis results (file extention)

% evaluation
params.evaluation.dir = fullfile(params.dataset.dir, 'evaluation');
params.evaluation.query_vs_synth.dir = fullfile(params.evaluation.dir, 'queryVsSynth');
params.evaluation.errors.path = fullfile(params.evaluation.dir, 'errors.csv');
params.evaluation.summary.path = fullfile(params.evaluation.dir, 'summary.txt');
params.evaluation.retrieved.poses.dir = fullfile(params.evaluation.dir, 'retrievedPoses');
params.evaluation.retrieved.queries.path = fullfile(params.evaluation.dir, 'retrievedQueries.csv');

% NOTE: this snippet might be expensive
load(params.input.dblist_matname, 'cutout_imgnames_all');
params.dataset.db.cutout.size = size(imread(fullfile(params.dataset.db.cutouts.dir, cutout_imgnames_all{1})));
params.dataset.db.cutout.size = [params.data.db.cutout.size(2), params.dataset.db.cutout.size(1)]; % width, heigh

end