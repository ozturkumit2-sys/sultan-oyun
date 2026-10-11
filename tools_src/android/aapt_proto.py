"""aapt2 proto biçimindeki AndroidManifest.xml (aapt.pb.XmlNode) için asgari şema.
Tanımlanmayan alanlar bilinmeyen alan olarak korunur ve aynen yeniden yazılır.
Kaynak: AOSP frameworks/base/tools/aapt2/Resources.proto (yalnızca gereken alt küme)."""
from google.protobuf import descriptor_pb2, descriptor_pool, message_factory

F = descriptor_pb2.FieldDescriptorProto


def _msg(fdp, name, fields, oneofs=()):
    m = fdp.message_type.add()
    m.name = name
    for o in oneofs:
        m.oneof_decl.add().name = o
    for (fname, num, ftype, label, tname, oneof) in fields:
        f = m.field.add()
        f.name, f.number, f.type, f.label = fname, num, ftype, label
        if tname:
            f.type_name = ".aapt.pb." + tname
        if oneof is not None:
            f.oneof_index = oneof
    return m


def build():
    fdp = descriptor_pb2.FileDescriptorProto()
    fdp.name = "fusechef_aapt_subset.proto"
    fdp.package = "aapt.pb"
    fdp.syntax = "proto3"
    O, R = F.LABEL_OPTIONAL, F.LABEL_REPEATED
    _msg(fdp, "SourcePosition", [("line_number", 1, F.TYPE_UINT32, O, None, None), ("column_number", 2, F.TYPE_UINT32, O, None, None)])
    _msg(fdp, "String", [("value", 1, F.TYPE_STRING, O, None, None)])
    _msg(fdp, "Primitive", [("int_decimal_value", 6, F.TYPE_INT32, O, None, 0), ("boolean_value", 8, F.TYPE_BOOL, O, None, 0)], ["oneof_value"])
    _msg(fdp, "Item", [("str", 2, F.TYPE_MESSAGE, O, "String", 0), ("prim", 7, F.TYPE_MESSAGE, O, "Primitive", 0)], ["value"])
    _msg(fdp, "XmlNamespace", [("prefix", 1, F.TYPE_STRING, O, None, None), ("uri", 2, F.TYPE_STRING, O, None, None),
                               ("source", 3, F.TYPE_MESSAGE, O, "SourcePosition", None)])
    _msg(fdp, "XmlAttribute", [("namespace_uri", 1, F.TYPE_STRING, O, None, None), ("name", 2, F.TYPE_STRING, O, None, None),
                               ("value", 3, F.TYPE_STRING, O, None, None), ("source", 4, F.TYPE_MESSAGE, O, "SourcePosition", None),
                               ("resource_id", 5, F.TYPE_UINT32, O, None, None), ("compiled_item", 6, F.TYPE_MESSAGE, O, "Item", None)])
    _msg(fdp, "XmlElement", [("namespace_declaration", 1, F.TYPE_MESSAGE, R, "XmlNamespace", None),
                             ("namespace_uri", 2, F.TYPE_STRING, O, None, None), ("name", 3, F.TYPE_STRING, O, None, None),
                             ("attribute", 4, F.TYPE_MESSAGE, R, "XmlAttribute", None), ("child", 5, F.TYPE_MESSAGE, R, "XmlNode", None)])
    _msg(fdp, "XmlNode", [("element", 1, F.TYPE_MESSAGE, O, "XmlElement", 0), ("text", 2, F.TYPE_STRING, O, None, 0),
                          ("source", 3, F.TYPE_MESSAGE, O, "SourcePosition", None)], ["node"])
    pool = descriptor_pool.DescriptorPool()
    pool.Add(fdp)
    return message_factory.GetMessageClass(pool.FindMessageTypeByName("aapt.pb.XmlNode"))


XmlNode = build()
ANDROID_NS = "http://schemas.android.com/apk/res/android"


def walk(node, path=()):
    """(eleman, yol) çiftlerini derinlik öncelikli verir."""
    if node.WhichOneof("node") != "element":
        return
    el = node.element
    p = path + (el.name,)
    yield el, p
    for c in el.child:
        yield from walk(c, p)


def attr(el, name, ns=ANDROID_NS):
    for a in el.attribute:
        if a.name == name and a.namespace_uri == ns:
            return a
    return None
