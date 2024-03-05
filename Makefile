docs:
	asciidoctor README.adoc -o ./docs/README.html

lint:
	# https://github.com/sbdchd/squawk
	squawk ./init.aql
