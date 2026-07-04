function PS = PLOT_STANDARDS()
%PLOT_STANDARDS Return the color names used by the plotting scripts.
%
% Returns
% -------
% PS : struct
%     Small compatibility struct for the original plotting helper package.
%     Values are MATLAB RGB triples in the 0..1 range.

PS.DRed4 = [0.89, 0.10, 0.11];
PS.Red4 = PS.DRed4;
PS.DOrange2 = [1.00, 0.50, 0.00];
PS.MyGreen4 = [0.00, 0.55, 0.20];
PS.Blue1 = [0.12, 0.47, 0.71];
PS.MyBlue4 = [0.00, 0.25, 0.70];
PS.DBlue1 = [0.42, 0.16, 0.55];
end
