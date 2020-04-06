import numpy as np
import sys
import scipy.io as sio
import pyrender
import trimesh
from PIL import Image
import open3d as o3d

def projectMesh(meshPath, f, R, t, sensorSize, ortho, mag):
    RGBcut, XYZcut, depth, XYZpts = projectMeshDebug(meshPath, f, R, t, sensorSize, ortho, mag, False)
    return RGBcut, XYZcut, depth

def projectMeshCached(scene, f, R, t, sensorSize, ortho, mag):
    RGBcut, XYZcut, depth, XYZpts = projectMeshCachedDebug(scene, f, R, t, sensorSize, ortho, mag, False)
    return RGBcut, XYZcut, depth

def buildXYZcut(sensorWidth, sensorHeight, t, cameraDirection, scaling, sensorXAxis, sensorYAxis, depth):
    # TODO: compute xs, ys only once (may not actually matter)
    ts = np.broadcast_to(t, (sensorHeight*sensorWidth, 3))
    camDirs = np.broadcast_to(cameraDirection, (sensorHeight*sensorWidth, 3))
    xs = np.arange(-int(sensorWidth/2), int(sensorWidth/2))
    xs = np.broadcast_to(xs, (sensorHeight, sensorWidth)).T
    xs = np.reshape(xs, (sensorHeight*sensorWidth, 1))
    xs = np.tile(xs, (1,3))
    ys = np.arange(-int(sensorHeight/2), int(sensorHeight/2))
    ys = np.broadcast_to(ys, (sensorWidth, sensorHeight))
    ys = np.reshape(ys, (sensorHeight*sensorWidth, 1))
    ys = np.tile(ys, (1,3))
    sensorXAxes = np.broadcast_to(sensorXAxis, (sensorHeight*sensorWidth, 3))
    sensorYAxes = np.broadcast_to(sensorYAxis, (sensorHeight*sensorWidth, 3))
    sensorPoints = ts + camDirs + scaling * np.multiply(xs, sensorXAxes) + scaling * np.multiply(ys, sensorYAxes)
    sensorDirs = sensorPoints - ts
    depths = np.reshape(depth.T, (sensorHeight*sensorWidth, 1))
    depths = np.tile(depths, (1,3))
    pts = ts + np.multiply(sensorDirs, depths)
    xyzCut = np.reshape(pts, (sensorHeight, sensorWidth, 3))
    return xyzCut, pts

def projectMeshCachedDebug(scene, f, R, t, sensorSize, ortho, mag, debug):
    # In OpenGL, camera points toward -z by default, hence we don't need rFix like in the MATLAB code
    sensorWidth = sensorSize[0]
    sensorHeight = sensorSize[1]
    fovHorizontal = 2*np.arctan((sensorWidth/2)/f)
    fovVertical = 2*np.arctan((sensorHeight/2)/f)

    if ortho:
        camera = pyrender.OrthographicCamera(xmag=mag, ymag=mag)
    else:
        camera = pyrender.PerspectiveCamera(fovVertical)

    camera_pose = np.eye(4)
    camera_pose[0:3,0:3] = R
    camera_pose[0:3,3] = t
    cameraNode = scene.add(camera, pose=camera_pose)

    scene._ambient_light = np.ones((3,))

    r = pyrender.OffscreenRenderer(sensorWidth, sensorHeight)
    meshProjection, depth = r.render(scene)

    # XYZ cut
    scaling = 1.0/f

    spaceCoordinateSystem = np.eye(3)

    sensorCoordinateSystem = np.matmul(R, spaceCoordinateSystem)
    sensorXAxis = sensorCoordinateSystem[:,0]
    sensorYAxis = -sensorCoordinateSystem[:,1]
    # make camera point toward -z by default, as in OpenGL
    cameraDirection = -sensorCoordinateSystem[:,2] # unit vector

    xyzCut, pts = buildXYZcut(sensorWidth, sensorHeight, t, cameraDirection, scaling,
                                sensorXAxis, sensorYAxis, depth)

    XYZpc = -1
    if debug:
        XYZpc = o3d.geometry.PointCloud()
        XYZpc.points = o3d.utility.Vector3dVector(pts)
    
    scene.remove_node(cameraNode)

    return meshProjection, xyzCut, depth, XYZpc

def projectMeshDebug(meshPath, f, R, t, sensorSize, ortho, mag, debug):
    trimeshScene = trimesh.load(meshPath)
    scene = pyrender.Scene.from_trimesh_scene(trimeshScene)
    return projectMeshCachedDebug(scene, f, R, t, sensorSize, ortho, mag, debug)

if __name__ == '__main__':
    debug = False
    if not debug:
        if len(sys.argv) != 3:
            print('Usage: python3 projectMesh.py <input path> <output path>')
            print('Example: python3 projectMesh.py input.mat output.mat')
            exit(1)
        inputPath = sys.argv[1]
        outputPath = sys.argv[2]
    else:
        inputPath = '/private/var/folders/n0/m5ngvx3920n720yl5v9px94h0000gn/T/tp9d64aadb_8996_4290_a8fd_af152c40a41a.mat'
        outputPath = 'output.mat'
        spacePc = o3d.io.read_point_cloud('/Volumes/GoogleDrive/Můj disk/ARTwin/InLocCIIRC_dataset/models/B-670/cloud - rotated.ply')

    inputData = sio.loadmat(inputPath, squeeze_me=True)
    meshPath = str(inputData['meshPath'])
    f = float(inputData['f'])
    R = inputData['R']
    t = inputData['t']
    sensorSize = inputData['sensorSize'].astype(np.int64) # avoid overflow, because they are uint16 by default
    ortho = inputData['ortho']
    mag = inputData['mag']

    RGBcut, XYZcut, depth, XYZpc = projectMeshDebug(meshPath, f, R, t, sensorSize, ortho, mag, debug)

    if debug:
        o3d.visualization.draw_geometries([spacePc, XYZpc])

    sio.savemat(outputPath, {'RGBcut': RGBcut, 'XYZcut': XYZcut, 'depth': depth})