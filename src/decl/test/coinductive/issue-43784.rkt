#lang racket
(require redex/reduction-semantics
         "../../decl-to-clause.rkt"
         "../../decl-ok.rkt"
         "../../grammar.rkt"
         "../../prove.rkt"
         "../../../util.rkt")

(module+ test
  (redex-let*
   formality-decl

   ((; struct Foo { }
     AdtDecl_Foo (term (Foo (struct () () ((struct-variant ()))))))

    (; trait Partial: Copy { }
     TraitDecl_Partial (term (Partial (trait ((TyKind Self)) ((Implemented (Copy (Self)))) ()))))

    (; trait Complete: Partial { }
     TraitDecl_Complete (term (Complete (trait ((TyKind Self)) ((Implemented (Partial (Self)))) ()))))

    (; impl<T> Partial for T where T: Complete {}
     TraitImplDecl_Partial (term (impl ((TyKind T)) (Partial (T)) ((Implemented (Complete (T)))) ())))

    (; impl<T> Complete for T {}
     TraitImplDecl_CompleteA (term (impl ((TyKind T)) (Complete (T)) () ())))

    (; impl<T: Partial> Complete for T {}
     TraitImplDecl_CompleteB (term (impl ((TyKind T)) (Complete (T)) ((Implemented (Partial (T)))) ())))

    (; crate A { ... }
     CrateDecl_A (term (A (crate (AdtDecl_Foo
                                  TraitDecl_Partial
                                  TraitDecl_Complete
                                  TraitImplDecl_Partial
                                  TraitImplDecl_CompleteA)))))

    (Env_A (term (env-for-crate-decl CrateDecl_A)))

    (; crate B { ... }
     CrateDecl_B (term (B (crate (AdtDecl_Foo
                                  TraitDecl_Partial
                                  TraitDecl_Complete
                                  TraitImplDecl_Partial
                                  TraitImplDecl_CompleteB)))))

    (Env_B (term (env-for-crate-decl CrateDecl_B)))
    )

   (; The crate A is not well-formed:
    ;
    ; the `impl<T> Complete for T` cannot prove that `T: Complete` because it cannot
    ; prove that `T: Copy`.
    traced '()
           (decl:test-cannot-prove
            Env_A
            (crate-ok-goal (CrateDecl_A) CrateDecl_A)))

   (; The crate B, however, IS well-formed.
    traced '()
           (decl:test-can-prove
            Env_B
            (crate-ok-goal (CrateDecl_B) CrateDecl_B)))

   (redex-let*
    formality-decl
    [(Ty_Foo (term (TyRigid Foo ())))]

    (; But `Foo: Partial` does not hold in B.
     traced '()
            (decl:test-cannot-prove
             Env_B
             (Implemented (Partial (Ty_Foo)))))

    (; But `Foo: Partial` implies `Foo: Copy`.
     traced '()
            (decl:test-can-prove
             Env_B
             (Implies ((Implemented (Partial (Ty_Foo)))) (Implemented (Copy (Ty_Foo))))))
    )
   )
  )