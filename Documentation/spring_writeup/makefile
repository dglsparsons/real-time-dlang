# Makefile 

all: 
	pdflatex --enable-write18 writeup.tex
	bibtex writeup.aux
	pdflatex --enable-write18 writeup.tex
	pdflatex --enable-write18 writeup.tex
	pdflatex --enable-write18 writeup.tex

clean: 
	rm -fv *.aux *.blg *.out *.bbl *.log *.toc *.lot writeup.pdf *.sum *.sum2

view: 
	zathura writeup.pdf&

spell: 
	ispell *.tex

cb: 
	cp writeup.pdf ~/Downloads/writeup.pdf

count: 
	texcount *.tex -total | grep "Words in" 
	detex writeup.tex | wc -w

cbs: 
	make clean && make && make cb
