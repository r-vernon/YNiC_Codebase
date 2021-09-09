function[curve] = parse4spline(x,y)
% Formats (parses) x and y input values so that they can be passed to an
% interpolating spine function Uses Eugene Lee's centripetal scheme to
% determine break points
%
% Returns spline in ppform
% (Heavily based on Matlab's csape.m and cscvn.m)

%{
  EXAMPLE DATA
  question mark
  x = [0 1 1 0 -1 -1 0 0];
  y = [0 0 1 2 1 0 -1 -2];
  heart
  x = [0 0.82 0.92 0 0 -0.92 -0.82 0];
  y = [0.66 0.9 0 -0.83 -0.83 0 0.9 0.66];
%}

%--------------------------------------------------------------------------
% calculate break points with centripetal scheme

% turn x,y into a single points variable (transposing if necessary)
if isrow(x),x = x'; end
if isrow(y),y = y'; end
points = [x,y];

% Want to transpose points, take difference between adjacent points (i.e.
% P(i+1)-P(i) in each column) and square it, put points back in original
% orientation (transpose again), then sum each row together
dt = diff(points).^2;
dt = sum(dt.');

% now take cumulutative sum of dt^(1/4), prepending 0 to start so first
% element of dt isn't skipped over
t = cumsum([0,dt.^(1/4)]);
% (reason it's ^(1/4) is that first we sqrt dt, to undo the previous
% squaring (as ||x||n = (sum(x^n))^(1/n) - i.e. we do the x^n part, in this
% case squaring it, then undo it with the ^(1/n) part ), then take sqrt
% again due to definition of function - Eugene Lee's centripetal scheme)

%--------------------------------------------------------------------------
% examine dt to understand nature of curve (continuous/discontinuous etc)
% dt can't be <1, dt = 0 when current point = prev. point, otherwise dt > 0
% ('adapted' from cscvn.m)

% set end conditions
if points(1,:) == points(end,:)
    endconds = 'periodic';
else
    endconds = 'natural'; % aka variational in cscvn.m
end

% if every point is unique
if all(dt > 0)
    coefs = spline_interp(t,points,endconds);
else
    % find all unique points
    dtp = find(dt > 0);
    % whenever there's a jump >1 between two points, suggests corner
    dtpbig = find(diff(dtp)>1);
    
    % test to see if there's only one piece (i.e. no corners)
    % I *think* this cond. is only met if double point is at end...
    % (leaving it in just to be safe)
    if isempty(dtpbig)
        temp = dtp(1):(dtp(end)+1);
        coefs = spline_interp(t(temp),points(temp,:),endconds);
    else
        % there must be several pieces
        
        % dtpbig contains details of corners, i.e. every point in dtpbig is
        % the end of a segment, add on length(dtp) to include last segment
        dtpbig = [dtpbig,length(dtp)];
        
        % NOTE: imagine dtp = 0,1,2,4,5, diff(dtp) = 1,1,2,1 so dtpbig = 3
        % actual skip in dtp is at 4 so if dtpbig is index use +1
        
        % deal with first segment
        temp = dtp(1):(dtp(dtpbig(1)) +1);
        coefs = spline_interp(t(temp),points(temp,:),'natural');
        % deal with remaining segments
        for i = 2:length(dtpbig)
            temp = dtp(dtpbig(i-1)+1):(dtp(dtpbig(i))+1);
            coefs =[coefs;spline_interp(t(temp),points(temp,:),'natural')];
        end
        t = t([dtp(1) dtp+1]); % removes duplicate point(s)
    end
        
end

curve = mkpp(t,coefs,2);

end