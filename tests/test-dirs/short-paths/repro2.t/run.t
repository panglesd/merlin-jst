Reproduce a short-paths bug where a wrapped library's mangled name leaks
into the printed type. With dune-style wrapping, querying the type of
`Repro2_main.Topic_name.of_topic` in `usage/src/usage.ml` should print
`Repro2_main.Topic.t -> Repro2_main.Topic_name.t option`, but instead
prints `Repro2_types__.Topic.t -> Repro2_main.Topic_name.t option`.

Build the priv library (no dependencies).
  $ cat > priv/src/repro2_priv__.ml-gen << 'EOF'
  > module No_direct_access_to_repro2_priv = struct
  >   module Repro2_priv = No_such_module
  >   module Repro2_priv__Topic = No_such_module
  >   module Repro2_priv__Topic_name = No_such_module
  > end
  > 
  > (** @canonical Repro2_priv.Repro2_priv *)
  > module Repro2_priv = Repro2_priv
  > 
  > (** @canonical Repro2_priv.Topic *)
  > module Topic = Repro2_priv__Topic
  > 
  > (** @canonical Repro2_priv.Topic_name *)
  > module Topic_name = Repro2_priv__Topic_name
  > EOF

  $ $OCAMLC -w -49 -no-alias-deps -o priv/src/repro2_priv__.cmo \
  >   -c -impl priv/src/repro2_priv__.ml-gen
  $ $OCAMLC -I priv/src -open Repro2_priv__ \
  >   -o priv/src/repro2_priv__Topic.cmi -c -intf priv/src/topic.mli
  $ $OCAMLC -I priv/src -open Repro2_priv__ \
  >   -o priv/src/repro2_priv__Topic.cmo -c -impl priv/src/topic.ml
  $ $OCAMLC -I priv/src -open Repro2_priv__ \
  >   -o priv/src/repro2_priv__Topic_name.cmi -c -intf priv/src/topic_name.mli
  $ $OCAMLC -I priv/src -open Repro2_priv__ \
  >   -o priv/src/repro2_priv__Topic_name.cmo -c -impl priv/src/topic_name.ml
  $ $OCAMLC -I priv/src -open Repro2_priv__ \
  >   -o priv/src/repro2_priv.cmo -c -impl priv/src/repro2_priv.ml

Build the types library (depends on priv).
  $ cat > types/src/repro2_types__.ml-gen << 'EOF'
  > module No_direct_access_to_repro2_types = struct
  >   module Repro2_types = No_such_module
  >   module Repro2_types__Topic = No_such_module
  >   module Repro2_types__Topic_name = No_such_module
  > end
  > 
  > (** @canonical Repro2_types.Repro2_types *)
  > module Repro2_types = Repro2_types
  > 
  > (** @canonical Repro2_types.Topic *)
  > module Topic = Repro2_types__Topic
  > 
  > (** @canonical Repro2_types.Topic_name *)
  > module Topic_name = Repro2_types__Topic_name
  > EOF

  $ $OCAMLC -w -49 -no-alias-deps -o types/src/repro2_types__.cmo \
  >   -c -impl types/src/repro2_types__.ml-gen
  $ $OCAMLC -I types/src -I priv/src -open Repro2_types__ \
  >   -o types/src/repro2_types__Topic.cmi -c -intf types/src/topic.mli
  $ $OCAMLC -I types/src -I priv/src -open Repro2_types__ \
  >   -o types/src/repro2_types__Topic.cmo -c -impl types/src/topic.ml
  $ $OCAMLC -I types/src -I priv/src -open Repro2_types__ \
  >   -o types/src/repro2_types__Topic_name.cmi -c -intf types/src/topic_name.mli
  $ $OCAMLC -I types/src -I priv/src -open Repro2_types__ \
  >   -o types/src/repro2_types__Topic_name.cmo -c -impl types/src/topic_name.ml
  $ $OCAMLC -I types/src -I priv/src -open Repro2_types__ \
  >   -o types/src/repro2_types.cmo -c -impl types/src/repro2_types.ml

