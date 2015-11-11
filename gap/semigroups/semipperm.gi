#############################################################################
##
#W  semipperm.gi
#Y  Copyright (C) 2013-15                                James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

# This file contains methods for every operation/attribute/property that is
# specific to semigroups of partial perms.

InstallMethod(Idempotents, "for a partial perm semigroup and pos int",
[IsPartialPermSemigroup, IsInt],
function(S, rank)
  local deg;
  deg := DegreeOfPartialPermSemigroup(S);
  return Filtered(Idempotents(S),
                              x -> RankOfPartialPerm(x) = rank);
end);

# this should really be in the library

InstallImmediateMethod(GeneratorsOfSemigroup,
IsPartialPermSemigroup and IsGroup and HasGeneratorsOfGroup,
0, GeneratorsOfGroup);

InstallMethod(RankOfPartialPermSemigroup,
"for a partial perm semigroup",
[IsPartialPermSemigroup], RankOfPartialPermCollection);

#

InstallMethod(IsPartialPermSemigroupGreensClass, "for a Green's class",
[IsGreensClass], x -> IsPartialPermSemigroup(Parent(x)));

#

InstallMethod(Enumerator, "for a symmetric inverse monoid",
[IsSymmetricInverseMonoid],
Maximum(RankFilter(IsActingSemigroup),
        RankFilter(IsSemigroupIdeal and HasGeneratorsOfSemigroupIdeal)) + 1,
#to beat the method for an acting semigroup with generators
function(S)
  local n, record;

  n := DegreeOfPartialPermSemigroup(S);
  record := rec(ElementNumber := function(enum, pos)
                  if pos > Size(S) then
                    return fail;
                  fi;
                  return PartialPermNumber(pos, n);
                end,

                NumberElement := function(enum, elt)
                  if DegreeOfPartialPerm(elt) > n
                      or CoDegreeOfPartialPerm(elt) > n then
                    return fail;
                  fi;
                  return NumberPartialPerm(elt, n);
                end,

                Length := function(enum);
                  return Size(S);
                end,

                Membership := function(elt, enum)
                  return elt in S;
                end,

                PrintObj := function(enum)
                  Print("<enumerator of ", ViewString(S), ">");
                end);

  return EnumeratorByFunctions(S, record);
end);

# TODO improve this

InstallGlobalFunction(SEMIGROUPS_SubsetNumber,
function(m, k, n, set, min, nr, coeff)
  local i;

  nr := nr + 1;

  if k = 1 then
    set[nr] := m + min;
    return set;
  fi;

  i := 1;
  while m > coeff do
    m := m - coeff;
    coeff := coeff * (n - k - i + 1) / (n - i);
    # coeff = Binomial( n - i, k - 1 )
    i := i + 1;
  od;

  min := min + i;
  set[nr] := min;

  return SEMIGROUPS_SubsetNumber(m, k - 1, n - i, set, min, nr,
                                 coeff * (k - 1) / (n - i));
   # coeff = Binomial( n - i - 1, k - 2 )
end);

# the <m>th subset of <[1..n]> with <k> elements
# TODO improve this

InstallMethod(SubsetNumber, "for pos int, pos int, pos int",
[IsPosInt, IsPosInt, IsPosInt],
function(m, k, n)
  return SEMIGROUPS_SubsetNumber(m, k, n, EmptyPlist(k), 0, 0, Binomial(n - 1,
                                 k - 1));
end);

# the position of <set> in the set of subsets of [ 1 .. <n> ] with shortlex
# ordering

InstallMethod(NumberSubset, "for a set and a pos int",
[IsList, IsPosInt],
function(set, n)
  local m, nr, summand, i;

  m := Length(set);

  if m = 0 then
    return 1;
  elif m = 1 then
    return set[1] + 1;
  fi;

  nr := 1;
  summand := n;

  # position in power set before the first set with the same size as set
  for i in [1 .. m - 1] do
    nr := nr + summand;
    summand := summand * (n - i) / (i + 1);
  od;

  return nr + NumberSubsetOfEqualSize(set, n);
end);

#

