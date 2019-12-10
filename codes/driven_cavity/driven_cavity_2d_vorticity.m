% ----------------------------------------------------------------------- %
%                                     __  __  __       _  __   __         %
%        |\/|  _  |_ |  _  |_   |__| /   |_  |  \  _  (_ |__) |_          %
%        |  | (_| |_ | (_| |_)     | \__ |   |__/ (_) |  | \  |           %
%                                                                         %
% ----------------------------------------------------------------------- %
%                                                                         %
%   Author: Alberto Cuoci <alberto.cuoci@polimi.it>                       %
%   CRECK Modeling Group <http://creckmodeling.chem.polimi.it>            %
%   Department of Chemistry, Materials and Chemical Engineering           %
%   Politecnico di Milano                                                 %
%   P.zza Leonardo da Vinci 32, 20133 Milano                              %
%                                                                         %
% ----------------------------------------------------------------------- %
%                                                                         %
%   This file is part of Matlab4CFDofRF framework.                        %
%                                                                         %
%   License                                                               %
%                                                                         %
%   Copyright(C) 2019 Alberto Cuoci                                       %
%   Matlab4CFDofRF is free software: you can redistribute it and/or       %
%   modify it under the terms of the GNU General Public License as        %
%   published by the Free Software Foundation, either version 3 of the    %
%   License, or (at your option) any later version.                       %
%                                                                         %
%   Matlab4CFDofRF is distributed in the hope that it will be useful,     %
%   but WITHOUT ANY WARRANTY; without even the implied warranty of        %
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         %
%   GNU General Public License for more details.                          %
%                                                                         %
%   You should have received a copy of the GNU General Public License     %
%   along with Matlab4CRE. If not, see <http://www.gnu.org/licenses/>.    %
%                                                                         %
%-------------------------------------------------------------------------%
%                                                                         %
%  Code: 2D driven-cavity problem in vorticity/streamline formulation     %
%        The code is adapted and extended from Tryggvason, Computational  %
%        Fluid Dynamics http://www.nd.edu/~gtryggva/CFD-Course/           %
%                                                                         %
% ----------------------------------------------------------------------- %
close all;
clear variables;

% Basic setup
nx=25;                  % number of grid points along x
ny=nx;                  % number of grid points along y
Re=100;                 % Reynolds number [-]
tau=20;                 % total time of simulation [-]

% Parameters for SOR
max_iterations=10000;   % maximum number of iterations
beta=1.5;               % SOR coefficient
max_error=0.0001;      % error for convergence

% Data for reconstructing the velocity field
L=1;                    % length [m]
nu=1e-3;                % kinematic viscosity [m2/s] 
Uwall=nu*Re/L;          % wall velocity [m/s]

% Grid step
h=1/(nx-1);                         % grid step along x and y [-]

% Time step
sigma = 0.5;                        % safety factor for time step (stability)
dt_diff=h^2*Re/4;                   % time step (diffusion stability)
dt_conv=4/Re;                       % time step (convection stability)
dt=sigma*min(dt_diff, dt_conv);     % time step (stability)
nsteps=tau/dt;                      % number of steps

fprintf('Time step: %f\n', dt);
fprintf(' - Diffusion:  %f\n', dt_diff);
fprintf(' - Convection: %f\n', dt_conv);

% Memory allocation
psi=zeros(nx,ny);       % streamline function
omega=zeros(nx,ny);     % vorticity
omegao=zeros(nx,ny);    % vorticity at previous time
u=zeros(nx,ny);         % reconstructed dimensionless x-velocity
v=zeros(nx,ny);         % reconstructed dimensionless y-velocity
U=zeros(nx,ny);         % reconstructed x-velocity
V=zeros(nx,ny);         % reconstructed y-velocity

% Mesh construction (only needed in graphical post-processing)
x=0:h:1;                % grid coordinates (x axis)
y=0:h:1;                % grid coordinates (y axis)
[X,Y] = meshgrid(x,y);  % mesh

% Time loop
t = 0;
for istep=1:nsteps     
    
    % ------------------------------------------------------------------- %
    % Poisson equation (SOR)
    % ------------------------------------------------------------------- %
    [psi, iter] = Poisson2D( psi, nx, ny, h, omega, ...
                             beta, max_iterations, max_error);
    
    % ------------------------------------------------------------------- %
    % Find vorticity on boundaries
    % ------------------------------------------------------------------- %
    omega(2:nx-1,1)=-2.0*psi(2:nx-1,2)/(h*h);               % south
    omega(2:nx-1,ny)=-2.0*psi(2:nx-1,ny-1)/(h*h)-2.0/h*1;   % north
    omega(1,2:ny-1)=-2.0*psi(2,2:ny-1)/(h*h);               % east
    omega(nx,2:ny-1)=-2.0*psi(nx-1,2:ny-1)/(h*h);           % west
  
    % ------------------------------------------------------------------- %
    % Find new vorticity in interior points
    % ------------------------------------------------------------------- %
     omegao=omega;
     for i=2:nx-1 
         for j=2:ny-1
            omega(i,j)=omegao(i,j)+dt*(-0.25*((psi(i,j+1)-psi(i,j-1))*...
                    (omegao(i+1,j)-omegao(i-1,j))-(psi(i+1,j)-psi(i-1,j))*...
                    (omegao(i,j+1)-omegao(i,j-1)))/(h*h)+...
                    1/Re*(omegao(i+1,j)+omegao(i-1,j)+omegao(i,j+1)+...
                    omegao(i,j-1)-4.0*omegao(i,j))/(h^2) );
         end
     end
   
    if (mod(istep,25)==1)
        fprintf('Step: %d - Time: %f - Poisson iterations: %d\n', istep, t, iter);
    end
    
    t=t+dt;
    
    % ------------------------------------------------------------------- %
    % Reconstruction of dimensionless velocity field
    % ------------------------------------------------------------------- % 
    u(:,ny)=1;
    for i=2:nx-1 
         for j=2:ny-1
             u(i,j) =  (psi(i,j+1)-psi(i,j-1))/2/h;
             v(i,j) = -(psi(i+1,j)-psi(i-1,j))/2/h;
         end
    end
    
    % ------------------------------------------------------------------- %
    % Reconstruction of velocity field
    % ------------------------------------------------------------------- %
    U = u*Uwall;
    V = v*Uwall;
    
    % ------------------------------------------------------------------- %
    % Graphics only
    % ------------------------------------------------------------------- %
    plot_2x4 = false;   % plotting the 2x4 plot
    
    if (plot_2x4 == true)
        
        subplot(241);
        contour(x,y,omega');
        axis('square'); title('omega'); xlabel('x'); ylabel('y');

        subplot(245);
        contour(x,y,psi');
        axis('square'); title('psi'); xlabel('x'); ylabel('y');

        subplot(242);
        contour(x,y,u');
        axis('square'); title('u'); xlabel('x'); ylabel('y');

        subplot(246);
        contour(x,y,v');
        axis('square'); title('v'); xlabel('x'); ylabel('y');

        subplot(243);
        plot(x,u(:, round(ny/2)));
        hold on;
        plot(x,v(:, round(ny/2)));
        axis('square'); legend('u', 'v');
        title('velocities along HA'); xlabel('x'); ylabel('velocities');
        hold off;
        
        subplot(247);
        plot(y,u(round(nx/2),:));
        hold on;
        plot(y,v(round(nx/2),:));
        axis('square'); legend('u', 'v');
        title('velocities along VA'); xlabel('y'); ylabel('velocities');
        hold off;

        subplot(244);
        quiver(x,y,u',v');
        axis('square', [0 1 0 1]);
        title('velocity vectors'); xlabel('x'); ylabel('y');
    
        pause(0.001);
        
    end
    
end

% ------------------------------------------------------------------- %
% Write final maps
% ------------------------------------------------------------------- %

subplot(231);
surface(x,y,u');
axis('square'); title('u'); xlabel('x'); ylabel('y');

subplot(234);
surface(x,y,v');
axis('square'); title('v'); xlabel('x'); ylabel('y');

subplot(232);
surface(x,y,omega');
axis('square'); title('omega'); xlabel('x'); ylabel('y');

subplot(235);
surface(x,y,psi');
axis('square'); title('psi'); xlabel('x'); ylabel('y');

subplot(233);
contour(x,y,psi', 30, 'b');
axis('square');
title('stream lines'); xlabel('x'); ylabel('y');

subplot(236);
quiver(x,y,u',v');
axis([0 1 0 1], 'square');
title('stream lines'); xlabel('x'); ylabel('y');

% ------------------------------------------------------------------- %
% Write velocity profiles along the centerlines for exp comparison
% ------------------------------------------------------------------- %
u_profile = u(round(nx/2),:);
fileVertical = fopen('experimental_data/vertical.out','w');
for i=1:ny 
    fprintf(fileVertical,'%f %f\n',y(i), u_profile(i));
end
fclose(fileVertical);

v_profile = v(:,round(ny/2));
fileHorizontal = fopen('experimental_data/horizontal.out','w');
for i=1:nx
    fprintf(fileHorizontal,'%f %f\n',x(i), v_profile(i));
end
fclose(fileHorizontal);

% ------------------------------------------------------------------- %
% Compare with exp data (available only for Re=100, 400, and 1000)
% ------------------------------------------------------------------- %
% Read experimental data from file
exp_u_along_y = dlmread('experimental_data/u_along_y.exp', '', 1, 0);
exp_v_along_x = dlmread('experimental_data/v_along_x.exp', '', 1, 0);

% Comparison with exp data
% Be careful: cols 1,2 for Re=100, 3,4 for Re=400, 5,6 for Re=1000
figure;
plot(exp_u_along_y(:,1), exp_u_along_y(:,2), 'o', y, u_profile, '-');
axis('square'); title('u along y (centerline)'); xlabel('y'); ylabel('u');

figure;
plot(exp_v_along_x(:,1), exp_v_along_x(:,2), 'o', x, v_profile, '-');
axis('square'); title('v along x (centerline)'); xlabel('x'); ylabel('v');


% --------------------------------------------------------------------------------------
% Poisson equation solver
% --------------------------------------------------------------------------------------
function [psi, iter] = Poisson2D(psi, nx, ny, h, omega, beta, max_iterations, max_error)

    for iter=1:max_iterations

            for i=2:nx-1
                for j=2:ny-1 % solve for the stream function by SOR iteration
                    psi(i,j)=0.25*beta*(psi(i+1,j)+psi(i-1,j)+psi(i,j+1)+...
                                psi(i,j-1)+h*h*omega(i,j))+(1.0-beta)*psi(i,j);
                end
            end

            % Estimate the error
            epsilon=0.0; 
            for i=2:nx-1
                for j=2:ny-1
                    epsilon=epsilon+abs( ( psi(i+1,j) - 2*psi(i,j) + psi(i-1,j) )/h^2 + ...
                                         ( psi(i,j+1) - 2*psi(i,j) + psi(i,j-1) )/h^2 + ...
                                         omega(i,j)  ); 
                end
            end
            epsilon = epsilon/(nx-2)/(ny-2);

            % Check the error
            if (epsilon <= max_error) % stop if converged
                break;
            end 
    end
    
end
