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
  D2: prev in U so in D (kind: type, path: prev/6[3])
  # discourse-verbose - D6
  D6: merging discourse of type prev
  # discourse-verbose - D2
  D2: t in U so in D (kind: type, path: t/4[1])
  # discourse-verbose - D6
  D6: merging discourse of type t
  # discourse-verbose - D2
  D2: t in U so in D (kind: type, path: t/7[4])
  # discourse-verbose - D6
  D6: merging discourse of type t
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
    [prev -> [{item = (type, prev/6[3]); env = with env}];
    t ->
      [{item = (type, t/4[1]); env = with env};
       {item = (type, t/7[4]); env = with env}]];
    substs =
    [] }
  # discourse-recap - D
  Final D:
  Discourse {
    size = 13;
    paths =
    t [t/4[1]; t/7[4]];
    prev [prev/6[3]];
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