InstallMethod(NumberSubsetOfEqualSize, "for a set and a pos int",
[IsList, IsPosInt],
function(set, n)
  local m, helper, nr, i;

  m := Length(set);

  if m = 0 then
    return 1;
  elif m = 1 then
    return set[1];
  fi;

  # the position before the first occurrence in the ordered list of <m>-subsets
  # of [ 1 .. <n> ] of set with first element equal to <k>.

  helper := function(n, m, k)
    local summand, sum, j;
    if k = 1 then
      return 0;
    elif m = 1 then
      return k - 1;
    fi;
    summand := Binomial(n - 1, m - 1);
    sum := summand;
    for j in [1 .. k - 2] do
      summand := summand * (n - m - j + 1) / (n - j);
      sum := sum + summand;
    od;
    return sum;
  end;

  nr := helper(n, m, set[1]);
  m := m - 1;

  for i in [2 .. Length(set)] do
    nr := nr + helper(n - set[i - 1], m, set[i] - set[i - 1]);
    m := m - 1;
  od;

  return nr + 1;
end);

#

InstallMethod(PartialPermNumber, "for pos int and pos int",
[IsPosInt, IsPosInt],
function(m, n)
  local i, base, coeff, j;

  if m = 1 then
    return PartialPermNC([]);
  fi;

  m := m - 1;
  i := 1;
  base := [1 .. n];
  coeff := n ^ 2; # Binomial( n, 1 ) * NrArrangements([1..n], 1)

  while m > coeff do
    m := m - coeff;
    i := i + 1;
    coeff := Binomial(n, i) * NrArrangements(base, i);
  od;

  j := 1;
  coeff := NrArrangements(base, i);
  while m > coeff do
    j := j + 1;
    m := m - coeff;
  od;
  return PartialPermNC(SubsetNumber(j, i, n), ArrangementNumber(m, i, n));
end);

#

InstallMethod(NumberPartialPerm, "for a partial perm and a pos int",
[IsPartialPerm, IsPosInt],
function(x, n)
  local dom, k, nr, i;

  dom := DomainOfPartialPerm(x);
  k := Length(dom);

  if k = 0 then
    return 1;
  fi;

  # count all partial perms with smaller image
  nr := 1;
  for i in [1 .. k - 1] do
    nr := nr + Binomial(n, i) * NrArrangements([1 .. n], i);
  od;

  return nr + (NumberSubsetOfEqualSize(dom, n) - 1)
   * NrArrangements([1 .. n], k)
   + NumberArrangement(ImageListOfPartialPerm(x), n);
end);

#

InstallMethod(AsPartialPermSemigroup, "for a semigroup", [IsSemigroup],
function(S)
  return Range(IsomorphismPartialPermSemigroup(S));
end);

# same method for ideals

# same method for ideals

InstallMethod(IsomorphismPermGroup, "for a partial perm semigroup",
[IsPartialPermSemigroup],
function(s)

  if not IsGroupAsSemigroup(s) then
    ErrorMayQuit("Semigroups: IsomorphismPermGroup: usage,\n",
                 "the argument <s> must be a partial perm semigroup ",
                 "satisfying IsGroupAsSemigroup,");
  fi;

  # gaplint: ignore 3
  return MagmaIsomorphismByFunctionsNC(s,
           Group(List(GeneratorsOfSemigroup(s), AsPermutation)),
           AsPermutation,
           x -> AsPartialPerm(x, DomainOfPartialPermCollection(s)));
end);

# it just so happens that the MultiplicativeNeutralElement of a semigroup of
# partial permutations has to coincide with the One. This is not the case for
# transformation semigroups

# same method for ideals

InstallMethod(MultiplicativeNeutralElement, "for a partial perm semigroup",
[IsPartialPermSemigroup], One);

# same method for ideals

InstallMethod(GroupOfUnits, "for a partial perm semigroup",
[IsPartialPermSemigroup],
function(S)
  local H, map, inv, G, deg, U;

  if MultiplicativeNeutralElement(S) = fail then
    return fail;
  fi;

  H := GreensHClassOfElementNC(S, MultiplicativeNeutralElement(S));
  map := IsomorphismPermGroup(H);
  inv := InverseGeneralMapping(map);
  G := Range(map);

  deg := Maximum(DegreeOfPartialPermSemigroup(S),
                 CodegreeOfPartialPermSemigroup(S));

  U := Monoid(List(GeneratorsOfGroup(G), x -> x ^ inv));

  SetIsomorphismPermGroup(U, MappingByFunction(U, G,
                                               x -> x ^ map,
                                               x -> x ^ inv));

  SetIsGroupAsSemigroup(U, true);
  UseIsomorphismRelation(U, G);

  return U;
end);

