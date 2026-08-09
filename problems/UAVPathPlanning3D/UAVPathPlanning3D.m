classdef UAVPathPlanning3D < PROBLEM
% <single> <real> <expensive>
% 500-D three-dimensional UAV trajectory planning with soft penalties.

    properties
        scenarioId
        startPosition
        endPosition
    end

    methods
        function Setting(obj)
            [obj.scenarioId,obj.startPosition,obj.endPosition] = ...
                obj.ParameterSet(1,[0,0,50],[200,200,100]);
            if isempty(obj.D)
                obj.D = 500;
            end
            if mod(obj.D,2) ~= 0
                error('UAVPathPlanning3D:OddDimension','D must be even: D/2 y values and D/2 z values.');
            end
            if ~ismember(obj.scenarioId,1:3)
                error('UAVPathPlanning3D:Scenario','The paper uses scenario 1, 2, or 3.');
            end
            middleCount = obj.D/2;
            obj.M = 1;
            obj.lower = [repmat(-50,1,middleCount),repmat(10,1,middleCount)];
            obj.upper = [repmat(250,1,middleCount),repmat(300,1,middleCount)];
            obj.encoding = ones(1,obj.D);
        end

        function objective = CalObj(obj,decisions)
            objective = zeros(size(decisions,1),1);
            for i = 1:size(decisions,1)
                path = UAVPathPlanning3D.DecodeTrajectory(decisions(i,:), ...
                    obj.startPosition,obj.endPosition,300);
                segment = diff(path,1,1);
                distanceCost = sum(sqrt(sum(segment.^2,2)));
                [threatCost,collisionCost] = UAVPathPlanning3D.ObstacleCost( ...
                    path(:,1),path(:,2),path(:,3),obj.scenarioId);
                altitudeCost = sum(abs(diff(path(:,3))));
                smoothCost = UAVPathPlanning3D.SmoothnessCost(segment);
                objective(i) = distanceCost + 20*threatCost + 1e4*collisionCost ...
                    + 0.5*altitudeCost + 10*smoothCost;
            end
        end
    end

    methods(Static)
        function path = DecodeTrajectory(decision,startPosition,endPosition,sampleCount)
            decision = decision(:)';
            middleCount = numel(decision)/2;
            middleY = decision(1:middleCount);
            middleZ = decision(middleCount+1:end);
            fixedX = linspace(startPosition(1),endPosition(1),middleCount+2);
            controls = [fixedX',[startPosition(2),middleY,endPosition(2)]', ...
                [startPosition(3),middleZ,endPosition(3)]'];
            knots = 1:size(controls,1);
            query = linspace(1,size(controls,1),sampleCount);
            path = [spline(knots,controls(:,1),query)', ...
                spline(knots,controls(:,2),query)', ...
                spline(knots,controls(:,3),query)'];
        end

        function cost = SmoothnessCost(segments)
            cost = 0;
            maximumAngle = pi/4;
            for i = 2:size(segments,1)
                v1 = segments(i-1,:);
                v2 = segments(i,:);
                cosine = dot(v1,v2)/(norm(v1)*norm(v2)+1e-8);
                angle = acos(min(1,max(-1,cosine)));
                cost = cost + angle + 100*max(0,angle-maximumAngle)^2;
            end
        end

        function height = TerrainHeight(x,y,scenario)
            switch scenario
                case 1
                    height = 120*exp(-((x-60).^2+(y-80).^2)/1500) ...
                        + 160*exp(-((x-140).^2+(y-140).^2)/2000) ...
                        + 90*exp(-((x-160).^2+(y-50).^2)/1000);
                case 2
                    height = 150*exp(-((x-100).^2+(y-40).^2)/3000) ...
                        + 150*exp(-((x-100).^2+(y-160).^2)/3000);
                case 3
                    height = 130*exp(-((x-50).^2+(y-150).^2)/800) ...
                        + 140*exp(-((x-100).^2+(y-100).^2)/1200) ...
                        + 120*exp(-((x-150).^2+(y-150).^2)/800) ...
                        + 110*exp(-((x-150).^2+(y-50).^2)/800);
            end
        end

        function zones = RestrictedZones(scenario)
            switch scenario
                case 1
                    zones = [50,60,0,45,100;120,140,0,50,150;150,70,0,40,120];
                case 2
                    zones = [60,100,0,40,120;140,100,0,40,120];
                case 3
                    zones = [100,100,0,55,180;40,160,0,35,100;160,40,0,35,100];
            end
        end

        function [threatCost,collisionCost] = ObstacleCost(x,y,z,scenario)
            terrain = UAVPathPlanning3D.TerrainHeight(x,y,scenario);
            collisionCost = sum(max(0,terrain+15-z).^2);
            zones = UAVPathPlanning3D.RestrictedZones(scenario);
            threatCost = 0;
            for i = 1:numel(x)
                for j = 1:size(zones,1)
                    distance = norm([x(i),y(i),z(i)]-zones(j,1:3));
                    if distance < zones(j,4)
                        threatCost = threatCost + zones(j,5)*(1-distance/zones(j,4))^4;
                    end
                end
            end
        end
    end
end

