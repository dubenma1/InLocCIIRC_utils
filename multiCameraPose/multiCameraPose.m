function [posesWrtModel] = multiCameraPose(workingDir, queryInd, cameraPoseWrtFirstCameraPose, ...
                                            correspondences2D, correspondences3D, ...
                                            inlierThreshold, numLoSteps, ...
                                            invertYZ, pointsCentered, undistortionNeeded, params)
    dataDir = workingDir;
    mkdirIfNonExistent(dataDir);
    matchesDir = fullfile(dataDir, 'matches');
    mkdirIfNonExistent(matchesDir);
    rigPath = fullfile(dataDir, 'camerasIntrinsicsAndExtrinsics.txt');
    outputPath = fullfile(dataDir, 'multiCameraPoseOutput.txt');

    %% save cameras intrinsics and extrinsics, in the MultiCameraPose format
    sensorSize = params.camera.sensor.size; % height, width
    imageWidth = sensorSize(2);
    imageHeight = sensorSize(1);

    rigFile = fopen(rigPath, 'w');
    k = size(queryInd,1); % the length of the sequence
    for i=1:k
        % intrinsics
        queryId = queryInd(i);
        fprintf(rigFile, '%d PINHOLE %f %f %f %f %f %f ', queryId, imageWidth, imageHeight, ...
                                                            params.camera.K(1,1), params.camera.K(2,2), ...
                                                            params.camera.K(1,3), params.camera.K(2,3));

        % extrinsics
        thisCameraPoseWrtFirstCameraPose = squeeze(cameraPoseWrtFirstCameraPose(i,:,:));
        thisOrientation = thisCameraPoseWrtFirstCameraPose(1:3,1:3);
        thisOrientation = thisOrientation'; % aka firstCameraCSBasesToCameraBases (as in rawPoseToPose) % TODO: is this necessary?

        thisOrientation = rotm2quat(thisOrientation); % this is the same as below code, provided 'point' is used
        %thisOrientation = quaternion(thisOrientation, 'rotmat', 'point'); % NOTE: assuming 'frame' is not the correct param
        %[A,B,C,D] = parts(thisOrientation);
        %thisOrientation = [A,B,C,D];

        thisPosition = thisCameraPoseWrtFirstCameraPose(1:3,4);
        fprintf(rigFile, '%f %f %f %f %f %f %f\n', thisOrientation, thisPosition);
    end
    fclose(rigFile);

    %% save 2D-3D correspondences
    for i=1:k
        queryId = queryInd(i);
        matchesPath = fullfile(matchesDir, sprintf('%d%s', queryId, '.individual_datasets.matches.txt'));
        matchesFile = fopen(matchesPath, 'w');
        nMatchesPerQuery = size(correspondences3D,3);
        for j=1:nMatchesPerQuery
            fprintf(matchesFile, '%f %f %f %f %f\n', correspondences2D(:,j), correspondences3D(i,:,j));
        end
        fclose(matchesFile);
    end

    %% call MultiCameraPose exe
    command = sprintf('"%s" "%s" "%s" %f %d %d %d %d %d "%s"', params.multiCameraPoseExe.path, rigPath, outputPath, ...
                        inlierThreshold, numLoSteps, ...
                        invertYZ, pointsCentered, undistortionNeeded, k, matchesDir);
    disp(command);
    [status, cmdout] = system(command);
    disp(cmdout);
    
    % load results
    %% TODO: process outputPath
    
    %% delete temporary files
    %TODO: rmdir(dataDir, 's');
    
 end
