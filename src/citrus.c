

const char * Revision_citrus_c =
   "$Id: citrus.c,v$";

#include <stdlib.h>

#include "src/compiled.h" 

/* import the type from GAP */
Obj PartialPermType;

/* define the type for entries in part. perm */
typedef short int pptype;

/* retrieve entry pos of internal rep of partial perm f */
static inline pptype ELM_PP(Obj f, Int pos)
{
    pptype *data = (pptype *) (ADDR_OBJ(f) + 1);
    return data[pos-1];
}

/* define entry pos of internal rep of partial perm f to be nr */
static inline void SET_ELM_PP(Obj f, Int pos, pptype nr)
{
    pptype *data = (pptype *) (ADDR_OBJ(f) + 1);
    data[pos-1] = nr;
}

static inline Obj NEW_PP(pptype len)
{
    Obj f;

    f = NewBag(T_DATOBJ, sizeof(pptype)*(len)+sizeof(UInt));
    TYPE_DATOBJ(f) = PartialPermType;
    return f;
}

static inline Obj NEW_EMPTY_PP()
{
  Obj f;
  f = NewBag(T_DATOBJ, sizeof(pptype)*1+sizeof(UInt));
  TYPE_DATOBJ(f) = PartialPermType;
  SET_ELM_PP(f, 1, (pptype) 0);
  return f;
}

static inline short int LEN_PP(Obj f)
{
  return (short int) ELM_PP(f,1)+3*ELM_PP(f,2)+6;
}

/* method for f[i] */

Obj FuncELM_LIST_PP( Obj self, Obj f, Obj i)
{ 
  if(INT_INTOBJ(i)>LEN_PP(f)) return Fail;
  return INTOBJ_INT((Int) ELM_PP(f, INT_INTOBJ(i)));
}

/* method for f{list} */

Obj FuncELMS_LIST_PP(Obj self, Obj f, Obj list)
{   Int len, i;
    Obj out;
    
    len = LEN_LIST(list);
    if(len>LEN_PP(f)) len = LEN_PP(f);
    out = NEW_PLIST(T_PLIST_CYC, len);
    SET_LEN_PLIST(out, len);
    
    for(i=1;i<=len;i++){
      SET_ELM_PLIST(out,i,  
        INTOBJ_INT((Int) ELM_PP(f, INT_INTOBJ(ELM_LIST(list, i)))));
    }

    return out;
}

/*******************************************************************************
**
** A partial permutation is of the form:
**
** [degree, rank, min ran, max ran, min, max, img list, dom, ran, Set(ran)] 
**
** where <degree> is the length of <img list>, <rank> is the number of none zero
** entries in the <img list>,  <min ran>, <max ran> are
** self explanatory,  <min> is min(<min dom>, <min ran>), <max> is max(<max 
** dom>, <max ran>), <dom> is the domain, <ran> is the range, <Set(ran)> is the 
** range as a set (not calculated until needed), and <img list> is the list of 
** images with 0 for undefined.
*/

/* create partial perm from sparse representation */

Obj FuncSparsePartialPermNC( Obj self, Obj dom, Obj ran )
{   Int rank, deg, max_ran, min_ran, i, j, k;
    Obj f;

    rank = LEN_LIST(dom);

    if(rank==0){
      return NEW_EMPTY_PP();
    }
    
    deg =  INT_INTOBJ(ELM_LIST(dom, rank));
    f = NEW_PP(6+deg+3*rank);

    SET_ELM_PP(f, 1, (pptype) deg);
    SET_ELM_PP(f, 2, (pptype) rank);

    max_ran=0; 
    min_ran=65535; 

    /* find dense img list, max_ran, min_ran */
    for(i=1;i<=rank;i++){
      j = INT_INTOBJ(ELM_LIST(dom, i));
      SET_ELM_PP(f, 6+deg+i, (pptype) j);
      
      k = INT_INTOBJ(ELM_LIST(ran, i));
      SET_ELM_PP(f, 6+deg+rank+i, (pptype) k);
      SET_ELM_PP(f, j+6, (pptype) k);

      if(k>max_ran){
        max_ran=k;
      }
      if(k<min_ran){
        min_ran=k;
      }
    }

    SET_ELM_PP(f,3,(pptype) min_ran);
    SET_ELM_PP(f,4,(pptype) max_ran);

    /* set min */
    j=INT_INTOBJ(ELM_LIST(dom,1));
    if(min_ran<j){
      SET_ELM_PP(f,5,(pptype) min_ran);
    }else{
      SET_ELM_PP(f,5,(pptype) j);
    }
    
    /* set max */
    if(max_ran>deg){
      SET_ELM_PP(f,6,(pptype) max_ran);
    }else{
      SET_ELM_PP(f,6,(pptype) deg);
    }

    return f;
}

