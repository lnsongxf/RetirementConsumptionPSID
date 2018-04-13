function [X] = getCorrelatedSchocks(obs, num_var, VarCov)
% We wanna generate Normally distrubuted random numbers with Var-Cov Matrix
% VarCov X ~ N(0, VarCov)
% lets get 1000 observations for 3 variables
% obs = 1000000;
% num_var= 3; 
% VarCov = [1 0.03 0.001
%           0.5   1  0.2
%           0.1   0.2  1];

% 1. Lets draw indepenedent variables from standard normal cov(Z) = I
Z = random('Normal',0,1, [obs, num_var]);

% 2. Apply a transformation on Z
% We can set X = Z*A 
% where Cov(Z) = I so cov(X) = A'*A
% and we need cov(X) to be VarCov, we use Cholsesky to get A from VarCov 

A = chol(VarCov);

X = Z*A;

end
