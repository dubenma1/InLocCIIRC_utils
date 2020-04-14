function distance = rotationDistance(R1, R2)
    R = R2*inv(R1); % residual rotation matrix
    distance = acos(0.5 * (trace(R)-1));
    distance = abs(rad2deg(distance));
end