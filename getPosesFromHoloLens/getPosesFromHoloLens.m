function posesFromHoloLens = getPosesFromHoloLens(orientationDelay, translationDelay, params)
    prevWarningState = warning();
    warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames');
    rawHoloLensPosesTable = readtable(params.holoLens.poses.path);
    warning(prevWarningState);

    nQueries = size(rawHoloLensPosesTable,1);
    cameraPosesWrtHoloLensCS = zeros(nQueries,4,4); % the indices are for queryIds and they start from 1 (not disorganized like ImgList)
    for i=1:nQueries
        t = [rawHoloLensPosesTable{i, 'Position_X'}; ...
                    rawHoloLensPosesTable{i, 'Position_Y'}; ...
                    rawHoloLensPosesTable{i, 'Position_Z'}];
        orientation = [rawHoloLensPosesTable{i, 'Orientation_W'}, ...
                        rawHoloLensPosesTable{i, 'Orientation_X'}, ...
                        rawHoloLensPosesTable{i, 'Orientation_Y'}, ...
                        rawHoloLensPosesTable{i, 'Orientation_Z'}];
        R = rotmat(quaternion(orientation), 'frame'); % what are the columns of R? 
            % Bases of WHAT wrt WHAT? (one of them is initial unknown HL CS, the other is HL camera CS)
            % -> it is most likely a rotation matrix from initial unknown HL CS to HL camera CS. i.e. the columns
            % are bases of initial unknown HL CS in HL camera CS coordinates

        % camera points to -z in HoloLens
        % see https://docs.microsoft.com/en-us/windows/mixed-reality/coordinate-systems-in-directx
        rFix = rotationMatrix([pi, 0.0, 0.0], 'ZYX');

        R1 = (rFix * R)';
        R2 = R' * rFix;
        Rd = R1-R2;
        eps = 1e-8;
        assert(all(Rd(:) < eps));

        cameraPositionWrtHoloLensCS = t';
        cameraOrientationWrtHoloLensCS = R2;

        pose = eye(4);
        pose(1:3,1:3) = cameraOrientationWrtHoloLensCS;
        pose(1:3,4) = cameraPositionWrtHoloLensCS;
        cameraPosesWrtHoloLensCS(i,:,:) = pose;
    end

    % recalculate HoloLens poses based on a (possible) delay
    cameraPosesWrtHoloLensCS2 = zeros(nQueries,4,4);
    for i=1:nQueries
        orientationDataIdx = i+orientationDelay;
        translationDataIdx = i+translationDelay;
        if (orientationDataIdx > nQueries || translationDataIdx > nQueries)
            pose = nan(4,4);
        else
            pose = eye(4);
            pose(1:3,1:3) = cameraPosesWrtHoloLensCS(orientationDataIdx,1:3,1:3);
            pose(1:3,4) = cameraPosesWrtHoloLensCS(translationDataIdx,1:3,4);
        end
        cameraPosesWrtHoloLensCS2(i,:,:) = pose;
    end
    cameraPosesWrtHoloLensCS = cameraPosesWrtHoloLensCS2;

    posesFromHoloLens = cameraPosesWrtHoloLensCS;
end