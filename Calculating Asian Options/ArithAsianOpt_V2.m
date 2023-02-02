function V=ArithAsianOpt_V2(M,N,T,K,Scheme)
% Aritmetic Asian call option pricing with Monte-Carlo simulation
% Different Scheme calculations (Euler and Milstein approaches)
% it will still use constant sigma, kappa, theta and etc. which can also be
% parametarized in the future revisions
% M= number of paths
% N= sample size
% T= time to maturity
% K= strike
% Scheme = 'E' for Euler, 'M' for Milstein
% Returns the Price array as V(1)=Average Price,V(2)=left boundry and
% V(3)=right boundry and V(4)=approximate runtime
tstart=tic;
h = T/N;%delta t
S0 = 100;
sigma0 = 0.09; %variance at t=0
kappa = 1.15;
theta = 0.348;
rho = -0.64;
r=0.05;
sigma = 0.39; %the volatility of volatility
nu = 0.2;
S_mean=zeros(M,1);%mean of S to store mean S values and will be used for final pricing.
%adding this next for loop will save us from storing huge MxN matrices so
%that we wont be out of memory. We basically turn all huge matrix
%multiplications into an iterative for loop.
N=int32(N);
S = S0*ones(1,N+1);
sigma2 = sigma0*ones(1,N+1);

for j=1:M
    % two dimensional Brownian motion
    dW1 = randn(1,N+1)*sqrt(h);
    dW2 = rho*dW1 + sqrt(1-rho^2)*randn(1,N+1)*sqrt(h);
    if (Scheme=='E')
        % Solution of the SDE-System with Euler-Maruyama Method
        i=1;
        while i <= N
            sigma2(:,i+1) = sigma2(:,i) + kappa*(theta-sigma2(:,i))*h ...
                + sigma*sqrt(abs(sigma2(:,i))).*dW2(:,i);
            S(:,i+1) = S(:,i).*(1 + r*h + sqrt(abs(sigma2(:,i))).*dW1(:,i));
            i=i+1;
        end
    elseif (Scheme=='M')
        % Solution of the SDE-System with Milstein Method
        i=1;
        while i<=N
            sigma2(:,i+1) = sigma2(:,i) + kappa*(theta-sigma2(:,i))*h ...
                + nu*sqrt(abs(sigma2(:,i))).*dW2(:,i)+1/4*nu^2.*(dW2(:,i).^2-h);
            S(:,i+1) = S(:,i).*(1 + r*h + sqrt(abs(sigma2(:,i))).*dW1(:,i))+1/2*sigma2(:,i).*S(:,i).*(dW1(:,i).^2-h);
            i=i+1;
        end
    else
        disp('Please use a correct scheme.')
        quit
    end
    S_mean(j,1)=mean(S);
end
payoff = exp(-r*T)*max(0,mean(S_mean,2)-K);
stdpayoff = std(payoff);
V(1) = mean(payoff);
V(2) = V(1) - 1.96*stdpayoff/sqrt(M);
V(3) = V(1) + 1.96*stdpayoff/sqrt(M);
tend=toc(tstart);
V(4) = tend;
end




