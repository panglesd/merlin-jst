(*

We call U the set of all paths used directly in a file:

- 1. Any path occurring in the file is in U. For example, List.map occurring in
     the file will add both List.map and List to U.
- 2. All paths for definitions in the current file are in U. So if module M = …
     occurs in the file then M is in U.
- 3. All paths for things “defined” using include or open in the current file
     are in U. It is possible that all of these would end up in D anyway via
     other rules, but it's not entirely obvious so I've included this rule here
     just to make sure they do.
- Note that constructors or fields only used via type-based disambiguation are
  not in U.

We call D the domain of discourse:

- 1. The paths of all the predefined types that are intended for direct use by
     users, like int, are in D.
- 2. If a path is in U then it is also in D.
- 3. If a module path is in U then all the paths of its subcomponents are in D.
- 4. If a value path is in U and its value description was written by a user -
     as opposed to being inferred - then the paths used in that description are
     in D.
- 5. If a module path is in U and its module description was written by a user -
     as opposed to being inferred - then the paths used in that description are
     in D, excluding those paths that only appear inside of a sig…end.
- 6. If a type path is in U then any paths used in its equation or
     representation are in D.
- 7. If a constructor or record field is in U then any paths used in its type
     are in D.
- 8. If a module type path is in U then any paths used in its definition are in
     D, excluding those paths that only appear inside of a sig…end.
- 9. If a class path is in U and its class description was written by a user -
     as opposed to being inferred - then of any paths used in that description
     are in D.
- 10. If a class type path is in U then any paths used in its definition are in
      D.
- 11. If a path is in D and it includes another module path within it, then that
      module path is also in D.
- 12. If a module path m in D - note D not U - is a module alias with target n
      and another path p in D includes n within it, then the path obtained by
      substituting the m for n in p is also in D.
*)

open Shape.Sig_component_kind
open Discourse_types
let log_section = "discourse"
let { Logger.log } = Logger.for_section log_section

