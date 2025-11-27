{ lib }:
let
  inherit (lib)
    isList
    isString
    splitString
    filter
    concatStringsSep
    ;
in
rec {
  mkEntry =
    raw: prefix:
    let
      toLines =
        value:
        if isList value then
          # map each list item -> list-of-lines, then flatten
          builtins.concatLists (
            builtins.map (
              item:
              if isString item then
                splitString "\n" item
              else
                [
                  toString
                  item
                ]
            ) value
          )
        else if isString value then
          splitString "\n" value
        else
          [ ];

      lines = filter (l: l != "") (toLines raw);
      mapped = builtins.map (l: "${prefix}${l}\n") lines;
    in
    concatStringsSep "" mapped;

  mkComment = raw: mkEntry raw "! ";

  getAttrsKeyWithoutNullValues =
    c: if c == null then [ ] else builtins.attrNames (lib.filterAttrs (_: v: v != null) c);
}
