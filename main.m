%% Example code of Kinesis Wrapper for MATLAB
% Current support : KCubeDCServo, KCubeStepper
% Matlab version 2024a
% Kinesis version 1.14.52
% 2025. 03. 06 
% Yong Guk Kang

% Kinesis.m class

%% Initialize and enable
deviceX = Kinesis('KCubeStepper','26005738', 50000);
deviceZ = Kinesis('KCubeDCServo','27269776', 50000);

%% Homing

deviceX.Homing();
deviceZ.Homing();


%% Relative/ Absolute motion
currX = deviceX.GetPosition();
fprintf('CurrentLoc : %f, Axis : %s\n', currX, deviceX.DeviceType);
currZ = deviceZ.GetPosition();
fprintf('CurrentLoc : %f, Axis : %s\n', currZ, deviceZ.DeviceType);

deviceX.MoveAbsolute(5);
deviceZ.MoveAbsolute(5);

currX = deviceX.GetPosition();
fprintf('CurrentLoc : %f, Axis : %s\n', currX, deviceX.DeviceType);
currZ = deviceZ.GetPosition();
fprintf('CurrentLoc : %f, Axis : %s\n', currZ, deviceZ.DeviceType);

deviceZ.MoveRelative(3);
deviceZ.MoveRelative(3);

currX = deviceX.GetPosition();
fprintf('CurrentLoc : %f, Axis : %s\n', currX, deviceX.DeviceType);
currZ = deviceZ.GetPosition();
fprintf('CurrentLoc : %f, Axis : %s\n', currZ, deviceZ.DeviceType);

%% error and check axis limits : not disconnection

deviceX.MoveAbsolute(-1);
[limitMin, limitMax] = deviceX.GetLimits();
fprintf('limitMin : %f, limitMax : %f\n', limitMin, limitMax);
[limitMin, limitMax]  = deviceZ.GetLimits();
fprintf('limitMin : %f, limitMax : %f\n', limitMin, limitMax);


currX = deviceX.GetPosition();
fprintf('CurrentLoc : %f, Axis : %s\n', currX, deviceX.DeviceType);
currZ = deviceZ.GetPosition();
fprintf('CurrentLoc : %f, Axis : %s\n', currZ, deviceZ.DeviceType);

deviceX.MoveAbsolute(10);
currX = deviceX.GetPosition();
fprintf('CurrentLoc : %f, Axis : %s\n', currX, deviceX.DeviceType);
currZ = deviceZ.GetPosition();
fprintf('CurrentLoc : %f, Axis : %s\n', currZ, deviceZ.DeviceType);


%% get limits 
[limitMin, limitMax] = deviceX.GetLimits();
fprintf('limitMin : %f, limitMax : %f\n', limitMin, limitMax);
[limitMin, limitMax]  = deviceZ.GetLimits();
fprintf('limitMin : %f, limitMax : %f\n', limitMin, limitMax);

%% Speed profile

% maxV, accel
[mV, aC] = deviceX.GetVelocity();
fprintf('Max Velocity : %f, Accel : %f\n', mV, aC);
[mV, aC] = deviceZ.GetVelocity();
fprintf('Max Velocity : %f, Accel : %f\n', mV, aC);

deviceX.MoveRelative(1);
deviceZ.MoveRelative(1);
deviceX.MoveRelative(-1);
deviceZ.MoveRelative(-1);

% Changing dynamics
deviceX.SetVelocity(2, 2);
deviceZ.SetVelocity(2, 2);

[mV, aC] = deviceX.GetVelocity();
fprintf('Max Velocity : %f, Accel : %f\n', mV, aC);
[mV, aC] = deviceZ.GetVelocity();
fprintf('Max Velocity : %f, Accel : %f\n', mV, aC);

deviceX.MoveRelative(1);
deviceZ.MoveRelative(1);
deviceX.MoveRelative(-1);
deviceZ.MoveRelative(-1);

%% Execute
delete(deviceX);
delete(deviceZ);
