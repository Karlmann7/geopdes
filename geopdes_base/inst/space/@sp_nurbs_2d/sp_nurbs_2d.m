% SP_NURBS_2D: Construct the class of a tensor-product space of NURBS in 2D.
%
%     sp = sp_nurbs_2d (nurbs, msh)
%     sp = sp_nurbs_2d (knots, degree, weights, msh)
%
% INPUTS:
%     
%     nurbs:     nurbs structure representing a surface
%     msh:       msh class containing (in the field msh.qn) the points 
%                along each parametric direction in the parametric 
%                domain at which to evaluate, i.e. quadrature points 
%                or points for visualization (see msh_2d)
%     knots:     open knot vector
%     degree:    nurbs polynomial degree (order minus one)
%     weights:   weights associated to the basis functions
%
% OUTPUT:
%
%    sp: class representing the discrete function space, with the following fields and methods:
%
%        FIELD_NAME      (SIZE)                      DESCRIPTION
%        spu             (struct)                    space of univariate splines in the first parametric direction
%        spv             (struct)                    space of univariate splines in the second parametric direction
%        ndof            (scalar)                    total number of degrees of freedom
%        ndof_dir        (1 x 2 vector)              degrees of freedom along each direction
%        nsh_max         (scalar)                    maximum number of shape functions per element
%        nsh             (1 x msh.nel vector)        actual number of shape functions per each element
%        ncomp           (scalar)                    number of components of the functions of the space (actually, 1)
%        boundary        (1 x 4 struct array)        struct array representing the space of traces of basis functions on each edge
%
%       METHOD_NAME
%       sp_evaluate_col: compute the basis functions in one column of the mesh (that is, fixing the element in the first parametric direction).
%
%       sp_evaluate_row: compute the basis functions in one row of the mesh (that is, fixing the element in the last parametric direction).
%
%       sp_eval:        evaluate a function, given by its dofs, at a given set of points.
%       sp_to_vtk:      export a function, given by its dofs, in the vtk format.
%       sp_h1_error:    evaluate the error in H^1 norm.
%       sp_l2_error:    evaluate the error in L^2 norm.
%
% Copyright (C) 2009, 2010, 2011 Carlo de Falco
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

function sp = sp_nurbs_2d (varargin)

  if (nargin == 2)
    nurbs = varargin{1};
    msh   = varargin{2};

    sp.knots   = nurbs.knots;
    sp.degree  = nurbs.order - 1;
    sp.weights = squeeze (nurbs.coefs(4, :, :));
  elseif (nargin == 4)
    sp.knots   = varargin{1};
    sp.degree  = varargin{2};
    sp.weights = varargin{3};
    msh        = varargin{4};
  else
    error ('sp_nurbs_2d: wrong input arguments. See the help for usage');
  end

  nodes = msh.qn;
  sp.spu = sp_bspline_1d_param (sp.knots{1}, sp.degree(1), nodes{1}, 'gradient', true, 'hessian', true);
  sp.spv = sp_bspline_1d_param (sp.knots{2}, sp.degree(2), nodes{2}, 'gradient', true, 'hessian', true);

  sp.nsh_max  = sp.spu.nsh_max * sp.spv.nsh_max;
  sp.ndof     = sp.spu.ndof * sp.spv.ndof;
  sp.ndof_dir = [sp.spu.ndof, sp.spv.ndof];
  sp.ncomp    = 1;

  mcp = sp.ndof_dir(1);
  ncp = sp.ndof_dir(2); 
  if (~isempty (msh.boundary))
    w_bnd{1} = sp.weights(1,:);
    w_bnd{2} = sp.weights(end,:);
    w_bnd{3} = sp.weights(:,1);
    w_bnd{4} = sp.weights(:,end);

    for iside = 1:numel(msh.boundary)
      ind = mod (floor ((iside+1)/2), 2) + 1;
      bnodes = reshape (squeeze (msh.boundary(iside).quad_nodes(ind,:,:)), ...
                        msh.boundary(iside).nqn, []);
      bnd_iside = sp_bspline_1d_param (sp.knots{ind}, sp.degree(ind), bnodes);
      boundary(iside) = rmfield (bnd_iside, 'shape_function_gradients');
      boundary(iside) = bsp_2_nrb_1d__ (boundary(iside), msh.boundary(iside), w_bnd{iside});
    end
    
    boundary(1).dofs = sub2ind ([mcp, ncp], ones(1,ncp), 1:ncp);
    boundary(2).dofs = sub2ind ([mcp, ncp], mcp*ones(1,ncp), 1:ncp);
    boundary(3).dofs = sub2ind ([mcp, ncp], 1:mcp, ones(1,mcp));
    boundary(4).dofs = sub2ind ([mcp, ncp], 1:mcp, ncp*ones(1,mcp));
    
    sp.boundary = boundary;
  else
    sp.boundary = [];
  end

  sp.constructor = @(MSH) sp_nurbs_2d (sp.knots, sp.degree, sp.weights, MSH);
  sp = class (sp, 'sp_nurbs_2d');

end
