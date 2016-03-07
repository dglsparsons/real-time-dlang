# Makefile 

all: 
	pdflatex writeup.tex
	bibtex writeup.aux
	pdflatex writeup.tex
	pdflatex writeup.tex
	pdflatex writeup.tex

clean: 
	rm -fv *.aux *.blg *.out *.bbl *.log *.toc *.lot writeup.pdf

view: 
	okular writeup.pdf&

spell: 
	ispell *.tex

cb: 
	cp writeup.pdf ~/Downloads/writeup.pdf

count: 
	texcount *.tex | grep "Words in text: " | grep -E "[0-9]{5}"
	detex writeup.tex | wc -w

cbs: 
	make clean && make && make cb
