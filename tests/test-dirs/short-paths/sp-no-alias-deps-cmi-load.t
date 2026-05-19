  $ export BUILD_PATH_PREFIX_MAP="TEST_OCAML=$MERLIN_TEST_OCAML_PATH:$BUILD_PATH_PREFIX_MAP"
  $ cat >base__.ml <<'EOF'
  > module Or_error = Base__Or_error
  > module Not_built = Base__Not_built
  > EOF

  $ cat >or_error.ml <<'EOF'
  > type 'a t = ('a,'a) Result.t
  > let ok (x : 'a) : 'a t = Ok x
  > module Id (X : sig end ) = X
  > EOF

  $ cat >test.ml <<'EOF'
  > let x = Or_error.ok 42
  > EOF

  $ $OCAMLC -c -o Base__Or_error or_error.ml

  $ $OCAMLC -c -no-alias-deps base__.ml
  File "base__.ml", line 2, characters 19-34:
  2 | module Not_built = Base__Not_built
                         ^^^^^^^^^^^^^^^
  Warning 49 [no-cmi-file]: no cmi file was found in path for module Base__Not_built

  $ $OCAMLC -c -open Base__ test.ml

  $ ls
  Base__Or_error.cmi
  Base__Or_error.cmo
  base__.cmi
  base__.cmo
  base__.ml
  or_error.ml
  test.cmi
  test.cmo
  test.ml

  $ cat >.merlin <<'EOF'
  > FLG -short-paths -open Base__
  > EOF

  $ $MERLIN single type-enclosing -log-file log -position 1:4 \
  > -filename test.ml < test.ml | jq '.value[0].type'
  "int Or_error.t"

We should never try to load the cmi for Not_build
  $ cat log | grep reading 
  reading "$TESTCASE_ROOT" from disk
  reading "TEST_OCAML/lib/ocaml" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib.cmi" from disk
  reading "$TESTCASE_ROOT/base__.cmi" from disk
  reading "$TESTCASE_ROOT/Base__Or_error.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Result.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Arg.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Array.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__ArrayLabels.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Atomic.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Backoff.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Bigarray.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Bool.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Buffer.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Bytes.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__BytesLabels.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Callback.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Char.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Complex.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Condition.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Digest.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Domain.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Dynarray.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Effect.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Either.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Ephemeron.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Filename.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Float.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Format.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Fun.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Gc.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Hashtbl.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__In_channel.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Int.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Int32.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Int64.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Lazy.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Lexing.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__List.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__ListLabels.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Map.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Marshal.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Modes.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__MoreLabels.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Mutex.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Nativeint.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Obj.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Oo.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Option.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Out_channel.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Parsing.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Printexc.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Printf.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Queue.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Quote.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Random.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Scanf.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Semaphore.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Seq.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Set.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Stack.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__StdLabels.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__String.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__StringLabels.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Sys.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Type.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Uchar.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Unit.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/stdlib__Weak.cmi" from disk
  reading "TEST_OCAML/lib/ocaml/camlinternalFormatBasics.cmi" from disk
