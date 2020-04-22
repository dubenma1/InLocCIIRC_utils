import numpy as np
import matplotlib.pyplot as plt
from projectMesh import projectMesh
from scipy.spatial.transform import Rotation
import sys
import os
sys.path.insert(1, os.path.join(sys.path[0], '..'))
from load_CIIRC_transformation.load_CIIRC_transformation import load_CIIRC_transformation

meshPath = '/Volumes/GoogleDrive/Můj disk/ARTwin/Matterport3D/scene_datasets/mp3d/1pXnuDYAj8r/1pXnuDYAj8r_semantic.ply'
posePath = '/Volumes/GoogleDrive/Můj disk/ARTwin/personal/lucivpav/habitat/poses/28.txt'
f = 1015.28

P = load_CIIRC_transformation(posePath)
R = P[0:3,0:3]
t = P[0:3,3]
t = -np.linalg.inv(R) @ t

rotationMatrix = Rotation.from_euler('xyz', np.array([90.0, 0.0, 0.0]), degrees=True).as_matrix() # y in poses data is actually z in .ply model
R = rotationMatrix @ R
t = rotationMatrix @ t

print(f'Position: {t}')

sensorSize = np.array([1344, 756])

RGBcut, XYZcut, depth = projectMesh(meshPath, f, R, t, sensorSize, False, -1)

plt.figure()
plt.imshow(RGBcut)

#plt.figure()
#plt.imshow(depth)
#
#plt.figure()
#plt.title('Orthographic projection')
#RGBcut, XYZcut, depth = projectMesh(meshPath, f, R, t, sensorSize, True, 3.0)
#plt.imshow(RGBcut)

plt.show()