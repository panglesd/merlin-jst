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
    size = 91;
    paths =
    unit [unit/7!];
    string [string/19!];
    nativeint [nativeint/13!];
    lexing_position [lexing_position/22!];
    int8x64 [int8x64/42!];
    int8x32 [int8x32/35!];
    int8x16 [int8x16/28!];
    int8 [int8/14!];
    int64x8 [int64x8/45!];
    int64x4 [int64x4/38!];
    int64x2 [int64x2/31!];
    int64 [int64/17!];
    int32x8 [int32x8/37!];
    int32x4 [int32x4/30!];
    int32x16 [int32x16/44!];
    int32 [int32/16!];
    int16x8 [int16x8/29!];
    int16x32 [int16x32/43!];
    int16x16 [int16x16/36!];
    int16 [int16/15!];
    int [int/1!];
    floatarray [floatarray/21!];
    float64x8 [float64x8/48!];
    float64x4 [float64x4/41!];
    float64x2 [float64x2/34!];
    float32x8 [float32x8/40!];
    float32x4 [float32x4/33!];
    float32x16 [float32x16/47!];
    float32 [float32/5!];
    float16x8 [float16x8/32!];
    float16x32 [float16x32/46!];
    float16x16 [float16x16/39!];
    float [float/4!];
    extension_constructor [extension_constructor/20!];
    exn [exn/8!];
    char [char/2!];
    bytes [bytes/3!];
    bool [bool/6!];
    Priv__a.t [Priv__a!.t];
    M [M!];
    M.B [Priv__b!; M!.B];
    M.B.f [Priv__b!.f; M!.B.f];
    M.A [M!.A];
    B [Layer!.B];
    substs =
    [Priv__a! -> [M.A];
    Priv__b! -> [M.B]]
    }
  # discourse-recap - U
  U at start of D.of_U:
  { u_paths =
    [];
    substs =
    [Priv__a! -> [M.A];
    Priv__b! -> [M.B]] }
  # discourse-recap - D
  Final D:
  Discourse {
    size = 0;
    paths =
    ;
    substs =
    [Priv__a! -> [M.A];
    Priv__b! -> [M.B]]
    }
  "M.A.t -> int"
