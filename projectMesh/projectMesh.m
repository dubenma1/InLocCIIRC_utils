function [RGBcut, XYZcut, depth] = projectMesh(meshPath, f, R, t, sensorSize, ortho, mag, projectMeshPyPath, headless)
% TODO: support outputSize param. Then interpolation may be necessary for the XYZcut

inputPath = strcat(tempname, '.mat');
outputPath = strcat(tempname, '.mat');
save(inputPath, 'meshPath', 'f', 'R', 't', 'sensorSize', 'ortho', 'mag');

% call projectMesh.py
if headless
    command = sprintf('PATH=/usr/local/bin:$PATH PYOPENGL_PLATFORM=osmesa python3 "%s" %s %s', projectMeshPyPath, inputPath, outputPath);
else
    command = sprintf('PATH=/usr/local/bin:$PATH python3 "%s" %s %s', projectMeshPyPath, inputPath, outputPath);
end

disp(command)
[status, cmdout] = system(command);
disp(cmdout)

% load results
load(outputPath, 'RGBcut', 'XYZcut', 'depth')

% delete temporary files
delete(inputPath);
delete(outputPath);

end
