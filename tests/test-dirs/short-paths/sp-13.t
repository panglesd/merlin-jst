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
  > FLG -short-paths -nostdlib
  > B .
  > B async
  > B async_kernel
  > EOF

  $ $MERLIN single type-enclosing -position 3:5 \
  > -log-file - -log-section my-short-paths-2 \
  > -filename test.ml < test.ml 
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Async,Async! at pos File "_none_", line 1
  # my-short-paths-2 - shorten
  Current used: { u_paths =
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
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Async,Async! at pos File "_none_", line 1
  # my-short-paths-2 - shorten
  Current used: THERE IS A DA for Let_syntax,Async!.Let_syntax
  # my-short-paths-2 - shorten
  Current used: THERE IS A discourse alias for Async_kernel.Let_syntax,Async_kernel!.Let_syntax at pos File "deferred.ml", line 4, characters 2-66
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Let_syntax,Async_kernel__Deferred!.Let_syntax.Let_syntax at pos File "deferred.ml", line 4, characters 2-66
  # my-short-paths-2 - shorten
  Next U: { u_paths =
    [Async_kernel -> [{item = (module, Async_kernel!); env = with env}];
    Let_syntax ->
      [{item = (module, Async_kernel__Deferred!.Let_syntax.Let_syntax);
        env = with env}];
    Async_kernel.Let_syntax ->
      [{item = (module, Async_kernel!.Let_syntax); env = with env}]];
    substs =
    [] }
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Async_kernel,Async_kernel! at pos File "_none_", line 1
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Let_syntax,Async_kernel__Deferred!.Let_syntax.Let_syntax at pos File "deferred.ml", line 4, characters 2-66
  # my-short-paths-2 - shorten
  Current used: THERE IS A DA for Async_kernel.Let_syntax,Async_kernel!.Let_syntax
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Deferred.Let_syntax.Let_syntax,Async!.Deferred.Let_syntax.Let_syntax at pos File "deferred.ml", line 4, characters 2-66
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Async_kernel.Let_syntax,Async_kernel__Deferred!.Let_syntax.Let_syntax at pos File "deferred.ml", line 4, characters 2-66
  # my-short-paths-2 - shorten
  Next U: { u_paths =
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
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Async_kernel,Async_kernel__Deferred!.Let_syntax at pos File "deferred.ml", line 3, characters 0-98
  # my-short-paths-2 - shorten
  Current used: THERE IS A DA for Deferred,Async!.Deferred
  # my-short-paths-2 - shorten
  Current used: THERE IS A discourse alias for Async_kernel.Deferred,Async_kernel!.Deferred at pos File "async_kernel.ml", line 1, characters 0-26
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Deferred,Async_kernel__Deferred! at pos File "_none_", line 1
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Async_kernel.Let_syntax,Async_kernel__Deferred!.Let_syntax.Let_syntax at pos File "deferred.ml", line 4, characters 2-66
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Deferred.Let_syntax,Async!.Deferred.Let_syntax at pos File "deferred.ml", line 3, characters 0-98
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Deferred.Let_syntax,Async_kernel__Deferred!.Let_syntax at pos File "deferred.ml", line 3, characters 0-98
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Deferred.Let_syntax.Let_syntax,Async!.Deferred.Let_syntax.Let_syntax at pos File "deferred.ml", line 4, characters 2-66
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Deferred.Let_syntax.Let_syntax,Async_kernel__Deferred!.Let_syntax.Let_syntax at pos File "deferred.ml", line 4, characters 2-66
  # my-short-paths-2 - shorten
  Next U: { u_paths =
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
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Async_kernel,Async_kernel! at pos File "_none_", line 1
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Deferred,Async_kernel__Deferred! at pos File "_none_", line 1
  # my-short-paths-2 - shorten
  Current used: THERE IS A DA for Async_kernel.Deferred,Async_kernel!.Deferred
  # my-short-paths-2 - shorten
  Current used: THERE IS A discourse alias for Deferred,Async!.Deferred at pos File "async_kernel.ml", line 1, characters 0-26
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Async_kernel.Deferred,Async_kernel__Deferred! at pos File "_none_", line 1
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Deferred.Let_syntax,Async_kernel__Deferred!.Let_syntax at pos File "deferred.ml", line 3, characters 0-98
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Deferred.Let_syntax.Let_syntax,Async_kernel__Deferred!.Let_syntax.Let_syntax at pos File "deferred.ml", line 4, characters 2-66
  # my-short-paths-2 - shorten
  Next U: { u_paths =
    [Deferred -> [{item = (module, Async!.Deferred); env = with env}];
    Async_kernel.Deferred ->
      [{item = (module, Async_kernel__Deferred!); env = with env}]];
    substs =
    [] }
  # my-short-paths-2 - shorten
  Current used: THERE IS A DA for Deferred,Async!.Deferred
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Deferred,Async_kernel__Deferred! at pos File "_none_", line 1
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Async_kernel.Deferred,Async_kernel__Deferred! at pos File "_none_", line 1
  # my-short-paths-2 - shorten
  Next U: { u_paths =
    [Deferred -> [{item = (module, Async_kernel__Deferred!); env = with env}]];
    substs =
    [] }
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Deferred,Async_kernel__Deferred! at pos File "_none_", line 1
  # my-short-paths-2 - shorten
  Current used: { u_paths =
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
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Async,Async! at pos File "_none_", line 1
  # my-short-paths-2 - shorten
  Current used: THERE IS A DA for Let_syntax,Async!.Let_syntax
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Let_syntax,Async_kernel__Deferred!.Let_syntax.Let_syntax at pos File "deferred.ml", line 4, characters 2-66
  # my-short-paths-2 - shorten
  Next U: { u_paths =
    [Let_syntax ->
       [{item = (module, Async_kernel__Deferred!.Let_syntax.Let_syntax);
         env = with env}]];
    substs =
    [] }
  # my-short-paths-2 - shorten
  Current used: No discourse alias for Let_syntax,Async_kernel__Deferred!.Let_syntax.Let_syntax at pos File "deferred.ml", line 4, characters 2-66
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