#

InstallMethod(IsPartialPermSemigroupGreensClass, "for a Green's class",
[IsGreensClass], x -> IsPartialPermSemigroup(Parent(x)));

# the following method is required to beat the method for
# IsPartialPermCollection in the library.

InstallMethod(One, "for a partial perm semigroup ideal",
[IsPartialPermSemigroup and IsSemigroupIdeal],
function(I)
  local pts, x;

  if HasGeneratorsOfSemigroup(I) then
    return One(GeneratorsOfSemigroup(I));
  fi;

  pts := Union(ComponentsOfPartialPermSemigroup(I));
  x := PartialPermNC(pts, pts);

  if x in I then
    return x;
  fi;
  return fail;
end);

#

InstallMethod(CodegreeOfPartialPermSemigroup,
"for a partial perm semigroup ideal",
[IsPartialPermSemigroup and IsSemigroupIdeal],
function(I)
  return CodegreeOfPartialPermCollection(SupersemigroupOfIdeal(I));
end);

#

InstallMethod(DegreeOfPartialPermSemigroup,
"for a partial perm semigroup ideal",
[IsPartialPermSemigroup and IsSemigroupIdeal],
function(I)
  return DegreeOfPartialPermCollection(SupersemigroupOfIdeal(I));
end);

#

InstallMethod(RankOfPartialPermSemigroup,
"for a partial perm semigroup ideal",
[IsPartialPermSemigroup and IsSemigroupIdeal],
function(I)
  return RankOfPartialPermCollection(SupersemigroupOfIdeal(I));
end);

#

InstallMethod(DisplayString,
"for a partial perm semigroup ideal with generators",
[IsPartialPermSemigroup and IsSemigroupIdeal and
 HasGeneratorsOfSemigroupIdeal],
ViewString);

#

InstallMethod(CyclesOfPartialPerm, "for a partial perm", [IsPartialPerm],
function(f)
  local n, seen, out, i, j, cycle;

  n := Maximum(DegreeOfPartialPerm(f), CoDegreeOfPartialPerm(f));
  seen := BlistList([1 .. n], ImageSetOfPartialPerm(f));
  out := [];

  #find chains
  for i in DomainOfPartialPerm(f) do
    if not seen[i] then
      i := i ^ f;
      while i <> 0 do
        seen[i] := false;
        i := i ^ f;
      od;
    fi;
  od;

  #find cycles
  for i in DomainOfPartialPerm(f) do
    if seen[i] then
      j := i ^ f;
      cycle := [j];
      while j <> i do
        seen[j] := false;
        j := j ^ f;
        Add(cycle, j);
      od;
      Add(out, cycle);
    fi;
  od;
  return out;
end);

#

InstallMethod(ComponentRepsOfPartialPermSemigroup,
"for a partial perm semigroup", [IsPartialPermSemigroup],
function(S)
  local pts, reps, next, opts, gens, o, out, i;

  pts := [1 .. DegreeOfPartialPermSemigroup(S)];
  reps := BlistList(pts, []);
  # true=its a rep, false=not seen it, fail=its not a rep
  next := 1;
  opts := rec(lookingfor := function(o, x)
                              if not IsEmpty(x) then
                                return reps[x[1]] = true or reps[x[1]] = fail;
                              else
                                return false;
                              fi;
                            end);

  if IsSemigroupIdeal(S) then
    gens := GeneratorsOfSemigroup(SupersemigroupOfIdeal(S));
  else
    gens := GeneratorsOfSemigroup(S);
  fi;

  repeat
    o := Orb(gens, [next], OnSets, opts);
    Enumerate(o);
    if PositionOfFound(o) <> false
        and reps[o[PositionOfFound(o)][1]] = true then
      if not IsEmpty(o[PositionOfFound(o)]) then
        reps[o[PositionOfFound(o)][1]] := fail;
      fi;
    fi;
    reps[next] := true;
    for i in [2 .. Length(o)] do
      if not IsEmpty(o[i]) then
        reps[o[i][1]] := fail;
      fi;
    od;
    next := Position(reps, false, next);
  until next = fail;

  out := [];
  for i in pts do
    if reps[i] = true then
      Add(out, i);
    fi;
  od;

  return out;
end);

