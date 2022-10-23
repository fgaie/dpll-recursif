ARCHIVE_NAME="58-gaie"

dpll: dpll.ml dimacs.ml
	ocamlfind ocamlopt -o dpll -package str -linkpkg dimacs.ml dpll.ml

pack:
	mkdir ${ARCHIVE_NAME}
	cp dpll.ml dimacs.ml Makefile RENDU ${ARCHIVE_NAME}
	zip ${ARCHIVE_NAME} -mr ${ARCHIVE_NAME}

clean:
	rm -f *.cmi *.cmx *.o dpll

