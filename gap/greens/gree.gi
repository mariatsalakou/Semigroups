#############################################################################
##
#W  gree.gi
#Y  Copyright (C) 2016                                   James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

# This file contains methods for Green's relations and classes of semigroups
# where the particular representation of the Green's classes is not important. 

#############################################################################
##
## Contents:
##
##   1. Technical Green's stuff (types, representative, etc)
##
##   2. Green's relations
##
##   3. Individual Green's classes, and equivalence classes of Green's
##      relations (constructors, size, membership)
##
##   4. Collections of Green's classes (GreensXClasses, XClassReps, NrXClasses)
##
##   5. Idempotents and NrIdempotents
##
##   6. Regularity of Green's classes
##
##   7. Iterators, enumerators etc
##
##   8. Viewing, printing, displaying
##
#############################################################################

#############################################################################
## 1. Technical Green's classes stuff . . .
#############################################################################

# This method differs from the library one in that it always returns true or
# false, whereas the library method gives an error if the types of the classes
# are not the same. 

#TODO move this to the library 

InstallMethod(\=, "for Green's classes",
[IsGreensClass, IsGreensClass],
function(x, y)
  if EquivalenceClassRelation(x) = EquivalenceClassRelation(y) then 
    # the classes are of the same type
    return Parent(x) = Parent(y) and Representative(x) in y;
  fi;
  return false;
end);

InstallMethod(\<, "for Green's classes",
[IsGreensClass, IsGreensClass],
function(x, y)
  if EquivalenceClassRelation(x) = EquivalenceClassRelation(y) then 
    return Parent(x) = Parent(y)
           and RepresentativeSmallest(x) < RepresentativeSmallest(y);
  fi;
  return false;
end);

InstallMethod(IsRegularDClass, "for a D-class of a semigroup",
[IsGreensDClass], IsRegularClass);

InstallMethod(MultiplicativeNeutralElement,
"for a H-class of a semigroup", [IsGreensHClass],
function(H)
  if not IsGroupHClass(H) then
    return fail;
  fi;
  return Idempotents(H)[1];
end);

InstallMethod(IsomorphismPermGroup, "for H-class of a semigroup",
[IsGreensHClass],
function(H)
  local G, p, h;

  if not IsGroupHClass(H) then
    ErrorNoReturn("Semigroups: IsomorphismPermGroup: usage,\n",
                  "the H-class is not a group,");
  fi;

  G := Group(());

  for h in H do
    p := Permutation(h, AsSet(H), OnRight);
    if not p in G then
      G := ClosureGroup(G, p);
      if Size(G) = Size(H) then
        break;
      fi;
    fi;
  od;
  return MappingByFunction(H, G, h -> Permutation(h, AsSet(H), OnRight));
end);

InstallMethod(StructureDescription, "for a Green's H-class",
[IsGreensHClass],
function(H)
  if not IsGroupHClass(H) then
    return fail;
  fi;
  return StructureDescription(Range(IsomorphismPermGroup(H)));
end);

#############################################################################
## 2. Green's relations
#############################################################################

# same method for ideals

InstallMethod(GreensJRelation, "for a finite semigroup",
[IsFinite and IsSemigroup], GreensDRelation);

#############################################################################
## 3. Individual classes . . .
#############################################################################

InstallMethod(OneImmutable, "for an H-class",
[IsGreensHClass],
function(H)
  if not IsGroupHClass(H) then
    TryNextMethod();
  fi;
  return Idempotents(H)[1];
end);

InstallMethod(DClass, "for an R-class", [IsGreensRClass], DClassOfRClass);
InstallMethod(DClass, "for an L-class", [IsGreensLClass], DClassOfLClass);
InstallMethod(DClass, "for an H-class", [IsGreensHClass], DClassOfHClass);
InstallMethod(LClass, "for an H-class", [IsGreensHClass], LClassOfHClass);
InstallMethod(RClass, "for an H-class", [IsGreensHClass], RClassOfHClass);

InstallMethod(GreensJClassOfElement,
"for a finite semigroup and multiplicative element",
[IsSemigroup and IsFinite, IsMultiplicativeElement], GreensDClassOfElement);

# Green's class of a Green's class (finer from coarser)

# Should these be for IsEnumerableSemigroupGreensClassRep?? 