/* create dense partial perm */
Obj FuncDensePartialPermNC( Obj self, Obj img )
{ 
    Obj f;
    Int deg, i, max_ran, min_ran, rank, j;
    Int ran[513];

    if(LEN_LIST(img)==0) return NEW_EMPTY_PP();

    deg = 0;
    for(i=LEN_LIST(img);1<=i;i--)
    {
      if(INT_INTOBJ(ELM_LIST(img, i))!=0) 
      {
        deg = i;
        break;
      }
    }

    if(deg==0) return NEW_EMPTY_PP();
    
    f = NEW_PP(3*deg+6); /* the output*/
    SET_ELM_PP(f, 1, (pptype) deg);
    
    max_ran=0; 
    min_ran=65535; 
    rank=0;

    /* find dom, rank, max_ran, min_ran */
    for(i=1;i<=deg;i++){
      j = INT_INTOBJ(ELM_LIST(img, i));
      SET_ELM_PP(f, i+6, (pptype) j);
      if(j!=0){
        rank++;
        SET_ELM_PP(f, deg+rank+6, (pptype) i); /* dom*/
        ran[rank]=j;
        if(j>max_ran){
          max_ran=j;
          }
        if(j<min_ran){
          min_ran=j;
          }
        }
      }

    SET_ELM_PP(f,2,(pptype) rank);
    SET_ELM_PP(f,3,(pptype) min_ran);
    SET_ELM_PP(f,4,(pptype) max_ran);

    /* set range */
    for(i=1;i<=rank;i++){
      SET_ELM_PP(f,deg+rank+6+i,(pptype) ran[i]);
    } 

    /* set min */
    j=ELM_PP(f,deg+7); /* min. dom. */
    if(min_ran<(short int) j){
      SET_ELM_PP(f,5,(pptype) min_ran);
    }else{
      SET_ELM_PP(f,5,j);
    }
    
    /* set max */
    j=ELM_PP(f,deg+rank+6); /* max. dom. */
    if(max_ran>(short int) j){
      SET_ELM_PP(f,6,(pptype) max_ran);
    }else{
      SET_ELM_PP(f,6,j);
    }

    ResizeBag(f, sizeof(pptype)*(LEN_PP(f))+sizeof(UInt));
    return f;
}

/* product of partial permutations */

