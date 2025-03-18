% Matlab version 2024a
% Kinesis version 1.14.52
% 2025. 03. 06 
% Yong Guk Kang

% 2025. 03. 18 
% Fix bug related to load motor configuration
% add Error handler

classdef Kinesis < handle
    properties
        Device
        DeviceType
        SerialNumber
        Timeout
    end
    
    methods (Static)
        function obj = Generate(devicetype, serialNumber, timeout_val)
            % Kinesis 객체 생성 및 초기화
            obj = Kinesis(devicetype, serialNumber, timeout_val);
        end
    end
    
    methods
        function obj = Kinesis(deviceType, serialNumber, timeout_val)
            % 객체 생성자
            obj.SerialNumber = serialNumber;
            obj.Timeout = timeout_val;
            obj.DeviceType = deviceType;
            % Load .NET Assemblies
            assemblyPath = 'C:\Program Files\Thorlabs\Kinesis\';
            if exist(assemblyPath, 'dir')
                NET.addAssembly(fullfile(assemblyPath, 'Thorlabs.MotionControl.DeviceManagerCLI.dll'));
                NET.addAssembly(fullfile(assemblyPath, 'Thorlabs.MotionControl.GenericMotorCLI.dll'));
                NET.addAssembly(fullfile(assemblyPath, 'Thorlabs.MotionControl.KCube.DCServoCLI.dll'));
                NET.addAssembly(fullfile(assemblyPath, 'Thorlabs.MotionControl.KCube.StepperMotorCLI.dll'));
            else
                error('Kinesis DLL 경로를 확인하세요.');
            end
            
            import Thorlabs.MotionControl.DeviceManagerCLI.*
            import Thorlabs.MotionControl.GenericMotorCLI.*
            import Thorlabs.MotionControl.KCube.DCServoCLI.*
            import Thorlabs.MotionControl.KCube.StepperMotorCLI.*
            
            % Connect to device
            DeviceManagerCLI.BuildDeviceList();
            if strcmp(obj.DeviceType,'KCubeDCServo')
                obj.Device = KCubeDCServo.CreateKCubeDCServo(serialNumber);
            elseif strcmp(obj.DeviceType,'KCubeStepper')% Stepper Motor
                obj.Device = KCubeStepper.CreateKCubeStepper(serialNumber);
            else
                error('Unknown device type');
            end

            try
                % 접속 - 설정 load - 추가설정 - wait
                obj.Device.Connect(serialNumber);
                obj.Device.WaitForSettingsInitialized(obj.Timeout);
                obj.Device.StartPolling(250);
                fprintf("[%s] Device Connected : %s ...", obj.DeviceType, serialNumber);

                obj.Device.LoadMotorConfiguration(obj.SerialNumber);
                obj.Device.EnableDevice();
                obj.Device.SetHomingVelocity(2);

                % device_info = obj.Device.GetDeviceInfo();
                % fprintf("[%s] Device Enabled\n [%s]", obj.DeviceType, device_info.Description);
                obj.Device.WaitForSettingsInitialized(5000);
                fprintf("Device Enabled\n", obj.DeviceType);
            catch e
                % fprintf("Error: %s\n", e.message);
                % obj.disconnectStage();
                obj.ErrorHandler(e)
            end
        end
        
        function Homing(obj)
            % Home the device
            try
                fprintf("[%s] Homing...", obj.DeviceType);
                obj.Device.Home(obj.Timeout);
                while obj.Device.IsDeviceBusy()
                    pause(0.1);
                end
                fprintf("Homed\n");
            catch e
                % fprintf("Error: %s\n", e.message);
                % obj.disconnectStage();
                obj.ErrorHandler(e)
            end
        end
        
        function MoveAbsolute(obj, position)
            % Move to absolute position
            try
                fprintf("[%s] Moving Absolute...", obj.DeviceType);
                obj.Device.MoveTo(position, obj.Timeout);
                while obj.Device.IsDeviceBusy()
                    pause(0.1);
                end
                fprintf("Moved\n", obj.DeviceType);
            catch e
                % fprintf("Error: %s\n", e.message);
                % obj.disconnectStage();
                obj.ErrorHandler(e)
            end
        end
        
        function MoveRelative(obj, displacement)
            % Move relatively
            try
                fprintf("[%s] Moving Relative...", obj.DeviceType);
                CurrLoc = obj.GetPosition(); %System.Decimal.ToDouble(obj.Device.DevicePosition);
                obj.Device.MoveTo(CurrLoc + displacement, obj.Timeout);
                while obj.Device.IsDeviceBusy()
                    pause(0.1);
                end
                fprintf("Moved\n", obj.DeviceType);
            catch e
                % fprintf("Error: %s\n", e.message);
                % obj.disconnectStage();
                obj.ErrorHandler(e)
            end
        end
        
        function [CurrLoc] = GetPosition(obj)
            % Get current position
            CurrLoc = [];
            try
                CurrLoc = System.Decimal.ToDouble(obj.Device.DevicePosition);
                % fprintf("Current Location : %.2f mm \n\n", CurrLoc);
            catch e
                % fprintf("Error: %s\n", e.message);
                % obj.disconnectStage();
                obj.ErrorHandler(e)
            end
        end
        
        function [limitMin, limitMax] = GetLimits(obj)
            % Get current position
            limitMin=[];
            limitMax=[];
            try
               lim_params = obj.Device.AdvancedMotorLimits;
               limitMin = System.Decimal.ToDouble(lim_params.LengthMinimum);
               limitMax = System.Decimal.ToDouble(lim_params.LengthMaximum);
            catch e
                % fprintf("Error: %s\n", e.message);
                % obj.disconnectStage();
                obj.ErrorHandler(e)
            end
        end

        function [maxV, accel] = GetVelocity(obj)
            % Get current velocity
            maxV = [];
            accel = [];
            try
                vel_params = obj.Device.GetVelocityParams;
                maxV = System.Decimal.ToDouble(vel_params.MaxVelocity);
                accel = System.Decimal.ToDouble(vel_params.Acceleration);
                % fprintf('Velocity: %.2f , Acceleration: %.2f\n\n', maxV, accel);
            catch e
                % fprintf("Error: %s\n", e.message);
                % obj.disconnectStage();
                obj.ErrorHandler(e)
            end
        end
        
        function SetVelocity(obj, maxV, accel)
            % Set velocity and acceleration
            try
                obj.Device.SetVelocityParams(maxV, accel);
            catch e
                % fprintf("Error: %s\n", e.message);
                % obj.disconnectStage();
                obj.ErrorHandler(e)
            end
        end

        function disconnectStage(obj)
            % Disconnect and clean up device
            try
                obj.Device.StopPolling();
                obj.Device.Disconnect();
                delete(obj.Device); % 객체 강제 삭제
                fprintf("[%s] Device Disconnected & deleted \n" , obj.DeviceType);
            catch e
                fprintf("Error: %s\n", e.message);
            end
        end
        
        function delete(obj)
            % Destructor to ensure cleanup
            obj.disconnectStage();
        end

        function ErrorHandler(obj, errorHandle)
            getID = errorHandle.identifier;
            switch getID
                case 'MATLAB:NET:CLRException:MethodInvoke'
                    warning('\n **Please check the position Limit**');
                otherwise
                    warning('Unknown Error : Disconnecting Stage');
                    obj.disconnectStage();
            end

        end
    end
end