module U = struct
  type u_item = { item : Item.t; env : Env.t option }
  let pp_u_item ppf { item = _, item; env } =
    Format.fprintf ppf "%a %s" Path.print item
      (match env with
      | None -> "without env"
      | Some _ -> "with env")
  module ItemSet = Set.Make (struct
    type t = u_item

    let compare i1 i2 = Item.compare i1.item i2.item
  end)

  type u = { u_paths : ItemSet.t Lid_map.t; substs : Lid_set.t Path.Map.t }

  let add_item_set lid item item_set =
    Lid_map.update lid
      (function
        | None -> Some (ItemSet.singleton item)
        | Some set -> Some (ItemSet.add item set))
      item_set

  let empty_discourse = { paths = empty; substs = Path.Map.empty }
  let empty_u : u = { u_paths = Lid_map.empty; substs = Path.Map.empty }
  let g = Local_store.s_ref empty_u

  (** We call U the set of all paths used directly in a file:

    1. Any path occurring in the file is in U. For example, List.map occurring in
       the file will add both List.map and List to U.
    2. All paths for definitions in the current file are in U. So if module M = …
       occurs in the file then M is in U.
    3. All paths for things “defined” using include or open in the current file
       are in U. It is possible that all of these would end up in D anyway via
       other rules, but it's not entirely obvious so I've included this rule here
       just to make sure they do.
    - Note that constructors or fields only used via type-based disambiguation are
      not in U.
*)

  let get () = !g
  let set v = g := v
  let reset () = g := empty_u

  let record_usages = Config.merlin

  (* TODO: do that in D.of_U *)
  (* let add_initial_discourse () = *)
  (*   let d = !g in *)
  (*   g := { d with u_paths = Lid_map.union (Predef.discourse ()) d.paths } *)

  let pp_substs fmt substs =
    let pp_sep ppf () = Format.fprintf ppf ";@;" in
    let pp_v fmt (p, s) =
      Format.fprintf fmt "%a -> [%a]" Path.print p
        (Format.pp_print_list ~pp_sep Pprintast.longident)
        s
    in
    let substs =
      Path.Map.bindings substs
      |> List.map (fun (p, s) -> (p, Lid_set.elements s))
    in
    Format.pp_print_list ~pp_sep pp_v fmt substs

  let fold_on_common_lid_and_path_segments ~init ~kind ~f (lid, path) =
    (* TODO : is it always true that paths prefixes are always Module ?*)
    let rec aux acc kind ((lid, path) : Longident.t * Path.t) =
      let acc = f acc kind (lid, path) in
      match (lid, path) with
      | Lident _, Pident _ -> acc
      | Ldot (l, _), Pdot (p, _) -> aux acc Module (l, p)
      | Lapply (l1, l2), Papply (p1, p2) ->
        let acc = aux acc Module (l2, p2) in
        aux acc Module (l1, p1)
      | _ -> acc
    in
    aux init kind (lid, path)

  let pp_map fmt t =
    let pp_lid_paths ppf (lid, paths) =
      Format.fprintf ppf "%a %a" Pprintast.longident lid pp_u_item paths
    in
    let pp_sep fmt () = Format.fprintf fmt ";@ " in
    Format.fprintf fmt "%a"
      (Format.pp_print_seq ~pp_sep pp_lid_paths)
      (Lid_map.to_seq t)

  let debug_print _fmt = ()
  (* Format.fprintf fmt "Size: %i@;%a@;%a" *)
  (*   (Lid_map.cardinal !g.u_paths) *)
  (*   pp_map !g.u_paths pp_substs !g.substs *)
  (* TODO: do *)

  let log_usage ?loc kind path =
    log ~title:"use" "Use %a\n%!" Logger.fmt (fun fmt ->
        Format.fprintf fmt "%s %a %a"
          (Shape.Sig_component_kind.to_string kind)
          Path.print path
          (fun fmt -> Format.pp_print_option Location.print_loc fmt)
          loc)

  let add_subst path lid =
    log ~title:"add_path_to_discourse" "New substitution %a -> %a" Logger.fmt
      (Fun.flip Path.print path) Logger.fmt
      (Fun.flip Pprintast.longident lid);
    let substs =
      Path.Map.update path
        (function
          | None -> Some (Lid_set.singleton lid)
          | Some lids -> Some (Lid_set.add lid lids))
        !g.substs
    in
    g := { !g with substs }

  (** {1 Rule U2: All paths for definitions in the current file are in U} *)

  let lid_and_path_of_ident ?root_lid ?root_path id =
    let lid =
      match root_lid with
      | Some lid -> Longident.Ldot (lid, Ident.name id)
      | None -> Longident.Lident (Ident.name id)
    in
    let path =
      match root_path with
      | Some path -> Path.Pdot (path, Ident.name id)
      | None -> Path.Pident id
    in
    (lid, path)

  let if_record_usage f = if record_usages then f ()

  let define kind ?root_path ?root_lid id =
    if_record_usage @@ fun () ->
    (* let path, _ = env_lookup lid env in *)
    let lid, path = lid_and_path_of_ident ?root_path ?root_lid id in
    log ~title:"def" "Define %s %a [%a]\n%!"
      (Shape.Sig_component_kind.to_string kind)
      Logger.fmt
      (fun fmt -> Pprintast.longident fmt lid)
      Logger.fmt
      (fun fmt -> Path.print fmt path);
    let discourse = !g in
    g :=
      { discourse with
        u_paths =
          add_item_set lid { item = (kind, path); env = None } discourse.u_paths
      }

  (* ??: Pourquoi avons-nous besoin de define_signature? (Et non seulement des
     [define_{value;type;module;module_type}]) ? Ne risque-t-on pas d'inclure
     deux fois?  Vérifier que l'on a bien envie de récurser dans les
     signatures. *)

  let rec define_signature ?root_path ?root_lid sg =
    log ~title:"def" "Define signature";
    if record_usages then List.iter (define_component ?root_path ?root_lid) sg

  and define_component ?root_path ?root_lid sig_item =
    if record_usages then
      (* let lident id = Longident.Lident (Ident.name id) in *)
      match sig_item with
      | Types.Sig_type (id, _, _, _) -> define_type ?root_path ?root_lid id
      | Types.Sig_value (id, _, _) -> define_value ?root_path ?root_lid id
      | Types.Sig_typext (_, _, _, _) -> ()
      | Types.Sig_module (id, _, md, _, _) ->
        define_module ?root_path ?root_lid md id
      | Types.Sig_modtype (id, _, _) -> define_modtype ?root_path ?root_lid id
      | Types.Sig_class (_, _, _, _) | Types.Sig_class_type (_, _, _, _) ->
        (* TODO: do *) ()

  and define_type ?root_path ?root_lid id = define ?root_path ?root_lid Type id

  and define_value ?root_path ?root_lid id =
    define ?root_path ?root_lid Value id

  and define_module ?root_path ?root_lid (decl : Types.module_declaration) id =
    define Module ?root_path ?root_lid id;
    let root_lid, root_path = lid_and_path_of_ident ?root_path ?root_lid id in
    match decl.md_type with
    (* TODO: Check what to move into D.of_U from the original define_module
       function *)
    | Mty_alias path -> add_subst path root_lid
    | Mty_signature module_type ->
      define_signature ~root_path ~root_lid module_type
    | _ -> ()

  and define_modtype ?root_path ?root_lid id =
    define ?root_path ?root_lid Module_type id

  (** {1 Rule U3}

     All paths for things “defined” using include or open in the current file
     are in U. It is possible that all of these would end up in D anyway via
     other rules, but it's not entirely obvious so I've included this rule here
     just to make sure they do.
  *)

  let define_signature_for_open ~root_path (sg : Subst.Lazy.signature) =
    List.iter
      (fun sig_item ->
        match sig_item with
        | Subst.Lazy.Sig_type (id, _, _, _) -> define_type ~root_path id
        | Sig_value (id, _, _) -> define_value ~root_path id
        | Sig_typext (_, _, _, _) -> ()
        | Sig_module (id, _, _md, _, _) ->
          log ~title:"define_signature_for_open" "Sig_module %a" Logger.fmt
            (Fun.flip Ident.print id);
          let lid, path = lid_and_path_of_ident ~root_path id in
          add_subst path lid;
          define Module ~root_path id
        | Sig_modtype (id, _, _) -> define_modtype ~root_path id
        | Sig_class (_, _, _, _) | Sig_class_type (_, _, _, _) -> (* TODO *) ())
      (Subst.Lazy.force_signature_once sg)

  (* TODO This should be done lazyly*)
  let open_module env path =
    if record_usages then begin
      log ~title:"def" "Open module %a\n%!" Logger.fmt (fun fmt ->
          Path.print fmt path);
      try
        (* When opening we need to traverse the aliases to get the components *)
        let root_path = Env.normalize_module_path None env path in
        let md = Env.find_module_lazy root_path env in
        match md.md_type with
        | Mty_signature sg -> define_signature_for_open ~root_path sg
        | _ -> ()
      with Not_found -> ()
    end

  (** {1 Rule U1}

      Any path occurring in the file is in U. For example, List.map occurring in
      the file will add both List.map and List to U.
  *)

  let add_used env kind lid path t =
    let loc = lid.Location.loc in
    let f acc kind (lid, path) =
      let () = log_usage ~loc kind path in
      try
        let u_paths =
          add_item_set lid { item = (kind, path); env = Some env } acc.u_paths
        in
        { acc with u_paths }
      with Not_found | Env.Error (Lookup_error _) -> acc
    in
    fold_on_common_lid_and_path_segments ~init:t ~kind ~f (lid.txt, path)

  let use_module env lid path = add_used env Module lid path
  let use_modtype env lid path = add_used env Module_type lid path
  let use_type env lid path = add_used env Type lid path
  let use_value env lid path = add_used env Value lid path

  (* TODO: this should be done in D.of_U *)
  (* let use_constructor (constr : Types.constructor_description) = *)
  (*   if record_usages then begin *)
  (*     (\* If a constructor is in U then any paths used in its type are in D. *\) *)
  (*     g := { !g with paths = Lid_trie.union !g.paths constr.cstr_discourse } *)
  (*   end *)

  (* let use_label (label : _ Types.gen_label_description) = *)
  (*   if record_usages then begin *)
  (*     (\* If a label is in U then any paths used in its type are in D. *\) *)
  (*     g := { !g with paths = Lid_trie.union !g.paths label.lbl_discourse } *)
  (*   end *)