Obj FuncProdPP( Obj self, Obj f, Obj g )
{
    Int n, m, deg, rank_f, i, j, r, k, l, max_ran, min_ran, rank;
    Obj fg;
    Int ran[513];

    n = (short int) ELM_PP(f,1);
    m = (short int) ELM_PP(g,1);
    
    if(n==0||m==0) return NEW_EMPTY_PP();
   
    deg = 0;
    rank_f = (short int) ELM_PP(f,2);

    /* find degree/max. dom */
    for(i=rank_f;1<=i;i--)
    {
      j = (short int) ELM_PP(f,6+n+rank_f+i);
      if( j<=m && (short int) ELM_PP(g,j+6)!=0)
      {
        deg = (short int) ELM_PP(f,6+n+i);
        r = i;
        break;
      }
    } 

   if(deg==0) return NEW_EMPTY_PP();

    fg = NEW_PP(3*deg+6);
    SET_ELM_PP(fg, 1, (pptype) deg);
   
    max_ran=0;
    min_ran=(short int) ELM_PP(g,4);
    rank=0;

    for (i=1;i<=r;i++)
    {
      j = (short int) ELM_PP(f,6+n+rank_f+i);
      if(j<=m)
      {
        k = (short int) ELM_PP(g,j+6);
        if(k!=0)
        { 
          rank++;
          l = (short int) ELM_PP(f,6+n+i);
          SET_ELM_PP(fg,deg+rank+6,(pptype) l);
          SET_ELM_PP(fg,l+6, (pptype) k);
          ran[rank]=k;
          if(k>max_ran) max_ran=k;
          if(k<min_ran) min_ran=k;
        }
      }
    }

    SET_ELM_PP(fg,2,(pptype) rank);
    SET_ELM_PP(fg,3,(pptype) min_ran);
    SET_ELM_PP(fg,4,(pptype) max_ran);
    
    for(i=1;i<=rank;i++)
    {
      SET_ELM_PP(fg,deg+rank+6+i,(pptype) ran[i]);
    }
 
    k=ELM_PP(fg,deg+7);
    if(min_ran<(short int) k)
    {
      SET_ELM_PP(fg,5,(pptype) min_ran);
    }
    else
    {
      SET_ELM_PP(fg,5,k);
    }

    k=ELM_PP(fg,deg+rank+6);
    if(max_ran>(short int) k)
    {
      SET_ELM_PP(fg,6,(pptype) max_ran);
    }
    else
    {
      SET_ELM_PP(fg,6,k);
    }

    ResizeBag(fg, sizeof(pptype)*(LEN_PP(fg))+sizeof(UInt));
    return fg;
}

/* comparison for qsort */

int cmp (const void *a, const void *b)
{ Int aa, bb;

 aa = *((const Int *)a);
 bb = *((const Int *)b);
 return (int) (aa-bb);
}

/* range set of partial permutation */

Obj FuncRanSetPartPerm_C ( Obj self, Obj f )
{ Int deg, rank, i;
  Obj out;

  deg = INT_INTOBJ(ELM_PLIST(f, 1));
  rank =  INT_INTOBJ(ELM_PLIST(f, 2));

  if(SIZE_OBJ(f)/sizeof(UInt)<7+deg+2*rank||ADDR_OBJ(f)[7+deg+2*rank]==0){
    for(i=1;i<=rank;i++){
      SET_ELM_PLIST(f,2*rank+deg+6+i, ELM_PLIST(f,rank+deg+6+i));
    }
   qsort(ADDR_OBJ(f)+7+deg+2*rank, rank, sizeof(UInt), cmp);
  }

  out = NEW_PLIST(T_PLIST_CYC,rank);
  SET_LEN_PLIST(out,rank);
  for(i=1;i<=rank;i++){
    SET_ELM_PLIST(out,i, ELM_PLIST(f,2*rank+deg+6+i));
  }
  
  return out;
}

/* inverse of a partial permutation */