#

InstallMethod(ComponentsOfPartialPermSemigroup,
"for a partial perm semigroup", [IsPartialPermSemigroup],
function(S)
  local pts, comp, next, nr, opts, gens, o, out, i;

  pts := [1 .. DegreeOfPartialPermSemigroup(S)];
  comp := BlistList(pts, []);
  # integer=its component index, false=not seen it
  next := 1;
  nr := 0;
  opts := rec(lookingfor := function(o, x)
                              if not IsEmpty(x) then
                                return IsPosInt(comp[x[1]]);
                              else
                                return false;
                              fi;
                            end);

  if IsSemigroupIdeal(S) then
    gens := GeneratorsOfSemigroup(SupersemigroupOfIdeal(S));
  else
    gens := GeneratorsOfSemigroup(S);
  fi;

  repeat
    o := Orb(gens, [next], OnSets, opts);
    Enumerate(o);
    if PositionOfFound(o) <> false then
      for i in o do
        if not IsEmpty(i) then
          comp[i[1]] := comp[o[PositionOfFound(o)][1]];
        fi;
      od;
    else
      nr := nr + 1;
      for i in o do
        if not IsEmpty(i) then
          comp[i[1]] := nr;
        fi;
      od;
    fi;
    next := Position(comp, false, next);
  until next = fail;

  out := [];
  for i in pts do
    if not IsBound(out[comp[i]]) then
      out[comp[i]] := [];
    fi;
    Add(out[comp[i]], i);
  od;

  return out;
end);

#

InstallMethod(CyclesOfPartialPermSemigroup,
"for a partial perm semigroup", [IsPartialPermSemigroup],
function(S)
  local deg, pts, comp, next, nr, cycles, opts, gens, o, scc, i;

  deg := Maximum(DegreeOfPartialPermSemigroup(S),
                 CodegreeOfPartialPermSemigroup(S));
  pts := [1 .. deg];
  comp := BlistList(pts, []);
  # integer=its component index, false=not seen it
  next := 1;
  nr := 0;
  cycles := [];
  opts := rec(lookingfor := function(o, x)
                              if not IsEmpty(x) then
                                return IsPosInt(comp[x[1]]);
                              else
                                return false;
                              fi;
                            end);

  if IsSemigroupIdeal(S) then
    gens := GeneratorsOfSemigroup(SupersemigroupOfIdeal(S));
  else
    gens := GeneratorsOfSemigroup(S);
  fi;

  repeat
    #JDM the next line doesn't work if OnPoints is used...
    o := Orb(gens, [next], OnSets, opts);
    Enumerate(o);
    if PositionOfFound(o) <> false then
      for i in o do
        if not IsEmpty(i) then
          comp[i[1]] := comp[o[PositionOfFound(o)][1]];
        fi;
      od;
    else
      nr := nr + 1;
      for i in o do
        if not IsEmpty(i) then
          comp[i[1]] := nr;
        fi;
      od;
      scc := First(OrbSCC(o), x -> Length(x) > 1);
      if scc <> fail then
        Add(cycles, List(o{scc}, x -> x[1]));
      fi;
    fi;
    next := Position(comp, false, next);
  until next = fail;

  return cycles;
end);

#

InstallMethod(NaturalLeqInverseSemigroup, "for a partial perm semigroup",
[IsPartialPermSemigroup],
function(S)
  if not IsInverseSemigroup(S) then
    ErrorMayQuit("Semigroups: NaturalLeqInverseSemigroup: usage,\n",
                 "the argument is not an inverse semigroup,");
  fi;
  return NaturalLeqPartialPerm;
end);

#