Build the main library (depends on types).
  $ cat > main/src/repro2_main__.ml-gen << 'EOF'
  > module No_direct_access_to_repro2_main = struct
  >   module Repro2_main = No_such_module
  > end
  > 
  > (** @canonical Repro2_main.Repro2_main *)
  > module Repro2_main = Repro2_main
  > EOF

  $ $OCAMLC -w -49 -no-alias-deps -o main/src/repro2_main__.cmo \
  >   -c -impl main/src/repro2_main__.ml-gen
  $ $OCAMLC -I main/src -I types/src -I priv/src -open Repro2_main__ \
  >   -o main/src/repro2_main.cmo -c -impl main/src/repro2_main.ml

Create a .merlin in usage/src mirroring what dune would generate.
  $ cat > usage/src/.merlin << 'EOF'
  > FLG -short-paths
  > FLG -log-file - -log-section discourse-recap -nostdlib
  > FLG -open Repro2_standalone__
  > S .
  > B .
  > SH ../../priv/src
  > BH ../../priv/src
  > S ../../types/src
  > B ../../types/src
  > S ../../main/src
  > B ../../main/src
  > EOF

The type of `of_topic` is shown as `Repro2_types__.Topic.t -> ...`, which
mentions the mangled wrapper name `Repro2_types__` rather than the
expected `Repro2_main.Topic.t -> Repro2_main.Topic_name.t option`.
  $ $MERLIN single type-enclosing -position 1:40 -index 0 \
  > -filename usage/src/usage.ml < usage/src/usage.ml \
  > | jq '.value[0].type'
  # discourse-recap - U
  U at start of D.of_U:
  { u_paths =
    [Repro2_main -> [{item = (module, Repro2_main!); env = with env}];
    Repro2_main.Topic_name ->
      [{item = (module, Repro2_main!.Topic_name); env = with env}];
    Repro2_main.Topic_name.of_topic ->
      [{item = (value, Repro2_main!.Topic_name.of_topic); env = with env}]];
    substs =
    [] }
  # discourse-recap - next_U
  next_U (non-empty, looping):
  { u_paths =
    [Repro2_main.Topic_name ->
       [{item = (module, Repro2_types__Topic_name!); env = with env}]];
    substs =
    [] }
  # discourse-recap - D
  Final D:
  Discourse {
    size = 97;
    paths =
    unit [unit/7!];
    t [t/279[1]];
    string [string/19!];
    option [option/12!];
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
    Topic_name [Repro2_types!.Topic_name];
    Topic.t [Repro2_types__!.Topic.t];
    Repro2_main [Repro2_main!];
    Repro2_main.Topic_name [Repro2_types__Topic_name!; Repro2_main!.Topic_name];
    Repro2_main.Topic_name.t [Repro2_types__Topic_name!.t];
    Repro2_main.Topic_name.of_topic
      [Repro2_types__Topic_name!.of_topic; Repro2_main!.Topic_name.of_topic];
    Repro2_main.Topic [Repro2_main!.Topic];
    substs =
    [Repro2_types__Topic! -> [Repro2_main.Topic];
    Repro2_types__Topic_name! -> [Repro2_main.Topic_name]]
    }
  # discourse-recap - U
  U at start of D.of_U:
  { u_paths =
    [];
    substs =
    [Repro2_types__Topic! -> [Repro2_main.Topic];
    Repro2_types__Topic_name! -> [Repro2_main.Topic_name]] }
  # discourse-recap - D
  Final D:
  Discourse {
    size = 0;
    paths =
    ;
    substs =
    [Repro2_types__Topic! -> [Repro2_main.Topic];
    Repro2_types__Topic_name! -> [Repro2_main.Topic_name]]
    }
  # discourse-recap - U
  U at start of D.of_U:
  { u_paths =
    [];
    substs =
    [Repro2_types__Topic! -> [Repro2_main.Topic];
    Repro2_types__Topic_name! -> [Repro2_main.Topic_name]] }
  # discourse-recap - D
  Final D:
  Discourse {
    size = 0;
    paths =
    ;
    substs =
    [Repro2_types__Topic! -> [Repro2_main.Topic];
    Repro2_types__Topic_name! -> [Repro2_main.Topic_name]]
    }
  "Repro2_types__.Topic.t -> Repro2_main.Topic_name.t option"
