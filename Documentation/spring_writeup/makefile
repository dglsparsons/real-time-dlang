# Makefile 

all: 
	pdflatex --enable-write18 writeup.tex
	bibtex writeup.aux
	pdflatex --enable-write18 writeup.tex
	pdflatex --enable-write18 writeup.tex
	pdflatex --enable-write18 writeup.tex

clean: 
	rm -fv *.aux *.blg *.out *.bbl *.log *.toc *.lot *.sum *.sum2

view: 
	zathura writeup.pdf&

spell: 
	ispell *.tex

cb: 
	cp writeup.pdf ~/Downloads/writeup.pdf

count: 
	texcount *.tex ada_profile.adb exception_profile.d rtmutex.d -total | grep "Words in" | ./wc_tool2.d	

cbs: 
	make clean && make && make cb
