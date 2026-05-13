Files
=====

| priv/priv__a.mli : type t
| priv/priv__b.mli : val f : Priv__a.t -> int
| priv/layer.ml    : module A = Priv__a
|                    module B = Priv__b
| m.ml             : open Layer
|                    module A = A
|                    module B = B
| usage.ml         : let _ = M.B.f

From usage.ml the type of M.B.f in usage.ml can be described as:

- Priv__a.t (but this has a bad score due to the __)
- M.A.t

So `M.A.t` is the clearly preferred candidate — *if* it's in D. The bug is that
it isn't.

Rules-only derivation
=====================

| U  = { M, M.B, M.B.f }       (from U1)

D2 / D3 / D4 / D5 contribute:

- D2:  M, M.B, M.B.f in D.
- D3:  M is a module in U → M.A and M.B in D.
- D3:  M.B is a module in U → M.B.f in D.
- D4:  M.B.f's value description uses `Priv__a.t` → Priv__a.t in D.
- D5:  M's module description mentions `open Layer`, `module A = A`, `module B = B` → Layer, Layer.A, Layer.B in D.

D11 lifts module prefixes:

- Priv__a.t includes Priv__a → add Priv__a to D.

D12 chases module aliases (fix-point):

- M.A is alias to Layer.A; Layer.A is alias to Priv__a.
- Step 1: m = Layer.A, n = Priv__a. p = Priv__a.t (in D) includes Priv__a. Substitute → Layer.A.t. Add.
- Step 2: m = M.A, n = Layer.A. p = Layer.A.t (just added) includes Layer.A. Substitute → M.A.t. Add.

Fixpoint reached. D contains M.A.t.

What the implementation does instead
====================================

The implementation only records D12 as a one-step subst
`Layer.A -> [M.A]` from `d3_rule` processing M's signature. At print
time, `apply_substitutions_fixpoint` looks for a trie key whose prefix
matches `Layer.A` — but the only Type-bearing trie key is `Priv__a.t`
(from D4), whose first segment is `Priv__a`, not `Layer`. The subst
never fires, `M.A.t` never enters D, and the only remaining candidate
is the heavily-penalised `Priv__a.t` (cost 11), which is what gets
printed.

Build the priv library (a, b, layer all in priv/).
  $ mkdir -p priv

  $ cat > priv/priv__a.mli << 'EOF'
  > type t
  > EOF
  $ cat > priv/priv__b.mli << 'EOF'
  > val f : Priv__a.t -> int
  > EOF

  $ $OCAMLC -I priv -c -intf priv/priv__a.mli
  $ $OCAMLC -I priv -c -intf priv/priv__b.mli

  $ cat > priv/layer.ml << 'EOF'
  > module A = Priv__a
  > module B = Priv__b
  > EOF

  $ $OCAMLC -I priv -c -impl priv/layer.ml

Build main.
  $ cat > m.ml << 'EOF'
  > open Layer
  > module A = A
  > module B = B
  > EOF

  $ $OCAMLC -I priv -c -impl m.ml

Usage.ml
  $ cat > usage.ml << 'EOF'
  > let _ = M.B.f
  > EOF

  $ cat > .merlin << 'EOF'
  > FLG -short-paths -nostdlib
  > FLG -log-file - -log-section discourse-recap
  > B .
  > B priv
  > EOF

FIXME: Expected: "M.A.t -> int".
  $ $MERLIN single type-enclosing -position 1:13 -index 0 \
  > -filename usage.ml < usage.ml | jq '.value[0].type'
  # discourse-recap - U
  U at start of D.of_U:
  { u_paths =
    [M -> [{item = (module, M!); env = with env}];
    M.B -> [{item = (module, M!.B); env = with env}];
    M.B.f -> [{item = (value, M!.B.f); env = with env}]];
    substs =
    [] }
  # discourse-recap - next_U
  next_U (non-empty, looping):
  { u_paths =
    [M.B -> [{item = (module, Priv__b!); env = with env}]];
    substs =
    [] }
  # discourse-recap - D
  Final D:
  Discourse {
    size = 17;
    paths =
    int [int/1!];
    Priv__a.t [Priv__a!.t];
    M [M!];
    M.B [Priv__b!; M!.B];
    M.B.f [Priv__b!.f; M!.B.f];
    M.A [M!.A];
    B [Layer!.B];
    substs =
    [Priv__b! -> [M.B];
    Layer!.A -> [M.A];
    Layer!.B -> [M.B]]
    }
  # discourse-recap - U
  U at start of D.of_U:
  { u_paths =
    [];
    substs =
    [Priv__b! -> [M.B];
    Layer!.A -> [M.A];
    Layer!.B -> [M.B]] }
  # discourse-recap - D
  Final D:
  Discourse {
    size = 0;
    paths =
    ;
    substs =
    [Priv__b! -> [M.B];
    Layer!.A -> [M.A];
    Layer!.B -> [M.B]]
    }
  "Priv__a.t -> int"
