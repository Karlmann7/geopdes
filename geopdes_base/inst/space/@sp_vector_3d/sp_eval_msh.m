% SP_EVAL: Evaluate a function, given by its degrees of freedom, at a given set of points.
%
%   [eu, F] = sp_eval (u, space, geometry, pts);
%   [eu, F] = sp_eval (u, space, msh);
%   [eu, F] = sp_eval (u, space, msh, opt);
%
% INPUT:
%     
%     u:         vector of dof weights
%     space:     class defining the space (see sp_bspline_2d)
%     geometry:  geometry structure (see geo_load)
%     pts:       coordinates of points along each parametric direction
%     msh:       msh structure
%     opt:       if the option 'recompute' is added, the values of the shape functions in the space structure are recomputed. By default the option is off.
%
% OUTPUT:
%
%     eu: the function evaluated in the given points 
%     F:  grid points in the physical domain, that is, the mapped points
% 
% Copyright (C) 2009, 2010 Carlo de Falco
% Copyright (C) 2011 Rafael Vazquez
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.

%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.

function [eu, F] = sp_eval_msh (u, space, msh);

  F  = msh.geo_map;
  eu = zeros (space.ncomp, msh.nqn, msh.nel);

  nel_col = msh.nelv * msh.nelw;
  for iel = 1:msh.nelu
    [sp_col, elem_list] = sp_evaluate_col (space, msh, iel, 'gradient', false);

    uc_iel = zeros (size (sp_col.connectivity));
    uc_iel(sp_col.connectivity~=0) = ...
          u(sp_col.connectivity(sp_col.connectivity~=0));
    weight = repmat (reshape (uc_iel, [1, sp_col.nsh_max, nel_col]), ...
                                  [msh.nqn, 1, 1]);

    eu(1, :, elem_list) = sum (weight .* reshape (sp_col.shape_functions(1,:,:,:), ...
                                  msh.nqn, sp_col.nsh_max, nel_col), 2);
    eu(2, :, elem_list) = sum (weight .* reshape (sp_col.shape_functions(2,:,:,:), ...
                                  msh.nqn, sp_col.nsh_max, nel_col), 2);
    eu(3, :, elem_list) = sum (weight .* reshape (sp_col.shape_functions(3,:,:,:), ...
                                  msh.nqn, sp_col.nsh_max, nel_col), 2);
  end

end