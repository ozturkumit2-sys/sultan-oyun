extends Node
## Rasterizes SVG files with Godot's own importer (ThorVG) for previewing generated art.
## args: <res dir> <out abs dir> [scale]

func run(args: Array) -> void:
	var dir: String = args[0]
	var out: String = args[1]
	var sc := float(args[2]) if args.size() > 2 else 1.0
	DirAccess.make_dir_recursive_absolute(out)
	var n := 0
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".svg"):
			continue
		var txt := FileAccess.get_file_as_string(dir.path_join(f))
		var img := Image.new()
		var err := img.load_svg_from_string(txt, sc)
		if err != OK:
			print("FAILED ", f)
			continue
		img.save_png(out.path_join(f.get_basename() + ".png"))
		n += 1
	print("rasterized ", n)