end

module D = struct
  (**

     {2 The domain of discourse}

     - [x] 1. The paths of all the predefined types that are intended for direct use by
       users, like int, are in D.

     This is already ok since they have been added in U... (TODO: move here?)

     - [x ]2. If a path is in U then it is also in D.
     - 3. If a module path is in U then all the paths of its subcomponents are in D.
     - 4. If a value path is in U and its value description was written by a user -
       as opposed to being inferred - then the paths used in that description are
       in D.
     - 5. If a module path is in U and its module description was written by a user -
       as opposed to being inferred - then the paths used in that description are
       in D, excluding those paths that only appear inside of a sig…end.
     - 6. If a type path is in U then any paths used in its equation or
       representation are in D.
     - 7. If a constructor or record field is in U then any paths used in its type
       are in D.
     - 8. If a module type path is in U then any paths used in its definition are in
       D, excluding those paths that only appear inside of a sig…end.
     - 9. If a class path is in U and its class description was written by a user -
       as opposed to being inferred - then of any paths used in that description
       are in D.
     - 10. If a class type path is in U then any paths used in its definition are in
       D.
     - 11. If a path is in D and it includes another module path within it, then that
       module path is also in D.
     - 12. If a module path m in D - note D not U - is a module alias with target n
       and another path p in D includes n within it, then the path obtained by
       substituting the m for n in p is also in D.
  *)

  (* TODO: check if that is necessary
     This might not be necessary if we have a clearer two-step process ?
     Currently the handling of aliases can create loops. *)
  let already_used : (Path.t, unit) Hashtbl.t = Hashtbl.create 256

  (* TODO *)
  let special_rule_for_aliases env { paths; substs } u_next path alias_lid
      alias_path =
    try
      let path', _ = Env.find_module_by_name_lazy alias_lid.Location.txt env in
      log ~title:"add_path_to_discourse" "Adding alias: %a %a %a" Logger.fmt
        (Fun.flip Pprintast.longident alias_lid.txt)
        Logger.fmt
        (Fun.flip Path.print alias_path)
        Logger.fmt
        (Fun.flip Path.print path');

      let substs =
        log ~title:"add_path_to_discourse" "New substitution 1' %a -> %a (%a)"
          Logger.fmt (Fun.flip Path.print path) Logger.fmt
          (Fun.flip Pprintast.longident alias_lid.txt)
          Logger.fmt
          (Fun.flip Location.print_loc alias_lid.loc);
        Path.Map.update path
          (function
            | None -> Some (Lid_set.singleton alias_lid.txt)
            | Some lids -> Some (Lid_set.add alias_lid.txt lids))
          substs
      in
      if Hashtbl.mem already_used path' then ({ paths; substs }, u_next)
      else begin
        Hashtbl.add already_used path' ();
        let u_next = U.use_module env alias_lid path' u_next in
        ({ paths; substs }, u_next)
      end
    with Not_found -> ({ paths; substs }, u_next)

  let d3_rule env lid path paths substs sig_ =
    let ldot id = Longident.Ldot (lid, Ident.name id) in
    let pdot id = Path.Pdot (path, Ident.name id) in
    List.fold_left
      (fun (paths, substs) ->
        let add kind id =
          log ~title:"add_path_to_discourse"
            "Adding signature component %s %a (%a)"
            (Shape.Sig_component_kind.to_string kind)
            Logger.fmt
            (fun fmt -> Ident.print fmt id)
            Logger.fmt
            (Fun.flip Path.print (pdot id));
          Lid_trie.add (ldot id) (kind, pdot id) paths
        in
        function
        | Subst.Lazy.Sig_value (id, _, _) -> (add Value id, substs)
        | Subst.Lazy.Sig_type (id, _, _, _) -> (add Type id, substs)
        | Subst.Lazy.Sig_typext (id, _, _, _) ->
          (add Extension_constructor id, substs)
        | Subst.Lazy.Sig_module (id, _, _, _, _) ->
          let md = Env.find_module_lazy (pdot id) env in
          let paths = add Module id in
          let substs =
            match md.md_type with
            | Mty_alias path' ->
              let lid = ldot id in
              log ~title:"add_path_to_discourse" "New substitution 2 %a -> %a"
                Logger.fmt
                (Fun.flip Path.print path')
                Logger.fmt
                (Fun.flip Pprintast.longident lid);
              Path.Map.update path'
                (function
                  | None -> Some (Lid_set.singleton lid)
                  | Some lids -> Some (Lid_set.add lid lids))
                substs
            | _ -> substs
          in
          (paths, substs)
        | Subst.Lazy.Sig_modtype (id, _, _) -> (add Module_type id, substs)
        | Subst.Lazy.Sig_class (id, _, _, _) -> (add Class id, substs)
        | Subst.Lazy.Sig_class_type (id, _, _, _) -> (add Class_type id, substs))
      (paths, substs)
      (Subst.Lazy.force_signature_once sig_)

  let module_consequences { paths; substs } u_next env lid path :
      discourse * U.u =
    let (paths, substs), u_next =
      let md = Env.find_module_lazy path env in
      let { paths; substs }, u_next =
        match md.md_discourse_alias with
        | None -> ({ paths; substs }, u_next)
        | Some (alias_lid, (_, alias_path)) ->
          special_rule_for_aliases env { paths; substs } u_next path alias_lid
            alias_path
      in
      (* D5. If a module path is in U and its module description was written then
         the paths used in that description are in D *)
      let paths = Lid_trie.union paths md.md_discourse in
      begin
        match md.md_type with
        | Mty_alias p ->
          (* D12. If a module path m in D - note D not U - is a module alias
             with target n and another path p in D includes n within it, then
             the path obtained by substituting the m for n in p is also in D.

             We accumulate such substitution and will apply them when shortening
             a path. *)
          (* We have to follow aliases to be able to add module components to
             the discourse.

             TODO now that we have md_discourse_aliases, this might be redundant
             ? *)
          let path' = Env.normalize_module_path None env p in
          (* TODO: I've removed it but ... ? *)
          let u_next =
            U.use_module env
              { Location.txt = lid; loc = Location.none }
              (* TODO: sort the location issue *)
              path' u_next
            (* add_path_to_discourse env { paths; substs } Module lid path'  *)
          in
          (* TODO: refactor that with [add_substs] *)
          let substs =
            log ~title:"add_path_to_discourse" "New substitution 1 %a -> %a"
              Logger.fmt
              (Fun.flip Path.print path')
              Logger.fmt
              (Fun.flip Pprintast.longident lid);
            Path.Map.update path'
              (function
                | None -> Some (Lid_set.singleton lid)
                | Some lids -> Some (Lid_set.add lid lids))
              substs
          in
          ((paths, substs), u_next)
        | Mty_signature sig_ ->
          (* D3. If a module path is in U then all the paths of its subcomponents
             are in D *)
          (d3_rule env lid path paths substs sig_, u_next)
        | _ -> ((paths, substs), u_next)
      end
    in
    ({ paths; substs }, u_next)

  let consequences d u_next (longident, { U.item = kind, path; env }) =
    match (kind, env) with
    | Module_type, Some env ->
      let mtd = Env.find_modtype_lazy path env in
      (* D8. If a module type path is in U then any paths used in its definition
         are in *)
      ({ d with paths = Lid_trie.union d.paths mtd.mtd_discourse }, u_next)
    | Module, Some env -> module_consequences d u_next env longident path
    | Value, Some env ->
      (* D4. If a value path is in U and its value description was written by a user -
         as opposed to being inferred - then the paths used in that description are
         in D. *)
      let vd = Env.find_value path env in
      ({ d with paths = Lid_trie.union d.paths vd.val_discourse }, u_next)
    | Type, Some env ->
      (* D6. If a type path is in U then any paths used in its equation or
         representation are in D. *)
      let td = Env.find_type path env in
      ({ d with paths = Lid_trie.union d.paths td.type_discourse }, u_next)
    | _ -> (d, u_next)

  let add_from_u_to_d :
      discourse -> U.u -> Longident.t * U.u_item -> discourse * U.u =
   fun d u_next ((longident, item) as input) ->
    let d = { d with paths = Lid_trie.add longident item.item d.paths } in
    consequences d u_next input

  let of_U u =
    let is_empty u = Lid_map.is_empty u.U.u_paths in
    let rec add_u_to_d d u =
      let d, next_u =
        Lid_map.to_seq u.U.u_paths
        |> Seq.fold_left
             (fun (d, u_next) (lid, (x : U.ItemSet.t)) ->
               U.ItemSet.fold
                 (fun item (d, u_next) -> add_from_u_to_d d u_next (lid, item))
                 x (d, u_next))
             (d, U.empty_u)
      in
      let d =
        { d with substs = Path.Map.union_merge Lid_set.union d.substs u.substs }
      in
      if is_empty next_u then d else add_u_to_d d next_u
    in
    add_u_to_d
      { paths = Lid_trie.empty; substs = (* u.U.substs *) Path.Map.empty }
      u
end

include U

let use_module env lid path = g := add_used env Module lid path !g
let use_modtype env lid path = g := add_used env Module_type lid path !g
let use_type env lid path = g := add_used env Type lid path !g
let use_value env lid path = g := add_used env Value lid path !g

let get () = D.of_U !g

(* (\* This might not be necessary if we have a clearer two-step process ? *)
(*    Currently the handling of aliases can create loops. *\) *)
(* let already_used : (Path.t, unit) Hashtbl.t = Hashtbl.create 256 *)

(* open U *)

(* (\** [add_path_to_discourse] adds one path from U to the Discourse, eventually *)
(*     adding the additionnal paths described by the rules for D. TODO this could *)
(*     and probably should be done lazily. *)

(*     TODO:Q what about rule D11 ? If a path is in D and it includes another module *)
(*           path within it, then that module path is also in D. Should we consider *)
(*           only [Papply] paths or all path components for addition to D ?  *\) *)
(* let rec add_path_to_discourse ?(for_open = false) env discourse kind lid path = *)
(*   (\* let log = log ~title:"add_path_to_discourse" in *\) *)
(*   log ~title:"add_path_to_discourse" "Adding %s %a %a" *)
(*     (Shape.Sig_component_kind.to_string kind) *)
(*     Logger.fmt *)
(*     (fun fmt -> Pprintast.longident fmt lid) *)
(*     Logger.fmt *)
(*     (fun fmt -> Path.print fmt path); *)
(*   let paths = Lid_trie.add lid (kind, path) discourse.paths in *)
(*   let paths, substs = *)
(*     let substs = discourse.substs in *)
(*     match kind with *)
(*     | Module -> *)
(*       (\* TODO This should probably be done lazily *\) *)
(*       let md = Env.find_module_lazy path env in *)
(*       let { paths; substs } = *)
(*         match md.md_discourse_alias with *)
(*         | None -> { paths; substs } *)
(*         | Some (alias_lid, (_, alias_path)) -> begin *)
(*           try *)
(*             let path', _ = Env.find_module_by_name_lazy alias_lid.txt env in *)
(*             log ~title:"add_path_to_discourse" "Adding alias: %a %a %a" *)
(*               Logger.fmt *)
(*               (Fun.flip Pprintast.longident alias_lid.txt) *)
(*               Logger.fmt *)
(*               (Fun.flip Path.print alias_path) *)
(*               Logger.fmt *)
(*               (Fun.flip Path.print path'); *)

(*             let substs = *)
(*               log ~title:"add_path_to_discourse" *)
(*                 "New substitution 1' %a -> %a (%a)" Logger.fmt *)
(*                 (Fun.flip Path.print path) Logger.fmt *)
(*                 (Fun.flip Pprintast.longident alias_lid.txt) *)
(*                 Logger.fmt *)
(*                 (Fun.flip Location.print_loc alias_lid.loc); *)
(*               Path.Map.update path *)
(*                 (function *)
(*                   | None -> Some (Lid_set.singleton alias_lid.txt) *)
(*                   | Some lids -> Some (Lid_set.add alias_lid.txt lids)) *)
(*                 substs *)
(*             in *)
(*             if Hashtbl.mem already_used path' then { paths; substs } *)
(*             else begin *)
(*               Hashtbl.add already_used path' (); *)
(*               add_used env Module alias_lid path' { paths; substs } *)
(*             end *)
(*           with Not_found -> { paths; substs } *)
(*         end *)
(*       in *)
(*       (\* D5. If a module path is in U and its module description was written then *)
(*          the paths used in that description are in D *\) *)
(*       let paths = Lid_trie.union paths md.md_discourse in *)
(*       begin *)
(*         match md.md_type with *)
(*         | Mty_alias p -> *)
(*           (\* D12. If a module path m in D - note D not U - is a module alias *)
(*              with target n and another path p in D includes n within it, then *)
(*              the path obtained by substituting the m for n in p is also in D. *)

(*              We accumulate such substitution and will apply them when shortening *)
(*              a path. *\) *)
(*           (\* We have to follow aliases to be able to add module components to *)
(*              the discourse. *)

(*              TODO now that we have md_discourse_aliases, this might be redundant *)
(*              ? *\) *)
(*           let path' = Env.normalize_module_path None env p in *)
(*           let { paths; substs } = *)
(*             add_path_to_discourse env { paths; substs } Module lid path' *)
(*           in *)
(*           let substs = *)
(*             log ~title:"add_path_to_discourse" "New substitution 1 %a -> %a" *)
(*               Logger.fmt *)
(*               (Fun.flip Path.print path') *)
(*               Logger.fmt *)
(*               (Fun.flip Pprintast.longident lid); *)
(*             Path.Map.update path' *)
(*               (function *)
(*                 | None -> Some (Lid_set.singleton lid) *)
(*                 | Some lids -> Some (Lid_set.add lid lids)) *)
(*               substs *)
(*           in *)
(*           (paths, substs) *)
(*         | Mty_signature s -> *)
(*           let ldot id = *)
(*             if for_open then lid else Longident.Ldot (lid, Ident.name id) *)
(*           in *)
(*           let pdot id = Path.Pdot (path, Ident.name id) in *)
(*           (\* D3. If a module path is in U then all the paths of its subcomponents *)
(*              are in D *\) *)
(*           List.fold_left *)
(*             (fun (paths, substs) -> *)
(*               let add kind id = *)
(*                 log ~title:"add_path_to_discourse" *)
(*                   "Adding signature component %s %a (%a)" *)
(*                   (Shape.Sig_component_kind.to_string kind) *)
(*                   Logger.fmt *)
(*                   (fun fmt -> Ident.print fmt id) *)
(*                   Logger.fmt *)
(*                   (Fun.flip Path.print (pdot id)); *)
(*                 Lid_trie.add (ldot id) (kind, pdot id) paths *)
(*               in *)
(*               function *)
(*               | Subst.Lazy.Sig_value (id, _, _) -> (add Value id, substs) *)
(*               | Subst.Lazy.Sig_type (id, _, _, _) -> (add Type id, substs) *)
(*               | Subst.Lazy.Sig_typext (id, _, _, _) -> *)
(*                 (add Extension_constructor id, substs) *)
(*               | Subst.Lazy.Sig_module (id, _, _, _, _) -> *)
(*                 let md = Env.find_module_lazy (pdot id) env in *)
(*                 let paths = add Module id in *)
(*                 let substs = *)
(*                   match md.md_type with *)
(*                   | Mty_alias path' -> *)
(*                     let lid = ldot id in *)
(*                     log ~title:"add_path_to_discourse" *)
(*                       "New substitution 2 %a -> %a" Logger.fmt *)
(*                       (Fun.flip Path.print path') *)
(*                       Logger.fmt *)
(*                       (Fun.flip Pprintast.longident lid); *)
(*                     Path.Map.update path' *)
(*                       (function *)
(*                         | None -> Some (Lid_set.singleton lid) *)
(*                         | Some lids -> Some (Lid_set.add lid lids)) *)
(*                       substs *)
(*                   | _ -> substs *)
(*                 in *)
(*                 (paths, substs) *)
(*               | Subst.Lazy.Sig_modtype (id, _, _) -> (add Module_type id, substs) *)
(*               | Subst.Lazy.Sig_class (id, _, _, _) -> (add Class id, substs) *)
(*               | Subst.Lazy.Sig_class_type (id, _, _, _) -> *)
(*                 (add Class_type id, substs)) *)
(*             (paths, substs) *)
(*             (Subst.Lazy.force_signature_once s) *)
(*         | _ -> (paths, substs) *)
(*       end *)
(*     | Module_type -> *)
(*       let mtd = Env.find_modtype_lazy path env in *)
(*       (\* D8. If a module type path is in U then any paths used in its definition *)
(*          are in *\) *)
(*       (Lid_trie.union paths mtd.mtd_discourse, substs) *)
(*     | Value -> *)
(*       (\* D4. If a value path is in U and its value description was written by a user - *)
(*          as opposed to being inferred - then the paths used in that description are *)
(*          in D. *\) *)
(*       let vd = Env.find_value path env in *)
(*       (Lid_trie.union paths vd.val_discourse, substs) *)
(*     | Type -> *)
(*       (\* D6. If a type path is in U then any paths used in its equation or *)
(*          representation are in D. *\) *)
(*       let td = Env.find_type path env in *)
(*       (Lid_trie.union paths td.type_discourse, substs) *)
(*     | _ -> (paths, substs) *)
(*   in *)
(*   { paths; substs } *)

(* (\** [add_used] adds all parts of a used path to the Discourse (U1, D2) *\) *)
(* and add_used env kind lid path t = *)
(*   let loc = lid.Location.loc in *)
(*   let f acc kind (lid, path) = *)
(*     let () = log_usage ~loc kind path in *)
(*     try add_path_to_discourse env acc kind lid path *)
(*     with Not_found | Env.Error (Lookup_error _) -> acc *)
(*   in *)
(*   fold_on_common_lid_and_path_segments ~init:t ~kind ~f (lid.txt, path) *)

(* let add_used env kind lid path = *)
(*   if record_usages then g := add_used env kind lid path !g *)

(* (\* Rule U1: Any path occurring in the file is in U *\) *)
(* let use_module env lid path = add_used env Module lid path *)
(* let use_modtype env lid path = add_used env Module_type lid path *)
(* let use_type env lid path = add_used env Type lid path *)
(* let use_value env lid path = add_used env Value lid path *)

let use_constructor _env (_constr : Types.constructor_description) =
  (* if record_usages then begin *)
  (*   (\* If a constructor is in U then any paths used in its type are in D. *\) *)
  (*   g := { !g with paths = Lid_trie.union !g.paths constr.cstr_discourse } *)
  (* end *)
  ()
(* TODO *)

let use_label _env (_label : _ Types.gen_label_description) =
  if record_usages then begin
    (* If a label is in U then any paths used in its type are in D. *)
    let label_discourse =
      Lid_map.empty
      (* let trie = label.lbl_discourse in *)
      (* let seq = Lid_trie.to_seq trie in *)
      (* Seq.fold_left (fun map (lid, paths) -> Lid_map.add lid paths map) Lid_map.empty seq *)
    in
    g :=
      { !g with
        u_paths = Lid_map.union (fun _ x _ -> Some x) !g.u_paths label_discourse
      }
  end
