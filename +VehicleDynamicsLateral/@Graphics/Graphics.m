%% Graphics
% Functions for graphics generation.
%
%% Code
%

classdef Graphics
	methods
        % Constructor
        function self = Graphics(varargin)
            v = VehicleDynamicsLateral.VehicleArticulatedNonlinear4DOF;
            if nargin == 0
                self.vehicle = v;%.params;
            else
                self.vehicle = varargin{1};%.params;
            end
        end

        %% Animation
        % Animates the manoever.
        %
        % *Sintax*
        %
        % |_GraphicsClass_.Animation(XOUT,TOUT,saveit)|
        %
        % *Arguments*
        %
        % The following table describes the input arguments:
        %
        % <html> <table border=1 width="97%">
        % <tr> <td width="30%"><tt>XOUT</tt></td> <td width="70%">Solution array. Each column corresponds to the solution of each state variable of the vehicle. The columns must respect the following variable order: [XT YT PSI dPSI VT ALPHAT (PHI dPHI)] </td> </tr>
        % <tr> <td width="30%"><tt>TOUT</tt></td> <td width="70%">Column vector of time points.</td> </tr>
        % <tr> <td width="30%"><tt>saveit</tt></td> <td width="70%">Flag for saving the animation in a gif file. If savit = 0 the animation will not be saved. If savit = 1 a file Animacao.gif is generated.</td> </tr>
        % </table> </html>
        %
        % *Description*
        %
        % TEXT

        function Animation(self,XOUT,TOUT,saveit)
            % Verifying number of columns of the state output matrix
            % col = 6 -> simples
            % col = 8 -> articulado
            [col] = size(XOUT,2);

            % States
            XT = XOUT(:,1);                 % Horizontal position [m]
            YT = XOUT(:,2);                 % Vertical position [m]
            PSI = XOUT(:,3);                % Vehicle yaw angle [rad]
            dPSI = XOUT(:,4);               % Yaw rate [rad/s]
            VT = XOUT(:,5);                 % Vehicle CG velocity [m/s]
            ALPHAT = XOUT(:,6);             % Vehicle side slip angle [rad]

            % Distances
            a = self.vehicle.distFT;        % Distance FT [m]
            b = self.vehicle.distTR;        % Distance TR [m]
            lT = self.vehicle.width / 2;    % Half width of the vehicle [m]

            % Slip angle @ front axle [rad]
            ALPHAF = atan2((a*dPSI + VT.*sin(ALPHAT)),(VT.*cos(ALPHAT)));
            % OBS: No steering angle because it measures the angle between velocity vector and longitudinal axle of the vehicle
            % Slip angle @ rear axle [rad]
            ALPHAR = atan2((-b*dPSI + VT.*sin(ALPHAT)),(VT.*cos(ALPHAT)));
            % OBS: When using atan2 and the value reaches 180 degrees the vector becomes strange

            % Velocity @ front axle [m/s]
            VF = sqrt((VT.*cos(ALPHAT)).^2 + (a*dPSI + VT.*sin(ALPHAT)).^2);
            % Velocity @ rear axle [m/s]
            VR = sqrt((VT.*cos(ALPHAT)).^2 + (-b*dPSI + VT.*sin(ALPHAT)).^2);

            % Position of the corners and axles relative to the CG

            % Position vectors 1, 2, 3 e 4 relative to T base (T t1 t2 t3)
            rt1t = [a;lT];                  % Front left
            rt2t = [a;-lT];                 % Front right
            rt3t = [-b;-lT];                % Rear right
            rt4t = [-b;lT];                 % Rear left

            eif = [a;0];                    % Front axle
            eir = [-b;0];                   % Rear axle

            % Absolute position of corners and axles
            % Movement of the points from change of orientation.

            % Preallocating matrix
            rt1i = zeros(length(TOUT),2);
            rt2i = zeros(length(TOUT),2);
            rt3i = zeros(length(TOUT),2);
            rt4i = zeros(length(TOUT),2);

            eff = zeros(length(TOUT),2);
            err = zeros(length(TOUT),2);

            % Loop start
            for j=1:length(TOUT)
                % Rotation matrix base (T t1 t2 t3) to (o i j k)
                RTI=[cos(PSI(j)) -sin(PSI(j));sin(PSI(j)) cos(PSI(j))];
                % Position vectors 1, 2, 3 e 4 relative to origin of the inertial reference base (T t1 t2 t3)
                rt1i(j,1:2) = (RTI*rt1t)';
                rt2i(j,1:2) = (RTI*rt2t)';
                rt3i(j,1:2) = (RTI*rt3t)';
                rt4i(j,1:2) = (RTI*rt4t)';
                % Position of front and rear axle
                eff(j,1:2) = (RTI*eif);     % Front
                err(j,1:2) = (RTI*eir);     % Rear
            end

            % Absolute position of corners and axles
            % Absolute position over time

            % Position vectors 1, 2, 3 e 4 relative to o base (o i j k)
            rc1t=[XT YT]+rt1i;
            rc2t=[XT YT]+rt2i;
            rc3t=[XT YT]+rt3i;
            rc4t=[XT YT]+rt4i;

            % Absolute position of the front and rear axle
            ef = [XT YT]+eff;
            er = [XT YT]+err;

            % Time adjustment
            % Exhibition has to be adjusted the number of frames is different from the resolution of the integrator (TSPAN)

            TEMPO = 0:0.05:TOUT(end);

            % Preallocating matrix
            rc1 = zeros(length(TEMPO),2);
            rc2 = zeros(length(TEMPO),2);
            rc3 = zeros(length(TEMPO),2);
            rc4 = zeros(length(TEMPO),2);

            efrente = zeros(length(TEMPO),2);
            etras = zeros(length(TEMPO),2);

            xxx = zeros(length(TEMPO),2);
            yyy = zeros(length(TEMPO),2);
            alphat = zeros(length(TEMPO),2);
            psii = zeros(length(TEMPO),2);

            alphaf = zeros(length(TEMPO),2);
            alphar = zeros(length(TEMPO),2);

            velf = zeros(length(TEMPO),2);
            velr = zeros(length(TEMPO),2);
            velt = zeros(length(TEMPO),2);

            rn1 = zeros(length(TEMPO),2);
            rn2 = zeros(length(TEMPO),2);
            rn3 = zeros(length(TEMPO),2);
            rn4 = zeros(length(TEMPO),2);

            for i=1:length(TEMPO)
                % Position of corners and axles
                rc1(i,1:2) = interp1(TOUT,rc1t,TEMPO(i));
                rc2(i,1:2) = interp1(TOUT,rc2t,TEMPO(i));
                rc3(i,1:2) = interp1(TOUT,rc3t,TEMPO(i));
                rc4(i,1:2) = interp1(TOUT,rc4t,TEMPO(i));

                efrente(i,1:2) = interp1(TOUT,ef,TEMPO(i));
                etras(i,1:2) = interp1(TOUT,er,TEMPO(i));

                % Position of CG
                xxx(i,1:2) = interp1(TOUT,XT,TEMPO(i));
                yyy(i,1:2) = interp1(TOUT,YT,TEMPO(i));

                % States
                alphat(i,1:2) = interp1(TOUT,ALPHAT,TEMPO(i));
                psii(i,1:2) = interp1(TOUT,PSI,TEMPO(i));

                % Slip angles
                alphaf(i,1:2) = interp1(TOUT,ALPHAF,TEMPO(i));
                alphar(i,1:2) = interp1(TOUT,ALPHAR,TEMPO(i));

                % Velocity
                velf(i,1:2) = interp1(TOUT,VF,TEMPO(i));
                velr(i,1:2) = interp1(TOUT,VR,TEMPO(i));
                velt(i,1:2) = interp1(TOUT,VT,TEMPO(i));
            end

            XSize = 25 ;                            % Horizontal size of the figure [cm]
            % Defining figure
            f666=figure(666);
            set(f666,'Units','centimeters')         % Changing units of the figure to centimeters
            set(f666,'PaperUnits','centimeters')    % Changing units of the paper to centimeters
            % Position and size of the figure window
            set(f666,'Position',[0 0 XSize ((max(YT)+10) - (min(YT)-10))/((max(XT)+10) - (min(XT)-20))*XSize])
            % Position and size of the figure on the printed page
            set(f666,'PaperPosition',[0 0 XSize ((max(YT)+10) - (min(YT)-10))/((max(XT)+10) - (min(XT)-20))*XSize])
            % % Size of the paper
            set(f666,'PaperSize',[XSize ((max(YT)+10) - (min(YT)-10))/((max(XT)+10) - (min(XT)-20))*XSize])
            ax666=gca;
            set(ax666,'Units','centimeters')        % Changing units of the axes to centimeters
            set(ax666,'NextPlot','add','Box','on','XGrid','on','YGrid','on','ZGrid','on')
            axis equal
            set(ax666,'XLim',[min(XT)-20 max(XT)+10])
            set(ax666,'YLim',[min(YT)-10 max(YT)+10])

            xlabel('Distance [m]')
            ylabel('Distance [m]')

            % First frame

            % Velocity vectors - Script "vector.m"
            self.Vector(efrente(1,1:2),(alphaf(1)+psii(1)),velf(1),'r');
            self.Vector(etras(1,1:2),(alphar(1)+psii(1)),velr(1),'g');

            % Corner coordinates for the first frame
            xc = [rc1(1,1) rc2(1,1) rc3(1,1) rc4(1,1)];
            yc = [rc1(1,2) rc2(1,2) rc3(1,2) rc4(1,2)];

            % The vehicle
            fill(xc,yc,'r')

            % Adding semitrailer
            if col == 8
                PHI = XOUT(:,7);            % Relative yaw angle of the semitrailer [rad]
                dPHI = XOUT(:,8);           % Relative yaw rate between the two units [rad/s]

                c = self.vehicle.distRA;    % Distance from  [m]
                d = self.vehicle.distAS;    % Distance from  [m]
                e = self.vehicle.distSM;    % Distance from  [m]
                lS = self.vehicle.widthSemi / 2; % Half width of the vehicle [m]

                % Slip angle semitrailer axle [rad]
                ALPHAM = atan2(((d + e)*(dPHI - dPSI) + VT.*sin(ALPHAT + PHI) - b*dPSI.*cos(PHI) - c*dPSI.*cos(PHI)),(VT.*cos(ALPHAT + PHI) + b*dPSI.*sin(PHI) + c*dPSI.*sin(PHI)));
                % Velocity semitrailer axle [m/s]
                VM = sqrt((VT.*cos(ALPHAT + PHI) + b*dPSI.*sin(PHI) + c*dPSI.*sin(PHI)).^2 + ((d + e)*(dPHI - dPSI) + VT.*sin(ALPHAT + PHI) - b*dPSI.*cos(PHI) - c*dPSI.*cos(PHI)).^2);
                RS = [XT-(b+c)*cos(PSI)-d*cos(PSI-PHI) YT-(b+c)*sin(PSI)-d*sin(PSI-PHI)];
                % Position vectors 1, 2, 3 e 4 relative to S base (S s1 s2 s3)
                rs1s = [d;lS];              % Front left
                rs2s = [d;-lS];             % Front right
                rs3s = [-e;-lS];            % Rear right
                rs4s = [-e;lS];             % Rear left

                eim = [-e;0];               % Position of semitrailer axle

                rn1i = zeros(length(TOUT),2);
                rn2i = zeros(length(TOUT),2);
                rn3i = zeros(length(TOUT),2);
                rn4i = zeros(length(TOUT),2);

                emm = zeros(length(TOUT),2);

                for j=1:length(TOUT)
                    % Rotation matrix base (S s1 s2 s3) to (o i j k)
                    RSI=[cos(PSI(j)-PHI(j)) -sin(PSI(j)-PHI(j));sin(PSI(j)-PHI(j)) cos(PSI(j)-PHI(j))];
                    % Position vectors 1, 2, 3 e 4 relative to O base (c c1 c2 c3)
                    rn1i(j,1:2) = (RSI*rs1s)';
                    rn2i(j,1:2) = (RSI*rs2s)';
                    rn3i(j,1:2) = (RSI*rs3s)';
                    rn4i(j,1:2) = (RSI*rs4s)';

                    % Position of semitrailer axle
                    emm(j,1:2) = (RSI*eim);
                end

                % Position vectors 1, 2, 3 e 4 relative to o base (o i j k)
                rn1t=RS+rn1i;
                rn2t=RS+rn2i;
                rn3t=RS+rn3i;
                rn4t=RS+rn4i;

                em = RS+emm;

                phii = zeros(length(TEMPO),2);
                alpham = zeros(length(TEMPO),2);
                velm = zeros(length(TEMPO),2);
                emsemi = zeros(length(TEMPO),2);

                for i=1:length(TEMPO)
                    phii(i,1:2) = interp1(TOUT,PHI,TEMPO(i));
                    alpham(i,1:2) = interp1(TOUT,ALPHAM,TEMPO(i));
                    velm(i,1:2) = interp1(TOUT,VM,TEMPO(i));
                    % Semitrailer
                    rn1(i,1:2) = interp1(TOUT,rn1t,TEMPO(i));
                    rn2(i,1:2) = interp1(TOUT,rn2t,TEMPO(i));
                    rn3(i,1:2) = interp1(TOUT,rn3t,TEMPO(i));
                    rn4(i,1:2) = interp1(TOUT,rn4t,TEMPO(i));

                    emsemi(i,1:2) = interp1(TOUT,em,TEMPO(i));
                end

                self.Vector(emsemi(1,1:2),(alpham(1)+psii(1)-phii(1)),velm(1),'b');
                xn = [rn1(1,1) rn2(1,1) rn3(1,1) rn4(1,1)];
                yn = [rn1(1,2) rn2(1,2) rn3(1,2) rn4(1,2)];
                fill(xn,yn,'g')
            end

            if saveit == 1
                % Initializing gif
                frame = getframe(666);
                im = frame2im(frame);
                [A,map] = rgb2ind(im,256,'nodither');
                imwrite(A,map,'Animation.gif','LoopCount',Inf,'DelayTime',0.05);
            end

            % Remaining frames
            %
            for j = 1:length(TEMPO)
                % Axles
                plot(efrente(:,1),efrente(:,2),'r')
                plot(etras(:,1),etras(:,2),'g')

                % Coordinates of the corners
                xc = [rc1(j,1) rc2(j,1) rc3(j,1) rc4(j,1)];
                yc = [rc1(j,2) rc2(j,2) rc3(j,2) rc4(j,2)];

                % Vehicle
                fill(xc,yc,'r')

                % Velocity vectors
                % Different colors
                self.Vector(efrente(j,1:2),(alphaf(j)+psii(j)),velf(j),'r');
                self.Vector(etras(j,1:2),(alphar(j)+psii(j)),velr(j),'g');

                if col == 8
                    plot(emsemi(:,1),emsemi(:,2),'b')
                    xn = [rn1(j,1) rn2(j,1) rn3(j,1) rn4(j,1)];
                    yn = [rn1(j,2) rn2(j,2) rn3(j,2) rn4(j,2)];
                    fill(xn,yn,'g')
                    self.Vector(emsemi(j,1:2),(alpham(j)+psii(j)-phii(j)),velm(j),'b');
                end

                if saveit == 1
                    % Adding the current frame to the initialized gif
                    frame = getframe(666);
                    im = frame2im(frame);
                    [A,map] = rgb2ind(im,256,'nodither');
                    imwrite(A,map,'Animation.gif','WriteMode','append','DelayTime',0.05);
                end

                pause(0.05)                 % OBS: It has to be the same value of the time adjustment

                cla(ax666);                    % Clearing axes
            end

            % Last frame
            % Last image seen when the animation is over

            % Axles
            plot(efrente(:,1),efrente(:,2),'r')
            plot(etras(:,1),etras(:,2),'g')

            % Coordinates of the corners of the last frame
            xc = [rc1(end,1) rc2(end,1) rc3(end,1) rc4(end,1)];
            yc = [rc1(end,2) rc2(end,2) rc3(end,2) rc4(end,2)];

            % Vehicle
            fill(xc,yc,'r')

            self.Vector(efrente(end,1:2),(alphaf(end)+psii(end)),velf(end),'r');
            self.Vector(etras(end,1:2),(alphar(end)+psii(end)),velr(end),'g');

            % Adding the semitrailer
            if col == 8
                plot(emsemi(:,1),emsemi(:,2),'b')
                xn = [rn1(end,1) rn2(end,1) rn3(end,1) rn4(end,1)];
                yn = [rn1(end,2) rn2(end,2) rn3(end,2) rn4(end,2)];
                fill(xn,yn,'g')
                self.Vector(emsemi(end,1:2),(alpham(end)+psii(end)-phii(end)),velm(end),'b');
            end
        end

        %% Frame
        % Plots the sequence of frames of the vehicle manoever.
        %
        % *Sintax*
        %
        % |_GraphicsClass_.Frame(XOUT,TOUT,saveit)|
        %
        % *Arguments*
        %
        % The following table describes the input arguments:
        %
        % <html> <table border=1 width="97%">
        % <tr> <td width="30%"><tt>XOUT</tt></td> <td width="70%">Solution array. Each column corresponds to the solution of each state variable of the vehicle. The columns must respect the following variable order: [XT YT PSI dPSI VT ALPHAT (PHI dPHI)] </td> </tr>
        % <tr> <td width="30%"><tt>TOUT</tt></td> <td width="70%">Column vector of time points.</td> </tr>
        % <tr> <td width="30%"><tt>saveit</tt></td> <td width="70%">Flag for saving the trajectory image in a pdf file. If savit = 0 the image will not be saved. If savit = 1 a file Trajectory.pdf is generated.</td> </tr>
        % </table> </html>
        %
        % *Description*
        %


        function Frame(self,XOUT,TOUT,saveit)
            % Verifying number of columns of the state output matrix
            % col = 6 -> simples
            % col = 8 -> articulado
            [col] = size(XOUT,2);

            % States
            XT = XOUT(:,1);                 % Horizontal position [m]
            YT = XOUT(:,2);                 % Vertical position [m]
            PSI = XOUT(:,3);                % Vehicle yaw angle [rad]
            dPSI = XOUT(:,4);               % Yaw rate [rad/s]
            VT = XOUT(:,5);                 % Vehicle CG velocity [m/s]
            ALPHAT = XOUT(:,6);             % Vehicle side slip angle [rad]

            % Distances
            a = self.vehicle.distFT;        % Distance FT [m]
            b = self.vehicle.distTR;        % Distance TR [m]
            lT = self.vehicle.width / 2;    % Half width of the vehicle [m]

            % Slip angle @ front axle [rad]
            ALPHAF = atan2((a*dPSI + VT.*sin(ALPHAT)),(VT.*cos(ALPHAT)));
            % OBS: No steering angle because it measures the angle between velocity vector and longitudinal axle of the vehicle
            % Slip angle @ rear axle [rad]
            ALPHAR = atan2((-b*dPSI + VT.*sin(ALPHAT)),(VT.*cos(ALPHAT)));
            % OBS: When using atan2 and the value reaches 180 degrees the vector becomes strange

            % Velocity
            VF = sqrt((VT.*cos(ALPHAT)).^2 + (a*dPSI + VT.*sin(ALPHAT)).^2);
            VR = sqrt((VT.*cos(ALPHAT)).^2 + (-b*dPSI + VT.*sin(ALPHAT)).^2);

            % Position of the corners and axles relative to the CG

            % Position vectors 1, 2, 3 e 4 relative to T base (T t1 t2 t3)
            rt1t = [a;lT];                  % Front left
            rt2t = [a;-lT];                 % Front right
            rt3t = [-b;-lT];                % Rear right
            rt4t = [-b;lT];                 % Rear left

            eif = [a;0];                    % Front axle
            eir = [-b;0];                   % Rear axle

            % Preallocating matrix
            rt1i = zeros(length(TOUT),2);
            rt2i = zeros(length(TOUT),2);
            rt3i = zeros(length(TOUT),2);
            rt4i = zeros(length(TOUT),2);

            eff = zeros(length(TOUT),2);
            err = zeros(length(TOUT),2);

            for j=1:length(TOUT)
                % Rotation matrix base (T t1 t2 t3) to (o i j k)
                RTI=[cos(PSI(j)) -sin(PSI(j));sin(PSI(j)) cos(PSI(j))];
                % Position vectors 1, 2, 3 e 4 relative to origin of the inertial reference base (T t1 t2 t3)
                rt1i(j,1:2) = (RTI*rt1t)';
                rt2i(j,1:2) = (RTI*rt2t)';
                rt3i(j,1:2) = (RTI*rt3t)';
                rt4i(j,1:2) = (RTI*rt4t)';
                % Position of front and rear axle
                eff(j,1:2) = (RTI*eif);     % Front
                err(j,1:2) = (RTI*eir);     % Rear
            end

            % Absolute position of corners and axles
            % Absolute position over time

            % Position vectors 1, 2, 3 e 4 relative to o base (o i j k)
            rc1t=[XT YT]+rt1i;
            rc2t=[XT YT]+rt2i;
            rc3t=[XT YT]+rt3i;
            rc4t=[XT YT]+rt4i;

            % Absolute position of the front and rear axle
            ef = [XT YT]+eff;
            er = [XT YT]+err;

            % Time adjustment
            % Exhibition has to be adjusted the number of frames is different from the resolution of the integrator (TSPAN)

            % The variable defines the instants the vehicle will be ploted
            TEMPO = 0:1:TOUT(end);

            % Preallocating matrix
            rc1 = zeros(length(TEMPO),2);
            rc2 = zeros(length(TEMPO),2);
            rc3 = zeros(length(TEMPO),2);
            rc4 = zeros(length(TEMPO),2);

            efrente = zeros(length(TEMPO),2);
            etras = zeros(length(TEMPO),2);

            xxx = zeros(length(TEMPO),2);
            yyy = zeros(length(TEMPO),2);
            alphat = zeros(length(TEMPO),2);
            psii = zeros(length(TEMPO),2);

            alphaf = zeros(length(TEMPO),2);
            alphar = zeros(length(TEMPO),2);

            velf = zeros(length(TEMPO),2);
            velr = zeros(length(TEMPO),2);
            velt = zeros(length(TEMPO),2);

            for i=1:length(TEMPO)
                % Position of corners and axles
                rc1(i,1:2) = interp1(TOUT,rc1t,TEMPO(i));
                rc2(i,1:2) = interp1(TOUT,rc2t,TEMPO(i));
                rc3(i,1:2) = interp1(TOUT,rc3t,TEMPO(i));
                rc4(i,1:2) = interp1(TOUT,rc4t,TEMPO(i));

                xxx(i,1:2) = interp1(TOUT,XT,TEMPO(i));
                yyy(i,1:2) = interp1(TOUT,YT,TEMPO(i));

                % States
                alphat(i,1:2) = interp1(TOUT,ALPHAT,TEMPO(i));
                psii(i,1:2) = interp1(TOUT,PSI,TEMPO(i));

                % Slip angles
                alphaf(i,1:2) = interp1(TOUT,ALPHAF,TEMPO(i));
                alphar(i,1:2) = interp1(TOUT,ALPHAR,TEMPO(i));

                % Velocity
                velf(i,1:2) = interp1(TOUT,VF,TEMPO(i));
                velr(i,1:2) = interp1(TOUT,VR,TEMPO(i));
                velt(i,1:2) = interp1(TOUT,VT,TEMPO(i));
            end

            XSize = 16 ;                            % Horizontal size of the figure [cm]

            % Defining figure
            f999 = figure(999);
            set(f999,'Units','centimeters')         % Changing units of the figure to centimeters
            set(f999,'PaperUnits','centimeters')    % Changing units of the paper to centimeters
            % Position and size of the figure window
            set(f999,'Position',[0 0 XSize ((max(YT)+10) - (min(YT)-10))/((max(XT)+10) - (min(XT)-20))*XSize])
            % Position and size of the figure on the printed page
            set(f999,'PaperPosition',[0 0 XSize ((max(YT)+10) - (min(YT)-10))/((max(XT)+10) - (min(XT)-20))*XSize])
            % % Size of the paper
            set(f999,'PaperSize',[XSize ((max(YT)+10) - (min(YT)-10))/((max(XT)+10) - (min(XT)-20))*XSize])
            ax999=gca;
            set(ax999,'Units','centimeters')        % Changing units of the axes to centimeters
            set(ax999,'NextPlot','add','Box','on','XGrid','on','YGrid','on','ZGrid','on')
            axis equal
            set(ax999,'XLim',[min(XT)-20 max(XT)+10])
            set(ax999,'YLim',[min(YT)-10 max(YT)+10])

            xlabel('Distance [m]')
            ylabel('Distance [m]')

            TEMPOplot = 0:0.05:TOUT(end); % Time for the plots
            for i=1:length(TEMPOplot)
                efrente(i,1:2) = interp1(TOUT,ef,TEMPOplot(i));
                etras(i,1:2) = interp1(TOUT,er,TEMPOplot(i));
            end

            plot(ef(:,1),ef(:,2),'r')
            plot(er(:,1),er(:,2),'g')

            for j = 1:length(TEMPO)
                % Coordinates of the corners
                xc = [rc1(j,1) rc2(j,1) rc3(j,1) rc4(j,1)];
                yc = [rc1(j,2) rc2(j,2) rc3(j,2) rc4(j,2)];
                % Vehicle
                fill(xc,yc,'r');
            end

            % Adding semitrailer
            if col == 8
                PHI = XOUT(:,7);            % Relative yaw angle of the semitrailer [rad]
                dPHI = XOUT(:,8);           % Relative yaw rate between the two units [rad/s]

                c = self.vehicle.distRA;    % Distance from  [m]
                d = self.vehicle.distAS;    % Distance from  [m]
                e = self.vehicle.distSM;    % Distance from  [m]
                lS = self.vehicle.widthSemi / 2; % Half width of the vehicle [m]
                % Slip angle semitrailer axle [rad]
                ALPHAM = atan2(((d + e)*(dPHI - dPSI) + VT.*sin(ALPHAT + PHI) - b*dPSI.*cos(PHI) - c*dPSI.*cos(PHI)),(VT.*cos(ALPHAT + PHI) + b*dPSI.*sin(PHI) + c*dPSI.*sin(PHI)));
                % Velocity semitrailer axle [m/s]
                VM = sqrt((VT.*cos(ALPHAT + PHI) + b*dPSI.*sin(PHI) + c*dPSI.*sin(PHI)).^2 + ((d + e)*(dPHI - dPSI) + VT.*sin(ALPHAT + PHI) - b*dPSI.*cos(PHI) - c*dPSI.*cos(PHI)).^2);
                % CG position
                RS = [XT-(b+c)*cos(PSI)-d*cos(PSI-PHI) YT-(b+c)*sin(PSI)-d*sin(PSI-PHI)];
                % Position vectors 1, 2, 3 e 4 relative to S base (S s1 s2 s3)
                rs1s = [d;lS];              % Front left
                rs2s = [d;-lS];             % Front right
                rs3s = [-e;-lS];            % Rear right
                rs4s = [-e;lS];             % Rear left
                eim = [-e;0];               % Position of semitrailer axle

                rn1i = zeros(length(TOUT),2);
                rn2i = zeros(length(TOUT),2);
                rn3i = zeros(length(TOUT),2);
                rn4i = zeros(length(TOUT),2);
                emm = zeros(length(TOUT),2);

                for j=1:length(TOUT)
                    % Rotation matrix base (S s1 s2 s3) to (o i j k)
                    RSI=[cos(PSI(j)-PHI(j)) -sin(PSI(j)-PHI(j));sin(PSI(j)-PHI(j)) cos(PSI(j)-PHI(j))];
                    % Position vectors 1, 2, 3 e 4 relative to O base (c c1 c2 c3)
                    rn1i(j,1:2) = (RSI*rs1s)';
                    rn2i(j,1:2) = (RSI*rs2s)';
                    rn3i(j,1:2) = (RSI*rs3s)';
                    rn4i(j,1:2) = (RSI*rs4s)';

                    % Position of semitrailer axle
                    emm(j,1:2) = (RSI*eim);
                end

                % Position vectors 1, 2, 3 e 4 relative to o base (o i j k)
                rn1t=RS+rn1i;
                rn2t=RS+rn2i;
                rn3t=RS+rn3i;
                rn4t=RS+rn4i;

                em = RS+emm;

                phii = zeros(length(TEMPO),2);
                alpham = zeros(length(TEMPO),2);
                velm = zeros(length(TEMPO),2);
                rn1 = zeros(length(TEMPO),2);
                rn2 = zeros(length(TEMPO),2);
                rn3 = zeros(length(TEMPO),2);
                rn4 = zeros(length(TEMPO),2);
                emsemi = zeros(length(TEMPO),2);

                for i=1:length(TEMPO)
                    phii(i,1:2) = interp1(TOUT,PHI,TEMPO(i));
                    alpham(i,1:2) = interp1(TOUT,ALPHAM,TEMPO(i));
                    velm(i,1:2) = interp1(TOUT,VM,TEMPO(i));

                    rn1(i,1:2) = interp1(TOUT,rn1t,TEMPO(i));
                    rn2(i,1:2) = interp1(TOUT,rn2t,TEMPO(i));
                    rn3(i,1:2) = interp1(TOUT,rn3t,TEMPO(i));
                    rn4(i,1:2) = interp1(TOUT,rn4t,TEMPO(i));
                end
                for i=1:length(TEMPOplot)
                    emsemi(i,1:2) = interp1(TOUT,em,TEMPOplot(i));
                end
                plot(em(:,1),em(:,2),'b')

                for j = 1:length(TEMPO)
                    xn = [rn1(j,1) rn2(j,1) rn3(j,1) rn4(j,1)];
                    yn = [rn1(j,2) rn2(j,2) rn3(j,2) rn4(j,2)];
                    fill(xn,yn,'g');
                end
            end

            if saveit == 1
                print(f999,'-dpdf','Trajectory.pdf')
            end
        end
    end

    methods(Static)

        %% Vector
        % Plots a vector arrow.
        %
        % *Sintax*
        %
        % |_GraphicsClass_.Vector(inicio,angulo,modulo,cor)|
        %
        % *Arguments*
        %
        % The following table describes the input arguments:
        %
        % <html> <table border=1 width="97%">
        % <tr> <td width="30%"><tt>startCoord</tt></td> <td width="70%"> Vector start coordinate.</td> </tr>
        % <tr> <td width="30%"><tt>angle</tt></td> <td width="70%"> Orientation angle of the arrow.</td> </tr>
        % <tr> <td width="30%"><tt>modulo</tt></td> <td width="70%">Size of the arrow.</td> </tr>
        % <tr> <td width="30%"><tt>color</tt></td> <td width="70%">Color of the arrow.</td> </tr>
        % </table> </html>
        %
        % *Description*
        %
        % TEXTO

        function Vector(startCoord,angle,modulo,color)
            coord1 = startCoord;                                % Vector start coordinate
            theta = angle;
            modulo = 0.7*modulo;                                % Size of the vector
            coord2 = modulo*[cos(theta) sin(theta)] + coord1;   % Vector end coordinate

            %theta = atan2((coord1(1)-coord2(1)),(coord1(2)-coord2(2))); % Orientatin angle of the triangle
            esc = 1; % Scale
            l = 0.5; % width relative to the triangle length (0-1)

            % Shape and orientation of the triangle
            c1 = esc*l*[-sin(theta) +cos(theta)];   % corner 1 - bottom left
            c2 = esc*l*[+sin(theta) -cos(theta)];   % corner 2 - bottom right
            c3 = esc*[+cos(theta) +sin(theta)];     % corner 3 - top central

            % Scale and positioning
            x = [c1(1)+coord2(1) c2(1)+coord2(1) c3(1)+coord2(1)];
            y = [c1(2)+coord2(2) c2(2)+coord2(2) c3(2)+coord2(2)];

            hold on
            fill(x,y,color)
            p = plot([coord1(1) coord2(1)],[coord1(2) coord2(2)],color);
            set(p,'LineWidth',2)
            % Idea of using a marker at the begining of the vector
            % m = plot(coord1(1),coord1(2),strcat('*',cor));
            % set(m,'MarkerSize',10)
        end

        %% changeMarker
        % The function changeMarker changes the number of marker in a plot.
        %
        % *Sintax*
        %
        % |_GraphicsClass_.changeMarker(p,n)|
        %
        % *Arguments*
        %
        % The following table describes the input arguments:
        %
        % <html> <table border=1 width="97%">
        % <tr> <td width="30%"><tt>p</tt></td> <td width="70%">Handle do plot.</td> </tr>
        % <tr> <td width="30%"><tt>n</tt></td> <td width="70%">Number of markers to be included.</td> </tr>
        % </table> </html>
        %
        % *Description*
        %
        % TEXTO

        function changeMarker(p,n)
            % p - handle of plot
            % n - number of markers

            % Line info
            line_color = get(p,'Color');
            line_Style = get(p,'LineStyle');
            line_LineWidth = get(p,'LineWidth');
            % Marker info
            marker_type = get(p,'Marker');
            marker_size = get(p,'MarkerSize');
            marker_EdgeColor = get(p,'MarkerEdgeColor');
            marker_FaceColor = get(p,'MarkerFaceColor');
            % Axis info
            vec_XData = get(p,'XData');
            vec_YData = get(p,'YData');

            size_XData = length(vec_XData);

            step = floor((size_XData)/(n-1));

            % Ploting the markers
            p_marker = plot(vec_XData(1:step:end),vec_YData(1:step:end));
            set(p_marker,'LineStyle','none','Marker',marker_type,'MarkerSize',marker_size,...
            	'MarkerEdgeColor',marker_EdgeColor,'MarkerFaceColor',marker_FaceColor)

            % Removing the markers from the original plot
            set(p,'Marker','none')
            % Hiding the original plot
            set(p,'HandleVisibility','off')
            set(p_marker,'HandleVisibility','off')

            % Dummy for legend
            p_dummy = plot(vec_XData(1),vec_YData(1));
            set(p_dummy,'Color',line_color,'LineStyle',line_Style,'LineWidth',line_LineWidth,...
            	'Marker',marker_type,'MarkerSize',marker_size,...
            	'MarkerEdgeColor',marker_EdgeColor,'MarkerFaceColor',marker_FaceColor)
        end

    end

    %% Properties
    %

    properties
        vehicle
    end
end

%% See Also
%
% <index.html Index>
%