Obj FuncInvPartPerm_C ( Obj self, Obj f )
{
    Obj f_inv, j, k;
    Int deg_f, rank, deg_f_inv, n, i;

    deg_f = INT_INTOBJ(ELM_PLIST(f, 1));
    rank =  INT_INTOBJ(ELM_PLIST(f, 2));
    
    /* check if f knows Set(Ran(f)) if not set it */
    if(SIZE_OBJ(f)/sizeof(UInt)<7+deg_f+2*rank||ADDR_OBJ(f)[7+deg_f+2*rank]==0){
      for(i=1;i<=rank;i++){
        SET_ELM_PLIST(f,2*rank+deg_f+6+i, ELM_PLIST(f,rank+deg_f+6+i));
      } 
      qsort(ADDR_OBJ(f)+7+deg_f+2*rank, rank, sizeof(UInt), cmp);
    }

    deg_f_inv = INT_INTOBJ(ELM_PLIST(f, 4));
    n = 3*rank + deg_f_inv + 6; 
    f_inv = NEW_PLIST(T_PLIST_CYC, n);
    SET_LEN_PLIST(f_inv, n); 
 
    SET_ELM_PLIST(f_inv, 1, ELM_PLIST(f, 4));
    SET_ELM_PLIST(f_inv, 2, ELM_PLIST(f, 2));
    SET_ELM_PLIST(f_inv, 3, ELM_PLIST(f, 7+deg_f));
    SET_ELM_PLIST(f_inv, 4, ELM_PLIST(f, 6+deg_f+rank));
    SET_ELM_PLIST(f_inv, 5, ELM_PLIST(f, 5));
    SET_ELM_PLIST(f_inv, 6, ELM_PLIST(f, 6));

    /* initialise dense image list */
    for(i=7;i<=deg_f_inv+6;i++){
      SET_ELM_PLIST(f_inv, i, INTOBJ_INT(0));
    }

    /* set dense img list, dom, and Set(ran) */
    for(i=1;i<=rank;i++){
      j = ELM_PLIST(f,i+deg_f+6);
      k = ELM_PLIST(f,i+deg_f+rank+6);
      SET_ELM_PLIST(f_inv, INT_INTOBJ(k)+6, j); /* dense img */
      SET_ELM_PLIST(f_inv, 6+deg_f_inv+i, ELM_PLIST(f, 6+deg_f+2*rank+i)); 
      SET_ELM_PLIST(f_inv, i+6+deg_f_inv+2*rank, j);
    }

    /* set ran of f_inv */
    for(i=1;i<=rank;i++){
      n = INT_INTOBJ(ELM_PLIST(f_inv, 6+deg_f_inv+i));
      SET_ELM_PLIST(f_inv, i+6+deg_f_inv+rank, ELM_PLIST(f_inv, n+6));
    }

    return f_inv;
}

/* on sets for a partial permutation */ 

Obj FuncOnIntegerSetsWithPartPerm_C (Obj self, Obj set, Obj f)
{ Obj out, j, k;
  Int deg, n, m, i, jj;

  deg = INT_INTOBJ(ELM_PLIST(f, 1));
  n = LEN_PLIST(set);
  if(n==0){
    out = NEW_PLIST(T_PLIST_EMPTY, 0);
    SET_LEN_PLIST(out, 0);
    return out;
  }

  out = NEW_PLIST(T_PLIST_CYC, n);
  m = 0;

  for(i=1;i<=n;i++){
    j = ELM_PLIST(set, i);
    jj = INT_INTOBJ(j);
    if(jj<=deg){
      k = ELM_PLIST(f, jj+6);
      if(INT_INTOBJ(k)!=0){
        m++;
        SET_ELM_PLIST(out, m, k);
      }
    }
  }
  SET_LEN_PLIST(out, m);
  SHRINK_PLIST(out, m);
  SortDensePlist(out);
  return out;
}

/* equality test for partial permutations */

Obj FuncEqPartPerm_C (Obj self, Obj f, Obj g)
{ Int deg_f, deg_g, rank_f, rank_g, i;

    deg_f = INT_INTOBJ(ELM_PLIST(f, 1));
    deg_g = INT_INTOBJ(ELM_PLIST(g, 1));
    
    if(deg_f!=deg_g) return False;
    if(deg_f==0) return True;

    rank_f = INT_INTOBJ(ELM_PLIST(f, 2));
    rank_g = INT_INTOBJ(ELM_PLIST(g, 2));

    if(rank_f!=rank_g) return False;

    /* search for a difference and return False if you find one          */
    for(i=7+deg_f;i<=6+deg_f+2*rank_f;i++){
      if(INT_INTOBJ(ELM_PLIST(f, i)) != INT_INTOBJ(ELM_PLIST(g, i))){
        return False;
      }
    }

    /* otherwise they must be equal                                        */
    return True;
}


/*F * * * * * * * * * * * * * initialize package * * * * * * * * * * * * * * */