InstallMethod(GreensRClassOfElement,
"for a D-class and multiplicative element",
[IsGreensDClass, IsMultiplicativeElement],
function(D, x)
  return EquivalenceClassOfElement(GreensRRelation(Parent(D)), x);
end);

InstallMethod(GreensLClassOfElement,
"for a D-class and multiplicative element",
[IsGreensDClass, IsMultiplicativeElement],
function(D, x)
  return EquivalenceClassOfElement(GreensLRelation(Parent(D)), x);
end);

InstallMethod(GreensHClassOfElement,
"for a Green's class and multiplicative element",
[IsGreensClass, IsMultiplicativeElement],
function(C, x)
  return EquivalenceClassOfElement(GreensHRelation(Parent(C)), x);
end);

# Green's classes of an element of a semigroup

# Should these be for IsEnumerableSemigroupGreensClassRep?? 

InstallMethod(GreensRClassOfElement,
"for a finite semigroup and multiplicative element",
[IsSemigroup and IsFinite, IsMultiplicativeElement],
function(S, x)
  return EquivalenceClassOfElement(GreensRRelation(S), x);
end);

InstallMethod(GreensLClassOfElement,
"for a finite semigroup and multiplicative element",
[IsSemigroup and IsFinite, IsMultiplicativeElement],
function(S, x)
  return EquivalenceClassOfElement(GreensLRelation(S), x);
end);

InstallMethod(GreensHClassOfElement,
"for a finite semigroup and multiplicative element",
[IsSemigroup and IsFinite, IsMultiplicativeElement],
function(S, x)
  return EquivalenceClassOfElement(GreensHRelation(S), x);
end);

InstallMethod(GreensDClassOfElement,
"for a finite semigroup and multiplicative element",
[IsSemigroup and IsFinite, IsMultiplicativeElement],
function(S, x)
  return EquivalenceClassOfElement(GreensDRelation(S), x);
end);

#############################################################################
## 4. Collections of classes, and reps
#############################################################################

# Numbers of classes . . .

InstallMethod(NrLClasses, "for a Green's D-class",
[IsGreensDClass], D -> Length(GreensLClasses(D)));

InstallMethod(NrRClasses, "for a Green's D-class",
[IsGreensDClass], D -> Length(GreensRClasses(D)));

InstallMethod(NrHClasses, "for a Green's D-class",
[IsGreensDClass], D -> NrRClasses(D) * NrLClasses(D));

InstallMethod(NrHClasses, "for a Green's L-class",
[IsGreensLClass], L -> NrRClasses(DClassOfLClass(L)));

InstallMethod(NrHClasses, "for a Green's R-class",
[IsGreensRClass], R -> NrLClasses(DClassOfRClass(R)));

InstallMethod(NrRegularDClasses, "for a semigroup",
[IsSemigroup], S -> Length(RegularDClasses(S)));

InstallMethod(NrDClasses, "for a semigroup",
[IsSemigroup], S -> Length(GreensDClasses(S)));

InstallMethod(NrLClasses, "for a semigroup",
[IsSemigroup], S -> Length(GreensLClasses(S)));

InstallMethod(NrRClasses, "for a semigroup",
[IsSemigroup], S -> Length(GreensRClasses(S)));

InstallMethod(NrHClasses, "for a semigroup",
[IsSemigroup], S -> Length(GreensHClasses(S)));

# Representatives

InstallMethod(DClassReps, "for a semigroup",
[IsSemigroup], S -> List(GreensDClasses(S), Representative));

InstallMethod(RClassReps, "for a semigroup",
[IsSemigroup], S -> List(GreensRClasses(S), Representative));

InstallMethod(LClassReps, "for a semigroup",
[IsSemigroup], S -> List(GreensLClasses(S), Representative));

InstallMethod(HClassReps, "for a semigroup",
[IsSemigroup], S -> List(GreensHClasses(S), Representative));

InstallMethod(RClassReps, "for a Green's D-class",
[IsGreensDClass], C -> List(GreensRClasses(C), Representative));

InstallMethod(LClassReps, "for a Green's D-class",
[IsGreensDClass], C -> List(GreensLClasses(C), Representative));

InstallMethod(HClassReps, "for a Green's class",
[IsGreensClass], C -> List(GreensHClasses(C), Representative));

# Green's classes of a semigroup

InstallMethod(RegularDClasses, "for a semigroup",
[IsSemigroup], S -> Filtered(GreensDClasses(S), IsRegularDClass));

