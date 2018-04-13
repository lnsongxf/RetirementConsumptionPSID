clear; clc; close all;
%cd 'C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID\Results\Aux_Model_Estimates'
cd '/Users/agneskaa/Documents/RetirementConsumptionPSID/Results/Aux_Model_Estimates'

A = importdata('coefs.txt');
B = importdata('sigma.txt');
data = importdata('InitData.csv');

%% Extract coefs and VCV

betaa = A.data';
coef_varnames  = cat(1, A.textdata(1, 2:end) );

simga = B.data;
sigma_varnames = cat(1, B.textdata(2:end, 1) );

%% Extract data
colnames = data.textdata;
ids = data.data(:, 1);
X0 = data.data(:, 2:end);

%% Select Data

% Lets just use 5 obs for now
X0 = X0(1:5, :)
ids = ids(1:5, :);

%%  Notes
% output = n x 8 matrix
% input = n x 8 matrix
% eps = 5x1
% coefs = 40x1

% Xi = n x k
% k = regressors
% n = obs
% 
% Y = nm x 1
% m = # eqns (5)
% 
% Y1 = consumption for each person 
% n x 1
% 
% Y = [Y1; Y2; Y3; Y4; Y5]
% 
% Xi = [Y1, Y2, Y3, Y4, Y5; age; age2; cons]
% 
% X = diag(Xi) repeated m times

%% Prepare simulation
[n, k] = size(X_input);  % n: obs k: regressors
m      = k-3;            % eqns
index_housing = 1; % index of housing (linear probability model)

% Xi = n x k
% X_input = ones(n, k) % TODO: from stata
% X_input = [ [eye(5); eye(5)], zeros(10,2), ones(10,1)];
X_input = X0;

%% Run once

X_t = X_input;
age_t = X_input(:, m+1);
cons = X_input(:, end);
n = size(X0, 1);

if m == 5
    BigX = blkdiag(X_t, X_t, X_t, X_t, X_t); % assuming there are 5 eqns
end


Var_Cov   = B.data;       
epsilon_t = getCorrelatedSchocks(n, m, Var_Cov);
epsilon_t = reshape(epsilon_t, n*m,1);

Y = BigX * betaa + epsilon_t;

% BigX = nm x km
% beta = km x 1
% Y = nm x 1

Y_transform = reshape(Y, [n, m] );

age_t1 = age_t + 1;
X_t1 = [Y_transform, age_t1, age_t1.^2, cons];

% convert housing to binary
X_t1(:,index_housing) = X_t1(:,index_housing) >= 0.5;

% row is a person
% columns: housing, consumption, etc, age, age2, constant

id = (1:size(X_input, 1))';

array2table( [ids, X_t; ids, X_t1], 'VariableNames', colnames )
