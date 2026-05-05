  $ cat >test.ml <<'EOF'
  > type t = Foo
  > module X = struct
  >   type prev = t
  >   type t = Bar
  >   let err (_x : prev) = (Bar : t)
  > end
  > EOF

  $ echo "FLG -short-paths -nostdlib" > .merlin

  $ $MERLIN single type-enclosing -position 5:7 \
  > -log-file - -log-section discourse-verbose \
  > -filename test.ml < test.ml 
  # discourse-verbose - U2
  U2: type t [t/4[1]] defined in current file
  # discourse-verbose - U1
  U1: path type used in file: t/4[1] (File "test.ml", line 3, characters 14-15)
  # discourse-verbose - U2
  U2: type prev [prev/6[3]] defined in current file
  # discourse-verbose - U2
  U2: type t [t/7[4]] defined in current file
  # discourse-verbose - U1
  U1: path type used in file: prev/6[3] (File "test.ml", line 5, characters 16-20)
  # discourse-verbose - U1
  U1: path type used in file: t/7[4] (File "test.ml", line 5, characters 31-32)
  # discourse-verbose - D7
  D7: constructor Bar used, merging its discourse
  # discourse-verbose - U2
  U2: module X [X/12[2]] defined in current file
  # discourse-verbose - U2
  U2: type X.prev [X/12[2].prev] defined in current file
  # discourse-verbose - U2
  U2: type X.t [X/12[2].t] defined in current file
  # discourse-verbose - U2
  U2: value X.err [X/12[2].err] defined in current file
  # discourse-verbose - D2
  D2: X in U so in D (kind: module, path: X/12[2])
  # discourse-verbose - D2
  D2: prev in U so in D (kind: type, path: prev/6[3])
  # discourse-verbose - D6
  D6: merging discourse of type prev
  # discourse-verbose - D2
  D2: prev in U so in D (kind: type, path: prev/6[3])
  # discourse-verbose - D2
  D2: t in U so in D (kind: type, path: t/4[1])
  # discourse-verbose - D6
  D6: merging discourse of type t
  # discourse-verbose - D2
  D2: t in U so in D (kind: type, path: t/7[4])
  # discourse-verbose - D6
  D6: merging discourse of type t
  # discourse-verbose - D2
  D2: t in U so in D (kind: type, path: t/4[1])
  # discourse-verbose - D2
  D2: t in U so in D (kind: type, path: t/7[4])
  # discourse-verbose - D2
  D2: X.err in U so in D (kind: value, path: X/12[2].err)
  # discourse-verbose - D2
  D2: X.prev in U so in D (kind: type, path: X/12[2].prev)
  # discourse-verbose - D2
  D2: X.t in U so in D (kind: type, path: X/12[2].t)
  {
    "class": "return",
    "value": [
      {
        "start": {
          "line": 5,
          "col": 6
        },
        "end": {
          "line": 5,
          "col": 9
        },
        "type": "prev -> t",
        "tail": "no"
      },
      {
        "start": {
          "line": 2,
          "col": 11
        },
        "end": {
          "line": 6,
          "col": 3
        },
        "type": "sig type prev = t type t = Bar val err : prev -> t end",
        "tail": "no"
      },
      {
        "start": {
          "line": 2,
          "col": 0
        },
        "end": {
          "line": 6,
          "col": 3
        },
        "type": "sig type prev = t type t = Bar val err : prev -> t end",
        "tail": "no"
      }
    ],
    "notifications": []
  }

  $ $MERLIN single type-enclosing -position 5:7 \
  > -log-file - -log-section discourse-recap \
  > -filename test.ml < test.ml 
  # discourse-recap - U
  U at start of D.of_U:
  { u_paths =
    [X -> [{item = (module, X/12[2]); env = without env}];
    prev ->
      [{item = (type, prev/6[3]); env = with env};
       {item = (type, prev/6[3]); env = without env}];
    t ->
      [{item = (type, t/4[1]); env = with env};
       {item = (type, t/7[4]); env = with env};
       {item = (type, t/4[1]); env = without env};
       {item = (type, t/7[4]); env = without env}];
    X.err -> [{item = (value, X/12[2].err); env = without env}];
    X.prev -> [{item = (type, X/12[2].prev); env = without env}];
    X.t -> [{item = (type, X/12[2].t); env = without env}]];
    substs =
    [] }
  # discourse-recap - D
  Final D:
  Discourse {
    size = 89;
    paths =
    unit [unit/7!];
    t [t/4[1]; t/7[4]];
    string [string/19!];
    prev [prev/6[3]];
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
    X [X/12[2]];
    X.t [X/12[2].t];
    X.prev [X/12[2].prev];
    X.err [X/12[2].err];
    substs =
    []
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
          "line": 5,
          "col": 6
        },
        "end": {
          "line": 5,
          "col": 9
        },
        "type": "prev -> t",
        "tail": "no"
      },
      {
        "start": {
          "line": 2,
          "col": 11
        },
        "end": {
          "line": 6,
          "col": 3
        },
        "type": "sig type prev = t type t = Bar val err : prev -> t end",
        "tail": "no"
      },
      {
        "start": {
          "line": 2,
          "col": 0
        },
        "end": {
          "line": 6,
          "col": 3
        },
        "type": "sig type prev = t type t = Bar val err : prev -> t end",
        "tail": "no"
      }
    ],
    "notifications": []
  }


  $ $MERLIN single type-enclosing -position 2:0 \
  > -filename test.ml < test.ml | jq '.value[].type'
  "sig type prev = t type t = Bar val err : prev -> t end"
