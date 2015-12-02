#!/bin/bash
rm article.pdf
pdflatex article.tex
bibtex article.aux
pdflatex article.tex
pdflatex article.tex

