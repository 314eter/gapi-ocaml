module Operation =
struct
  type t =
      None
    | Query
    | Insert
    | Update
    | Delete

  let to_string operation =
    match operation with
        None -> ""
      | Query -> "query"
      | Insert -> "insert"
      | Update -> "update"
      | Delete -> "delete"

  let of_string operation =
    match operation with
        "" -> None
      | "query" -> Query
      | "insert" -> Insert
      | "update" -> Update
      | "delete" -> Delete
      | _ -> failwith ("Batch operation " ^ operation ^ " unsupported")

end

module Status =
struct
  type t = {
    code : int;
    reason : string;
    content_type : string;
    content : string
  }

	let code = {
		GapiLens.get = (fun x -> x.code);
		GapiLens.set = (fun v x -> { x with code = v })
	}
	let reason = {
		GapiLens.get = (fun x -> x.reason);
		GapiLens.set = (fun v x -> { x with reason = v })
	}
	let content_type = {
		GapiLens.get = (fun x -> x.content_type);
		GapiLens.set = (fun v x -> { x with content_type = v })
	}
	let content = {
		GapiLens.get = (fun x -> x.content);
		GapiLens.set = (fun v x -> { x with content = v })
	}

  let empty =  {
    code = 0;
    reason = "";
    content_type = "";
    content = ""
  }

  let to_xml_data_model status =
    GdataAtom.render_element GdataExtensions.ns_batch "status"
      [GdataAtom.render_int_attribute "" "code" status.code;
       GdataAtom.render_attribute "" "reason" status.reason;
       GdataAtom.render_attribute "" "content-type" status.content_type;
       GdataAtom.render_text status.content]

  let of_xml_data_model status tree =
    match tree with
        GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "code"; `Namespace ""],
           v) ->
          { status with code = int_of_string v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "reason"; `Namespace ""],
           v) ->
          { status with reason = v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "content-type"; `Namespace ""],
           v) ->
          { status with content_type = v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Text],
           v) ->
          { status with content = v }
      | e ->
          GdataUtils.unexpected e

end

module BatchExtensions =
struct
  type t = {
    id : string;
    operation : Operation.t;
    status : Status.t;
  }

	let id = {
		GapiLens.get = (fun x -> x.id);
		GapiLens.set = (fun v x -> { x with id = v })
	}
	let operation = {
		GapiLens.get = (fun x -> x.operation);
		GapiLens.set = (fun v x -> { x with operation = v })
	}
	let status = {
		GapiLens.get = (fun x -> x.status);
		GapiLens.set = (fun v x -> { x with status = v })
	}

  let empty = {
    id = "";
    operation = Operation.None;
    status = Status.empty;
  }

  let to_xml_data_model ext =
    List.concat
      [GdataAtom.render_text_element GdataExtensions.ns_batch "id" ext.id;
       GdataAtom.render_text_element GdataExtensions.ns_batch "operation" (Operation.to_string ext.operation);
       Status.to_xml_data_model ext.status]

  let of_xml_data_model ext tree =
    match tree with
        GapiCore.AnnotatedTree.Node
          ([`Element; `Name "id"; `Namespace ns],
           [GapiCore.AnnotatedTree.Leaf
              ([`Text], v)]) when ns = GdataExtensions.ns_batch ->
          { ext with id = v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "operation"; `Namespace ns],
           [GapiCore.AnnotatedTree.Leaf
              ([`Text], v)]) when ns = GdataExtensions.ns_batch ->
          { ext with operation = Operation.of_string v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "status"; `Namespace ns],
           cs) when ns = GdataExtensions.ns_batch ->
          GdataAtom.parse_children
            Status.of_xml_data_model
            Status.empty
            (fun status -> { ext with status })
            cs
      | e ->
          GdataUtils.unexpected e

end
