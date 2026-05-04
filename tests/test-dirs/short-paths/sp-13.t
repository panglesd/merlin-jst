This mocks the Async --include--> Async_kernel --exports--> Deferred

  $ mkdir async_kernel
  $ cd async_kernel


  $ cat >async_kernel__.ml <<'EOF'
  > module Deferred = Async_kernel__Deferred
  > module Deferred0 = Async_kernel__Deferred0
  > EOF

  $ $OCAMLC -c async_kernel__.ml -no-alias-deps 2>/dev/null
  $ $MERLIN_TEST_OCAML_PATH/bin/ocamlobjinfo -quiet -discourse async_kernel__.cmi
  Discourse:
  Deferred: alias: Async_kernel__Deferred [Async_kernel__Deferred!]
    Async_kernel__Deferred [Async_kernel__Deferred!]
  
  Deferred0: alias: Async_kernel__Deferred0 [Async_kernel__Deferred0!]
    Async_kernel__Deferred0 [Async_kernel__Deferred0!]
  
  $ cat >deferred0.ml <<'EOF'
  > type +'a t = 'a
  > let create : 'a -> 'a t = fun x -> x
  > EOF

  $ cat >deferred0.mli <<'EOF'
  > type +'a t 
  > val create : 'a -> 'a t
  > EOF

  $ $OCAMLC -c deferred0.mli -open Async_kernel__ -o Async_kernel__Deferred0
  $ $OCAMLC -c deferred0.ml -open Async_kernel__ -o Async_kernel__Deferred0



  $ cat >deferred.ml <<'EOF'
  > type +'a t = 'a Deferred0.t
  > 
  > module Let_syntax = struct 
  >   module Let_syntax = struct let return x = Deferred0.create x end
  > end
  > EOF

  $ $OCAMLC -c deferred.ml -open Async_kernel__ -o Async_kernel__Deferred


  $ cat >async_kernel.ml <<'EOF'
  > module Deferred = Deferred
  > include Deferred.Let_syntax
  > EOF

  $ $OCAMLC -c async_kernel.ml -open Async_kernel__


  $ cd ..
  $ mkdir async
  $ cd async

  $ cat >async.ml <<'EOF'
  > include Async_kernel
  > EOF

  $ $OCAMLC -c async.ml -I ../async_kernel
  $ $MERLIN_TEST_OCAML_PATH/bin/ocamlobjinfo -quiet -discourse async.cmi
  Discourse:
  Deferred: alias: Async_kernel.Deferred [Async_kernel!.Deferred]
    Deferred [Async_kernel__!.Deferred]
  
  Let_syntax: alias: Async_kernel.Let_syntax [Async_kernel!.Let_syntax] 
  
  $ cd ..

  $ cat >test.ml <<'EOF'
  > open! Async
  > 
  > let foo = Let_syntax.return 5
  > EOF


  $ $OCAMLC -c test.ml  -I async -I async_kernel

  $ cat >.merlin <<'EOF'
  > FLG -short-paths
  > B .
  > B async
  > B async_kernel
  > EOF

  $ $MERLIN single type-enclosing -position 3:5 \
  > -log-file - -log-section discourse-recap \
  > -nostdlib \
  > -filename test.ml < test.ml 
  # discourse-recap - U
  U at start of D.of_U:
  { u_paths =
    [Async -> [{item = (module, Async!); env = with env}];
    Deferred -> [{item = (module, Async!.Deferred); env = without env}];
    Let_syntax ->
      [{item = (module, Async!.Let_syntax); env = with env};
       {item = (module, Async!.Let_syntax); env = without env}];
    Let_syntax.return ->
      [{item = (value, Async!.Let_syntax.return); env = with env}]];
    substs =
    [Async!.Deferred -> [Deferred];
    Async!.Let_syntax -> [Let_syntax]] }
  # discourse-recap - next_U
  next_U (non-empty, looping):
  { u_paths =
    [Async_kernel -> [{item = (module, Async_kernel!); env = with env}];
    Let_syntax ->
      [{item = (module, Async_kernel__Deferred!.Let_syntax.Let_syntax);
        env = with env}];
    Async_kernel.Let_syntax ->
      [{item = (module, Async_kernel!.Let_syntax); env = with env}]];
    substs =
    [] }
  # discourse-recap - next_U
  next_U (non-empty, looping):
  { u_paths =
    [Async_kernel ->
       [{item = (module, Async_kernel__Deferred!.Let_syntax); env = with env}];
    Deferred -> [{item = (module, Async!.Deferred); env = with env}];
    Async_kernel.Let_syntax ->
      [{item = (module, Async_kernel__Deferred!.Let_syntax.Let_syntax);
        env = with env}];
    Deferred.Let_syntax ->
      [{item = (module, Async!.Deferred.Let_syntax); env = with env}];
    Deferred.Let_syntax.Let_syntax ->
      [{item = (module, Async!.Deferred.Let_syntax.Let_syntax); env = with env}]];
    substs =
    [] }
  # discourse-recap - next_U
  next_U (non-empty, looping):
  { u_paths =
    [Async_kernel -> [{item = (module, Async_kernel!); env = with env}];
    Deferred -> [{item = (module, Async_kernel__Deferred!); env = with env}];
    Async_kernel.Deferred ->
      [{item = (module, Async_kernel!.Deferred); env = with env}];
    Deferred.Let_syntax ->
      [{item = (module, Async_kernel__Deferred!.Let_syntax); env = with env}];
    Deferred.Let_syntax.Let_syntax ->
      [{item = (module, Async_kernel__Deferred!.Let_syntax.Let_syntax);
        env = with env}]];
    substs =
    [] }
  # discourse-recap - next_U
  next_U (non-empty, looping):
  { u_paths =
    [Deferred -> [{item = (module, Async!.Deferred); env = with env}];
    Async_kernel.Deferred ->
      [{item = (module, Async_kernel__Deferred!); env = with env}]];
    substs =
    [] }
  # discourse-recap - next_U
  next_U (non-empty, looping):
  { u_paths =
    [Deferred -> [{item = (module, Async_kernel__Deferred!); env = with env}]];
    substs =
    [] }
  # discourse-recap - D
  Final D:
  Discourse {
    size = 117;
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
    Let_syntax
      [Async!.Let_syntax; Async_kernel__Deferred!.Let_syntax.Let_syntax];
    Let_syntax.return
      [Async!.Let_syntax.return;
       Async_kernel__Deferred!.Let_syntax.Let_syntax.return];
    Deferred
      [Async_kernel__Deferred!; Async!.Deferred; Async_kernel__!.Deferred];
    Deferred.t [Async_kernel__Deferred!.t];
    Deferred.Let_syntax
      [Async_kernel__Deferred!.Let_syntax; Async!.Deferred.Let_syntax];
    Deferred.Let_syntax.Let_syntax
      [Async_kernel__Deferred!.Let_syntax.Let_syntax;
       Async!.Deferred.Let_syntax.Let_syntax];
    Deferred.Let_syntax.Let_syntax.return
      [Async_kernel__Deferred!.Let_syntax.Let_syntax.return];
    Async_kernel [Async_kernel!; Async_kernel__Deferred!.Let_syntax];
    Async_kernel.Let_syntax
      [Async_kernel!.Let_syntax; Async_kernel__Deferred!.Let_syntax.Let_syntax];
    Async_kernel.Let_syntax.return
      [Async_kernel__Deferred!.Let_syntax.Let_syntax.return];
    Async_kernel.Deferred [Async_kernel__Deferred!; Async_kernel!.Deferred];
    Async_kernel.Deferred.t [Async_kernel__Deferred!.t];
    Async_kernel.Deferred.Let_syntax [Async_kernel__Deferred!.Let_syntax];
    Async [Async!];
    Async.Let_syntax [Async!.Let_syntax];
    Async.Deferred [Async!.Deferred];
    substs =
    [Async_kernel__Deferred! -> [Deferred; Async_kernel.Deferred];
    Async!.Deferred -> [Deferred; Async_kernel.Deferred];
    Async!.Let_syntax -> [Let_syntax; Async_kernel.Let_syntax];
    Async_kernel!.Deferred -> [Deferred];
    Async_kernel!.Let_syntax -> [Deferred.Let_syntax.Let_syntax];
    Async_kernel__!.Deferred -> [Async.Deferred; Async_kernel.Deferred];
    Async_kernel__Deferred!.Let_syntax -> [Deferred.Let_syntax];
    Async_kernel__Deferred!.Let_syntax.Let_syntax ->
      [Let_syntax; Async.Let_syntax; Async_kernel.Let_syntax;
       Deferred.Let_syntax.Let_syntax]]
    }
  # discourse-recap - U
  U at start of D.of_U:
  { u_paths =
    [];
    substs =
    [] }
  # discourse-recap - D
  Final D:
  Discourse {
    size = 0;
    paths =
    ;
    substs =
    []
    }
  {
    "class": "return",
    "value": [
      {
        "start": {
          "line": 3,
          "col": 4
        },
        "end": {
          "line": 3,
          "col": 7
        },
        "type": "int Deferred.t",
        "tail": "no"
      }
    ],
    "notifications": []
  }