InstallMethod(SmallerDegreePartialPermRepresentation,
"for an inverse semigroup of partial permutations",
[IsInverseSemigroup and IsPartialPermSemigroup],
function(S)
  local oldgens, newgens, D, e, h, lambdaorb, He, schutz, sigmainv, enum,
  sup, trivialse, orbits, cosets, stabpp, psi, rho, rhoinv, stab, nrcosets, j,
  reps, gen, offset, rep, box, subbox, T, d, k, i, m;

  oldgens := Generators(S);
  newgens := List(oldgens, x -> []);
  D := JoinIrreducibleDClasses(S);

  for d in D do
    e := RightOne(Representative(d));

    # Generate representatives for all the H-Classes in the R-Class of He
    h := HClassReps(GreensRClassOfElement(d, e));
    lambdaorb := List(h, ImageSetOfPartialPerm);

    He := GreensHClassOfElementNC(S, e);
    sup := SupremumIdempotentsNC(Minorants(S, e), e);
    trivialse := not ForAny(He, x -> NaturalLeqInverseSemigroup(S)(sup, x)
                                     and x <> e);

    if IsActingSemigroup(S) then
      schutz := SchutzenbergerGroup(He);
      sigmainv := x -> x ^ InverseGeneralMapping(IsomorphismPermGroup(He));
    else
      schutz := Group(());
      enum := Enumerator(He);
      for k in enum do
        schutz := ClosureGroup(schutz, AsPermutation(k));
      od;
      sigmainv := x -> AsPartialPerm(x, DomainOfPartialPerm(e));
    fi;

    ##  Se is the subgroup of He whose elements have the same minorants as e
    if trivialse then
      orbits := [[ActionDegree(He) + 1]];
      cosets := [e];
      stabpp := He;
    else
      psi := ActionHomomorphism(schutz,
                                Difference(DomainOfPartialPerm(e),
                                           DomainOfPartialPerm(sup)));
      rho := SmallerDegreePermutationRepresentation(Image(psi));
      rhoinv := InverseGeneralMapping(rho);
      orbits := Orbits(Image(rho));
    fi;

    for i in orbits do
      if not trivialse then
        stab := ImagesSet(InverseGeneralMapping(psi),
                          ImagesSet(rhoinv, Stabilizer(Image(rho), i[1])));
        cosets := RightTransversal(schutz, stab);
        stabpp := Set(stab, sigmainv);
      fi;

      # Generate representatives for ALL the cosets the generator will act on
      # Divide every H-Class in the R-Class into 'cosets' like stab in He
      nrcosets := Size(h) * Length(cosets);
      j := 0;
      reps := EmptyPlist(nrcosets);
      for k in [1 .. Size(h)] do
        for m in [1 .. Length(cosets)] do
          j := j + 1;
          reps[j] := cosets[m] * h[k];
        od;
      od;

      # Loop over old generators of S to calculate its action on the cosets
      for j in [1 .. Length(oldgens)] do
        gen := oldgens[j];
        offset := Length(newgens[j]);

        # Loop over cosets to calculate the image of each under the generator
        for k in [1 .. nrcosets] do
          rep := reps[k] * gen;
          # Will the new generator will be defined at this point?
          if not rep * rep ^ (-1) in stabpp then
            Add(newgens[j], 0);
          else
            box := Position(lambdaorb, ImageSetOfPartialPerm(rep));
            if trivialse then
              subbox := 1;
            else
              # instead of AsPermutation we could do ^ sigma
              subbox := PositionCanonical(cosets,
                                          AsPermutation(rep * h[box] ^ -1));
            fi;
            Add(newgens[j], (box - 1) * Length(cosets) + subbox + offset);
          fi;
        od;
      od;
    od;
  od;

  T := InverseSemigroup(List(newgens, x -> PartialPermNC(x)));

  # Return identity mapping if nothing has been accomplished; else the result.
  if NrMovedPoints(T) > NrMovedPoints(S)
      or (NrMovedPoints(T) = NrMovedPoints(S)
          and ActionDegree(T) >= ActionDegree(S)) then
    return IdentityMapping(S);
  fi;

  # gaplint: ignore 3
  return MagmaIsomorphismByFunctionsNC(S, T,
    x -> EvaluateWord(GeneratorsOfSemigroup(T), Factorization(S, x)),
    x -> EvaluateWord(GeneratorsOfSemigroup(S), Factorization(T, x)));
end);

