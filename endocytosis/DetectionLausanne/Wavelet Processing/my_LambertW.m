%% usage: W(z) or W(n,z)
%%
%% Compute the Lambert W function of z.  This function satisfies
%% W(z).*exp(W(z)) = z, and can thus be used to express solutions
%% of transcendental equations involving exponentials or logarithms.
%%
%% n must be integer, and specifies the branch of W to be computed;
%% W(z) is a shorthand for W(0,z), the principal branch.  Branches
%% 0 and -1 are the only ones that can take on non-complex values.
%%
%% If either n or z are non-scalar, the function is mapped to each
%% element; both may be non-scalar provided their dimensions agree.
%%
%% This implementation should return values within 2.5*eps of its
%% counterpart in Maple V, release 3 or later.  Please report any
%% discrepancies to the author, Nici Schraudolph <schraudo@inf.ethz.ch>.
%%
%% For further details, see:
%%
%% Corless, Gonnet, Hare, Jeffrey, and Knuth (1996), "On the Lambert
%% W Function", Advances in Computational Mathematics 5(4):329-359.

%% Author:   Nicol N. Schraudolph <schraudo@inf.ethz.ch>
%% Version:  1.0
%% Created:  07 Aug 1998
%% Keywords: Lambert W Omega special transcendental function

%% Copyright (C) 1998 by Nicol N. Schraudolph
%%
%% This program is free software; you can redistribute and/or
%% modify it under the terms of the GNU General Public
%% License as published by the Free Software Foundation;
%% either version 2, or (at your option) any later version.
%%
%% This program is distributed in the hope that it will be
%% useful, but WITHOUT ANY WARRANTY; without even the implied
%% warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
%% PURPOSE.  See the GNU General Public License for more
%% details.
%%
%% You should have received a copy of the GNU General Public
%% License along with Octave; see the file COPYING.  If not,
%% write to the Free Software Foundation, 59 Temple Place -
%% Suite 330, Boston, MA 02111-1307, USA.

function w = LambertW(b,z)
    if (nargin == 1)
        z = b;
        b = 0;
    else
        %% some error checking
        %
        if (nargin ~= 2)
            usage('result = W(branch, argument)')
        else
            if (any(round(real(b)) ~= b))
                usage('branch number for W must be integer')
            end
        end
    end

    %% series expansion about -1/e
    %
    % p = (1 - 2*abs(b)).*sqrt(2*e*z + 2);
    % w = (11/72)*p;
    % w = (w - 1/3).*p;
    % w = (w + 1).*p - 1
    %
    % first-order version suffices:
    %
    w = (1 - 2*abs(b)).*sqrt(2*exp(1)*z + 2) - 1;

    %% asymptotic expansion at 0 and Inf
    %
    v = log(z + ~(z | b)) + 2*pi*i*b;
    v = v - log(v + ~real(v));

    %% choose strategy for initial guess
    %
    c = abs(z + 1/exp(1));
    c = (c > 1.45 - 1.1*abs(b));
    c = c | (b.*imag(z) > 0) | (~imag(z) & (b == 1));
    w = (1 - c).*w + c.*v;

    %% Halley iteration
    %
    for n = 1:10
        p = exp(w);
        t = w.*p - z;
        f = (w ~= -1);
        t = f.*t./(p.*(w + f) - 0.5*(w + 2.0).*t./(w + f));
        w = w - t;
        if (abs(real(t)) < (2.48*eps)*(1.0 + abs(real(w))) && abs(imag(t)) < (2.48*eps)*(1.0 + abs(imag(w))))
            return
        end
    end
    warning('iteration limit reached, result of W may be inaccurate');
