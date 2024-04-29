function saddlePointIx = saddleFit(f, xp, yp)
%% Might become useful as later reference
% From fit model, get saddle points
syms x y

cn = coeffnames(f);
cv = coeffvalues(f);
form = formula(f);

for ii = 1:length(cn)
    eval([cn{ii},'=',num2str(cv(ii))])
end

fh = eval(form); 

H = hessian(fh);
D = det(H);

ixSaddle = D(xp, yp) < 0;

% Get derivatives
dx = diff(fh, x);
dy = diff(fh, y);

% Solve
ax = solve(dx, [x y], 'Real', true);
ay = solve(dy, [x y], 'Real', true);

% Find where first derivatives are zero
sx = double(ax.x)


end