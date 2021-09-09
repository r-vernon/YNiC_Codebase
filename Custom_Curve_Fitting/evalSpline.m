function[xy] = evalSpline(x,y,usage,param)
% Creates and evaluates a spline in one of two usage scenarios:
% usage = spacing, analogous to x(1):param:x(end)
% usage = number, analogous to linspace(x(1),x(end),param)
%
% returns (x,y) co-ordinates in form (N,2)

% if usage isn't specified properly, test param and guess correct usage
if ~strcmp(usage(1),'s') && ~strcmp(usage(1),'n')
    if param < 1
        usage = 'spacing';
        disp('NOTE: Assuming usage = spacing');
    else
        usage = 'number';
        disp('NOTE: Assuming usage = number');
    end
end

% first just create the spline
curve = parse4spline(x,y);

% create input (t) that will generate xy
switch usage(1)
    case 's'
        t = 0:param:max(curve.breaks);
        
        % append max break to ensure closed curve, if it isn't already there
        if t(end) ~= max(curve.breaks)
            t = [t max(curve.breaks)];
        end
    otherwise
        t = linspace(0,max(curve.breaks),param);
end

xy = ppval(curve,t)';

end