#TODO PartialOrderOfDClasses

#############################################################################
## 5. Idempotents . . .
#############################################################################

InstallMethod(NrIdempotents, "for a Green's class",
[IsGreensClass], C -> Length(Idempotents(C)));

InstallMethod(Idempotents, "for a Green's class",
[IsGreensClass], C -> Filtered(AsSet(C), IsIdempotent));

#############################################################################
## 6. Regular classes . . .
#############################################################################

InstallMethod(IsRegularClass, "for a Green's class",
[IsGreensClass], C -> First(Enumerator(C), x -> IsIdempotent(x)) <> fail);

InstallTrueMethod(IsRegularClass, IsRegularDClass);
InstallTrueMethod(IsRegularClass, IsInverseOpClass);
InstallTrueMethod(IsHClassOfRegularSemigroup,
                  IsInverseOpClass and IsGreensHClass);

#############################################################################
## 7. Enumerators, iterators etc
#############################################################################

InstallMethod(IteratorOfDClasses, "for a finite semigroup",
[IsSemigroup and IsFinite], GreensDClasses);

InstallMethod(IteratorOfRClasses, "for a finite semigroup",
[IsSemigroup and IsFinite], GreensRClasses);

#############################################################################
## 8. Viewing, printing, etc . . .
#############################################################################

# Viewing, printing, etc

InstallMethod(ViewString, "for a Green's class",
[IsGreensClass],
function(C)
  local str;

  str := "\><";
  Append(str, "\>Green's\< ");

  if IsGreensDClass(C) then
    Append(str, "D");
  elif IsGreensRClass(C) then
    Append(str, "R");
  elif IsGreensLClass(C) then
    Append(str, "L");
  elif IsGreensHClass(C) then
    Append(str, "H");
  fi;
  Append(str, "-class: ");
  Append(str, ViewString(Representative(C)));
  Append(str, ">\<");

  return str;
end);

InstallMethod(ViewString, "for a Green's relation",
[IsGreensRelation], 2, # to beat the method for congruences
function(rel)
  local str;

  str := "\><";
  Append(str, "\>Green's\< ");

  if IsGreensDRelation(rel) then
    Append(str, "D");
  elif IsGreensRRelation(rel) then
    Append(str, "R");
  elif IsGreensLRelation(rel) then
    Append(str, "L");
  elif IsGreensHRelation(rel) then
    Append(str, "H");
  fi;
  Append(str, "-relation of ");
  Append(str, ViewString(Source(rel)));
  Append(str, ">\<");

  return str;
end);

# TODO: remove/improve the library method for congruences, so that this is
# obsolete.

InstallMethod(ViewObj, "for a Green's relation",
[IsGreensRelation], 2, # to beat the method for congruences
function(rel)
  Print(ViewString(rel));
  return;
end);

InstallMethod(PrintObj, "for a Green's class",
[IsGreensClass],
function(C)
  Print(PrintString(C));
  return;
end);

InstallMethod(PrintObj, "for a Green's relation",
[IsGreensRelation], 2,
function(rel)
  Print(PrintString(rel));
  return;
end);

InstallMethod(PrintString, "for a Green's class",
[IsGreensClass],
function(C)
  local str;

  str := "\>\>\>Greens";
  if IsGreensDClass(C) then
    Append(str, "D");
  elif IsGreensRClass(C) then
    Append(str, "R");
  elif IsGreensLClass(C) then
    Append(str, "L");
  elif IsGreensHClass(C) then
    Append(str, "H");
  fi;
  Append(str, "ClassOfElement\<(\>");
  Append(str, PrintString(Parent(C)));
  Append(str, ",\< \>");
  Append(str, PrintString(Representative(C)));
  Append(str, "\<)\<\<");

  return str;
end);

InstallMethod(PrintString, "for a Green's relation",
[IsGreensRelation], 2,
function(rel)
  local str;

  str := "\>\>\>Greens";
  if IsGreensDRelation(rel) then
    Append(str, "D");
  elif IsGreensRRelation(rel) then
    Append(str, "R");
  elif IsGreensLRelation(rel) then
    Append(str, "L");
  elif IsGreensHRelation(rel) then
    Append(str, "H");
  fi;
  Append(str, "Relation\<(\>\n");
  Append(str, PrintString(Source(rel)));
  Append(str, "\<)\<\<");

  return str;
end);