InstallMethod(RepresentativeOfMinimalIdeal,
"for a partial perm semigroup",
[IsPartialPermSemigroup and HasGeneratorsOfSemigroup],
function(S)
  local gens, empty_map, nrgens, min_rank, doms, ims, rank, min_rank_index,
  domain, range, lenrange, deg, codeg, in_nbs, labels, positions, collapsed,
  nr_collapsed, i, act, pos, collapsible, squashed, elts, j, t, im,
  reduced_rank, m, k;

  gens := GeneratorsOfSemigroup(S);
  empty_map := PartialPerm([], []);
  if empty_map in gens then
    return empty_map;
  fi;
  nrgens := Length(gens);

  # Find the minimum rank of a generator
  min_rank := infinity;
  doms := EmptyPlist(nrgens);
  ims := EmptyPlist(nrgens);
  for i in [1 .. nrgens] do
    doms[i] := DomainOfPartialPerm(gens[i]);
    ims[i] := ImageListOfPartialPerm(gens[i]);
    rank := Length(doms[i]);
    if rank < min_rank then
      min_rank := rank;
      min_rank_index := i;
      if min_rank = 1 then
        if not IsIdempotent(gens[i]) then
          return empty_map;
        fi;
      fi;
    fi;
  od;

  # Union of the domains and images of the gens
  domain := Union(doms);
  rank := Length(domain);
  range := Union(ims);
  lenrange := Length(range);
  deg := Maximum(domain);
  codeg := Maximum(range);

  if min_rank = rank and domain = range then
    SetIsGroupAsSemigroup(S, true);
    return gens[1];
  fi;

  if rank = 1 or lenrange = 1 then
    # note that domain <> range otherwise we match the previous if statement.
    # S must contain the empty map: all generators have rank 1
    # And one of those generators has domain <> range
    return empty_map;
  fi;

  # The labelled action graph, defined by in-neighbours
  # Vertex lenrange + 1 corresponds to NULL
  in_nbs := List([1 .. lenrange + 1], x -> []);
  labels := List([1 .. lenrange + 1], x -> []);
  positions := EmptyPlist(codeg);
  for m in [1 .. lenrange] do
    positions[range[m]] := m;
  od;

  # Record of which image points (and how many) can be mapped to NULL
  collapsed := BlistList([1 .. lenrange], []);
  nr_collapsed := 0;
  for m in [1 .. lenrange] do
    i := range[m];
    for j in [1 .. nrgens] do
      act := i ^ gens[j];
      if act = 0 then
        Add(in_nbs[lenrange + 1], m);
        Add(labels[lenrange + 1], j);
        collapsed[m] := true;
        nr_collapsed := nr_collapsed + 1;
        break;
      fi;
      pos := positions[act];
      Add(in_nbs[pos], m);
      Add(labels[pos], j);
      if collapsed[pos] then
        collapsed[m] := true;
        nr_collapsed := nr_collapsed + 1;
        break;
      fi;
    od;
  od;

  # Do we know that every point be mapped to NULL? If so, empty_map is in S
  if nr_collapsed = lenrange then
    return empty_map;
  fi;

  # For each collapsible image point analyse graph find a word to collapse it
  collapsible := BlistList([1 .. codeg], []);
  squashed := [lenrange + 1];
  elts := List([1 .. lenrange + 1], x -> []);
  for i in squashed do
    for k in [1 .. Length(in_nbs[i])] do
      j := in_nbs[i][k];
      if not collapsible[j] then
        collapsible[j] := true;
        elts[j] := Concatenation([labels[i][k]], elts[i]);
        Add(squashed, j);
      fi;
    od;
  od;

  # Can every point be mapped to NULL? If so, empty_map is in S
  if Length(squashed) = lenrange + 1 then
    return empty_map;
  fi;

  # empty_map is not in S; now multiply generators to minimize rank
  t := gens[min_rank_index];
  while true do
    im := ImageListOfPartialPerm(t);
    reduced_rank := false;
    for i in im do
      if collapsible[i] then
        t := t * EvaluateWord(gens, elts[i]);
        reduced_rank := true;
        break;
      fi;
    od;
    if not reduced_rank then
      break;
    fi;
  od;

  return t;
end);
