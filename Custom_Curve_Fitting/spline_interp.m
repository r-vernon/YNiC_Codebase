function [coefs] = spline_interp(x,y,cond)
% fits a cubic interpolating spline through data points (x,y), the spline
% can either be periodic (start point = end point), or natural (default,
% also known as variational).
%
% Input
% x, y - data points you want to fit spline through
% optionally cond specified whether to use 'periodic' or 'natural' splines
%
% Output
% returns the coefficients for the splines that pass through those points

% NOTE
% commented-out bits of code from when y could only be one dimension (Nx1)
% adapted code so it can cope with two dimensions of y (Nx2)

%--------------------------------------------------------------------------
% initial tests/preformatting of input data

% set condition  to 'natural' if no condition specified
if nargin < 3
    cond = 'natural';
end

% just for clarity, specify which method is being used
switch cond(1)
    case 'p'
        disp('Using periodic interpolation');
    otherwise
        disp('Using natural interpolation');
end

% test x, y to make sure they are cols, if rows transpose
if size(x,1) < size(x,2), x = x'; end
if size(y,1) < size(y,2), y = y'; end

%--------------------------------------------------------------------------
% calculate some preliminary variables...

% calculate values of h (width between each pair of break points)
h = diff(x);

% calculate a temp value that's used repeatedly
% tmp = (1./h) .* (y(2:end)-y(1:end-1)); 
tmp = bsxfun(@times,(1./h),(y(2:end,:)-y(1:end-1,:)));

switch cond(1)
    case 'p'
        % calculate values of q and w
        q = 3.*(tmp-circshift(tmp,1));
        w = [2.*(h(1)+h(end)); 2*(h(2:end)+h(1:end-1))];
        
        % create diagonal columns for sparse matrix
        % padding 0 to end/start of h values so length(h) = length(w) (0s are clipped anyway)
        mat_diag = [flipud(h), [h(1:end-1);0], w(:), [0;h(1:end-1)], h];
        mat_size = length(w);
        % create sparse matrix
        sparse_mat = spdiags(mat_diag,[-mat_size+1, -1:1, mat_size-1],mat_size,mat_size);
    otherwise
        % calculate values of q and w
        % q = 3.*(tmp(2:end)-tmp(1:end-1));
        q = 3.*(tmp(2:end,:)-tmp(1:end-1,:));
        w = 2*(h(2:end)+h(1:end-1));
        
        % create diagonal columns for sparse matrix
        mat_diag = [ [h(2:end-1);0], w(:), [0;h(2:end-1)]];
        mat_size = length(w);
        % create sparse matrix
        sparse_mat = spdiags(mat_diag,-1:1,mat_size,mat_size);
end

%--------------------------------------------------------------------------
% calculate coefficients... (in form y = A + Bx + Cx^2 + Dx^3)

% coefficient A(i) = y(i), so don't need to calculate

switch cond(1)
    case 'p'
        % use sparse matrix to calculate C coefficients
        C = sparse_mat\q;
        
        % calculate B coefficients
        % B = tmp - ( (circshift(C,-1) + 2.*C).*(h./3));
        B = tmp - bsxfun(@times,circshift(C,-1) + 2.*C,h./3);
        
        % calculate D coefficients
        D = bsxfun(@rdivide,circshift(C,-1)-C,3.*h(1:end));
    otherwise
        % use sparse matrix to calculate C coefficients (pad 0s as C(0) = C(N) = 0)
        % C = [0; sparse_mat\q; 0];
        C = padarray(sparse_mat\q,[1 0]);
        
        % calculate B coefficients
        % B = tmp - ( (C(2:end) + 2.*C(1:end-1)).*(h./3));
        B = tmp - bsxfun(@times,(C(2:end,:) + 2.*C(1:end-1,:)),(h./3));
        
        % calculate D coefficients
        % D = diff(C) ./ (3.*h);
        D = bsxfun(@rdivide,diff(C),(3.*h));
        
        % tidy up C (remove last zeros)
        C = C(1:end-1,:);
end

%--------------------------------------------------------------------------
% calculate coefficients for ppform

% NOTE: ppform stores coefficients in order Dx^3 + Cx^2 + Bx + A

numDim = size(B);

if numDim(2) == 2 % if two cols in each coefficient, interleave arrays
    coefs = zeros(numDim*2);
    coefs(1:2:end,:) = [D(:,1) C(:,1) B(:,1) y(1:end-1,1)];
    coefs(2:2:end,:) = [D(:,2) C(:,2) B(:,2) y(1:end-1,2)];
else
    coefs = [D C B y(1:end-1)];
end

end
