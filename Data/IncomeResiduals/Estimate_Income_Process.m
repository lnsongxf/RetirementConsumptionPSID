clear; clc; close all;
cd 'C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID\Data\IncomeResiduals\'

u = csvread('u.csv', 2, 1)';
d = csvread('d.csv', 2, 1)';

A = size(d, 1);
n = size(d, 2);

%% Construct variance covariance matrix
Y = zeros(A, A);
D = zeros(A, A);

for ixd = 1:n
    d_i = d(:, ixd);
    D = D + d_i * d_i';

    u_i = u(:, ixd);
    Y = Y + u_i * u_i';
end

C = Y ./ D;
C_vech_full = vech(C);
moments_to_use = ~isnan(C_vech_full);

C_vech = C_vech_full(moments_to_use);

% C_vech = vech_slow(C);
% C_vech2 = vech(C);
% sum(C_vech(~isnan(C_vech))) 
% sum(C_vech2(~isnan(C_vech2)))

%% Construct weight matrix
M = zeros(A, A);
m_all = vech(C);
s_all = vech(D);

m = m_all(moments_to_use);
s = s_all(moments_to_use);

V_top = zeros(size(m));
V_bottom = s*s';

tic
for ixd = 1:n
    u_i = u(:, ixd);   
    m_i_all = vech( u_i * u_i' );
    m_i = m_i_all(moments_to_use);
    V_inner = m - m_i;
    V_top = V_top + (V_inner)*(V_inner)';
end
toc

%%
V = V_top ./ V_bottom;


V_inv = inv(V);
W = diag(diag(V_inv));

%% TODO: setup f(params) given cormac appendix

%% TODO: setup fmincon