Dump the discourse so regressions show up as a diff in this test:

  $ $MERLIN single type-enclosing -nostdlib -position 3:5 \
  > -log-file - -log-section discourse-recap \
  > -filename test.ml < test.ml > /dev/null
  # discourse-recap - U
  U at start of D.of_U:
  { u_paths =
    [Async -> [{item = (module, Async!); env = with env}];
    Deferred -> [{item = (module, Async!.Deferred); env = without env}];
    Let_syntax ->
      [{item = (module, Async!.Let_syntax); env = with env};
       {item = (module, Async!.Let_syntax); env = without env}];
    Let_syntax.return ->
      [{item = (value, Async!.Let_syntax.return); env = with env}]];
    substs =
    [Async!.Deferred -> [Deferred];
    Async!.Let_syntax -> [Let_syntax]] }
  # discourse-recap - next_U
  next_U (non-empty, looping):
  { u_paths =
    [Async_kernel -> [{item = (module, Async_kernel!); env = with env}];
    Let_syntax ->
      [{item = (module, Async_kernel__Deferred!.Let_syntax.Let_syntax);
        env = with env}];
    Async_kernel.Let_syntax ->
      [{item = (module, Async_kernel!.Let_syntax); env = with env}]];
    substs =
    [] }
  # discourse-recap - next_U
  next_U (non-empty, looping):
  { u_paths =
    [Async_kernel ->
       [{item = (module, Async_kernel__Deferred!.Let_syntax); env = with env}];
    Deferred -> [{item = (module, Async!.Deferred); env = with env}];
    Async_kernel.Let_syntax ->
      [{item = (module, Async_kernel__Deferred!.Let_syntax.Let_syntax);
        env = with env}];
    Deferred.Let_syntax ->
      [{item = (module, Async!.Deferred.Let_syntax); env = with env}];
    Deferred.Let_syntax.Let_syntax ->
      [{item = (module, Async!.Deferred.Let_syntax.Let_syntax); env = with env}]];
    substs =
    [] }
  # discourse-recap - next_U
  next_U (non-empty, looping):
  { u_paths =
    [Async_kernel -> [{item = (module, Async_kernel!); env = with env}];
    Deferred -> [{item = (module, Async_kernel__Deferred!); env = with env}];
    Async_kernel.Deferred ->
      [{item = (module, Async_kernel!.Deferred); env = with env}];
    Deferred.Let_syntax ->
      [{item = (module, Async_kernel__Deferred!.Let_syntax); env = with env}];
    Deferred.Let_syntax.Let_syntax ->
      [{item = (module, Async_kernel__Deferred!.Let_syntax.Let_syntax);
        env = with env}]];
    substs =
    [] }
  # discourse-recap - next_U
  next_U (non-empty, looping):
  { u_paths =
    [Deferred -> [{item = (module, Async!.Deferred); env = with env}];
    Async_kernel.Deferred ->
      [{item = (module, Async_kernel__Deferred!); env = with env}]];
    substs =
    [] }
  # discourse-recap - next_U
  next_U (non-empty, looping):
  { u_paths =
    [Deferred -> [{item = (module, Async_kernel__Deferred!); env = with env}]];
    substs =
    [] }
  # discourse-recap - D
  Final D:
  Discourse {
    size = 117;
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
    Let_syntax
      [Async!.Let_syntax; Async_kernel__Deferred!.Let_syntax.Let_syntax];
    Let_syntax.return
      [Async!.Let_syntax.return;
       Async_kernel__Deferred!.Let_syntax.Let_syntax.return];
    Deferred
      [Async_kernel__Deferred!; Async!.Deferred; Async_kernel__!.Deferred];
    Deferred.t [Async_kernel__Deferred!.t];
    Deferred.Let_syntax
      [Async_kernel__Deferred!.Let_syntax; Async!.Deferred.Let_syntax];
    Deferred.Let_syntax.Let_syntax
      [Async_kernel__Deferred!.Let_syntax.Let_syntax;
       Async!.Deferred.Let_syntax.Let_syntax];
    Deferred.Let_syntax.Let_syntax.return
      [Async_kernel__Deferred!.Let_syntax.Let_syntax.return];
    Async_kernel [Async_kernel!; Async_kernel__Deferred!.Let_syntax];
    Async_kernel.Let_syntax
      [Async_kernel!.Let_syntax; Async_kernel__Deferred!.Let_syntax.Let_syntax];
    Async_kernel.Let_syntax.return
      [Async_kernel__Deferred!.Let_syntax.Let_syntax.return];
    Async_kernel.Deferred [Async_kernel__Deferred!; Async_kernel!.Deferred];
    Async_kernel.Deferred.t [Async_kernel__Deferred!.t];
    Async_kernel.Deferred.Let_syntax [Async_kernel__Deferred!.Let_syntax];
    Async [Async!];
    Async.Let_syntax [Async!.Let_syntax];
    Async.Deferred [Async!.Deferred];
    substs =
    [Async_kernel__Deferred! -> [Deferred; Async_kernel.Deferred];
    Async!.Deferred -> [Deferred; Async_kernel.Deferred];
    Async!.Let_syntax -> [Let_syntax; Async_kernel.Let_syntax];
    Async_kernel!.Deferred -> [Deferred];
    Async_kernel!.Let_syntax -> [Deferred.Let_syntax.Let_syntax];
    Async_kernel__!.Deferred -> [Async.Deferred; Async_kernel.Deferred];
    Async_kernel__Deferred!.Let_syntax -> [Deferred.Let_syntax];
    Async_kernel__Deferred!.Let_syntax.Let_syntax ->
      [Let_syntax; Async.Let_syntax; Async_kernel.Let_syntax;
       Deferred.Let_syntax.Let_syntax]]
    }
  # discourse-recap - U
  U at start of D.of_U:
  { u_paths =
    [];
    substs =
    [] }
  # discourse-recap - D
  Final D:
  Discourse {
    size = 0;
    paths =
    ;
    substs =
    []
    }
