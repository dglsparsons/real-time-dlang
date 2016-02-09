# Makefile 

all: 
	pdflatex writeup.tex
	bibtex writeup.aux
	pdflatex writeup.tex
	pdflatex writeup.tex

clean: 
	rm -fv *.aux *.blg *.out *.bbl *.log *.toc *.lot writeup.pdf

view: 
	google-chrome-stable writeup.pdf

spell: 
	ispell *.tex

cb: 
	cp writeup.pdf ~/Downloads/writeup.pdf

count: 
	texcount *.tex