/******************************************************************************
*V  GVarFuncs . . . . . . . . . . . . . . . . . . list of functions to export
*/
static StructGVarFunc GVarFuncs [] = {

  { "DensePartialPermNC", 1, "img",
    FuncDensePartialPermNC,
    "pkg/citrus/src/citrus.c:FuncDensePartialPermNC" },
 
  { "SparsePartialPermNC", 2, "dom,ran",
    FuncSparsePartialPermNC,
    "pkg/citrus/src/citrus.c:FuncSparsePartialPermNC" },

  { "ELM_LIST_PP", 2, "f,i", 
    FuncELM_LIST_PP, 
    "pkg/citrus/src/citrus.c:ELM_LIST_PP" },

  { "ELMS_LIST_PP", 2, "f,list",
    FuncELMS_LIST_PP,
    "pkg/citrus/src/citrus.c:ELMS_LIST_PP" },
  
  { "ProdPP", 2, "f,g",
    FuncProdPP,
    "pkg/citrus/src/citrus.c:FuncProdPP" },

  { "RanSetPartPerm_C", 1, "f",
    FuncRanSetPartPerm_C,
    "pkg/citrus/src/citrus.c:FuncRanSetPartPerm_C" },

  { "InvPartPerm_C", 1, "f",
    FuncInvPartPerm_C,
    "pkg/citrus/src/citrus.c:FuncInvPartPerm_C" },

  { "OnIntegerSetsWithPartPerm_C", 2, "set,f",
    FuncOnIntegerSetsWithPartPerm_C,
    "pkg/citrus/src/citrus.c:FuncOnIntegerSetsWithPartPerm_C" },
  
  { "EqPartPerm_C", 2, "f,g",
    FuncEqPartPerm_C,
    "pkg/citrus/src/citrus.c:FuncEqPartPerm_C" },

  { 0 }

};

/******************************************************************************
*F  InitKernel( <module> )  . . . . . . . . initialise kernel data structures
*/
static Int InitKernel ( StructInitInfo *module )
{
    /* init filters and functions                                          */
    InitHdlrFuncsFromTable( GVarFuncs );

    ImportGVarFromLibrary( "PartialPermType", &PartialPermType );

    /* return success                                                      */
    return 0;
}

Obj FuncADD_SET(Obj self, Obj set, Obj obj);

/******************************************************************************
*F  InitLibrary( <module> ) . . . . . . .  initialise library data structures
*/
static Int InitLibrary ( StructInitInfo *module )
{
    Int             i, gvar;
    Obj             tmp;

    /* init filters and functions */
    for ( i = 0;  GVarFuncs[i].name != 0;  i++ ) {
      gvar = GVarName(GVarFuncs[i].name);
      AssGVar(gvar,NewFunctionC( GVarFuncs[i].name, GVarFuncs[i].nargs,
                                 GVarFuncs[i].args, GVarFuncs[i].handler ) );
      MakeReadOnlyGVar(gvar);
    }

    tmp = NEW_PREC(0);
    gvar = GVarName("CITRUSC"); AssGVar( gvar, tmp ); MakeReadOnlyGVar(gvar);

    /* return success                                                      */
    return 0;
}

/******************************************************************************
*F  InitInfopl()  . . . . . . . . . . . . . . . . . table of init functions
*/
static StructInitInfo module = {
#ifdef CITRUSSTATIC
 /* type        = */ MODULE_STATIC,
#else
 /* type        = */ MODULE_DYNAMIC,
#endif
 /* name        = */ "citrus",
 /* revision_c  = */ 0,
 /* revision_h  = */ 0,
 /* version     = */ 0,
 /* crc         = */ 0,
 /* initKernel  = */ InitKernel,
 /* initLibrary = */ InitLibrary,
 /* checkInit   = */ 0,
 /* preSave     = */ 0,
 /* postSave    = */ 0,
 /* postRestore = */ 0
};

#ifndef CITRUSSTATIC
StructInitInfo * Init__Dynamic ( void )
{
  module.revision_c = Revision_citrus_c;
  return &module;
}
#endif

StructInitInfo * Init__citrus ( void )
{
  module.revision_c = Revision_citrus_c;
  return &module;
}




