import itertools

# ============================================================
#  TP n2  Exercice 4 : Algorithmes de normalisation
# ============================================================

# Structures de donnees
myrelations = [
    {'A', 'B', 'C', 'G', 'H', 'I'},
    {'X', 'Y'}
]

mydependencies = [
    [{'A'}, {'B'}],     
    [{'A'}, {'C'}],     
    [{'C', 'G'}, {'H'}],
    [{'C', 'G'}, {'I'}],
    [{'B'}, {'H'}]   
]


#  1. Afficher les dependances fonctionnelles
def printDependencies(F: "list of dependencies"):
    for alpha, beta in F:
        print("\t", alpha, " --> ", beta)


#  2. Afficher les relations
def printRelations(T: "list of relations"):
    for R in T:
        print("\t", R)


#  3. Calculer le powerset d'un ensemble
def powerSet(inputset: "set"):
    _result = []
    for r in range(1, len(inputset) + 1):
        _result += map(set, itertools.combinations(inputset, r))
    return _result


#  4. Fermeture d'un ensemble d'attributs K sous F
def closure(F: "list of dependencies", K: "set") -> set:
    """
    Retourne la fermeture de K sous F (K+).
    On part de K et on applique les DF de F jusqu'à stabilité.
    """
    result = set(K)
    changed = True
    while changed:
        changed = False
        for alpha, beta in F:
            if alpha.issubset(result):
                before = len(result)
                result = result.union(beta)
                if len(result) > before:
                    changed = True
    return result


#  5. Fermeture de F (toutes les DF deductibles de F) 
def closureF(F: "list of dependencies", R: "set") -> list:
    """
    Retourne la fermeture de F : toutes les DF alpha -> beta
    deductibles de F sur la relation R.
    """
    result = []
    subsets = powerSet(R)
    for alpha in subsets:
        alpha_set = set(alpha)
        alpha_plus = closure(F, alpha_set)
        for beta in powerSet(alpha_plus):
            beta_set = set(beta)
            if beta_set != alpha_set:
                result.append([alpha_set, beta_set])
    return result


#  6. α determine-t-il fonctionnellement β ?
def determines(F: "list of dependencies", alpha: set, beta: set) -> bool:
    """
    Retourne True si alpha -> beta peut etre deduit de F.
    """
    return beta.issubset(closure(F, alpha))


# 7. K est-il une super-cle ? 
def isSuperKey(F: "list of dependencies", R: set, K: set) -> bool:
    """
    K est une super-cle si K+ = R.
    """
    return closure(F, K) == R


#  8. K est-il une clé candidate ?
def isCandidateKey(F: "list of dependencies", R: set, K: set) -> bool:

    if not isSuperKey(F, R, K):
        return False
    for attr in K:
        subset = K - {attr}
        if subset and isSuperKey(F, R, subset):
            return False
    return True


#  9. Liste de toutes les cles candidate
def allCandidateKeys(F: "list of dependencies", R: set) -> list:
    """
    Retourne la liste de toutes les clés candidates de R sous F.
    """
    keys = []
    for subset in powerSet(R):
        s = set(subset)
        if isCandidateKey(F, R, s):
            keys.append(s)
    return keys


# 10. Liste de toutes les super-cles
def allSuperKeys(F: "list of dependencies", R: set) -> list:
    """
    Retourne la liste de toutes les super-cles de R sous F.
    """
    superkeys = []
    for subset in powerSet(R):
        s = set(subset)
        if isSuperKey(F, R, s):
            superkeys.append(s)
    return superkeys


# 11. Retourner UNE cle candidate
def oneCandidateKey(F: "list of dependencies", R: set) -> set:

    key = set(R)
    for attr in list(R):
        candidate = key - {attr}
        if candidate and isSuperKey(F, R, candidate):
            key = candidate
    return key


# 12. R est-elle en BCNF ?
def isBCNF(F: "list of dependencies", R: set) -> bool:
    """
    R est en bcnf si pour toute DF alpha -> beta non triviale,
    alpha est une super-cle de R.
    """
    for alpha, beta in F:
        alpha = set(alpha)
        beta = set(beta)

        if not alpha.issubset(R) or not beta.issubset(R):
            continue

        if beta.issubset(alpha):
            continue
        if not isSuperKey(F, R, alpha):
            return False
    return True


# 13. Le schema T est-il en BCNF ?
def isSchemaBCNF(F: "list of dependencies", T: "list of relations") -> bool:
    """
    Retourne True si toutes les relations de T sont en bcnf.
    """
    for R in T:

        F_proj = [[set(a) & R, set(b) & R]
                  for a, b in F
                  if set(a).issubset(R) and set(b).issubset(R)]
        if not isBCNF(F_proj, R):
            return False
    return True


# 14. Decomposition BCNF
def bcnfDecomposition(F: "list of dependencies", R: set) -> list:

    result = [R]
    changed = True

    while changed:
        changed = False
        for Ri in result:

            F_proj = [[set(a), set(b)]
                      for a, b in F
                      if set(a).issubset(Ri) and set(b).issubset(Ri)]

            violation = None
            for alpha, beta in F_proj:
                alpha = set(alpha)
                beta = set(beta)
                if beta.issubset(alpha):
                    continue
                if not isSuperKey(F_proj, Ri, alpha):
                    violation = (alpha, beta)
                    break

            if violation:
                alpha, beta = violation
                alpha_plus = closure(F_proj, alpha)
                R1 = alpha_plus & Ri
                R2 = (Ri - alpha_plus) | alpha

                result.remove(Ri)
                result.append(R1)
                result.append(R2)
                changed = True
                break

    return result


#  TESTS
# ============================================================
if __name__ == "__main__":

    print("=" * 50)
    print("1. printDependencies :")
    printDependencies(mydependencies)

    print("\n2. printRelations :")
    printRelations(myrelations)

    print("\n3. powerSet({'A','B','C'}) :")
    for s in powerSet({'A', 'B', 'C'}):
        print("\t", s)

    R_ex = {'A', 'B', 'C', 'G', 'H', 'I'}
    F_ex = mydependencies

    print("\n4. Fermeture de {A} :", closure(F_ex, {'A'}))
    print("   Fermeture de {C,G} :", closure(F_ex, {'C', 'G'}))
    print("   Fermeture de {A,B} :", closure(F_ex, {'A', 'B'}))

    print("\n6. A -> B ?", determines(F_ex, {'A'}, {'B'}))
    print("   A -> H ?", determines(F_ex, {'A'}, {'H'}))
    print("   B -> G ?", determines(F_ex, {'B'}, {'G'}))

    print("\n7. {A,G} est super-cle ?", isSuperKey(F_ex, R_ex, {'A', 'G'}))
    print("   {A} est super cle ?",    isSuperKey(F_ex, R_ex, {'A'}))

    print("\n8. {A,G} est cle candidate ?", isCandidateKey(F_ex, R_ex, {'A', 'G'}))

    print("\n9. Toutes les cles candidates :")
    for k in allCandidateKeys(F_ex, R_ex):
        print("\t", k)

    print("\n10. Toutes les super-cles :")
    for sk in allSuperKeys(F_ex, R_ex):
        print("\t", sk)

    print("\n11. Une cle candidate :", oneCandidateKey(F_ex, R_ex))

    print("\n12. R_ex en bcnf ?", isBCNF(F_ex, R_ex))

    print("\n13. Schema bcnf ?", isSchemaBCNF(F_ex, myrelations))

    print("\n14. Decomposition bcnf de R_ex :")
    decomp = bcnfDecomposition(F_ex, R_ex)
    for r in decomp:
        print("\t", r)
