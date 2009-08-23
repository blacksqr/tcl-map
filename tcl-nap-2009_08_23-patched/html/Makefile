# Makefile --
#
# Copyright (c) 2005, CSIRO Australia
#
# Author: Harvey Davies, CSIRO Marine and Atmospheric Research
#
# RCS: @(#) $Id: Makefile,v 1.7 2006/02/10 12:50:20 dav480 Exp $

VP = vpdf
LATEX2PDF = pdflatex -interaction batchmode
RM = rm -f

.SUFFIXES: .html .tex .pdf .ps

.tex:
	$(MAKE) $(*F).pdf
	- $(VP) $(*F).pdf

.html:
	$(MAKE) $(*F).pdf
	- $(VP) $(*F).pdf

.html.pdf:
	$(MAKE) $(*F).tex
	$(MAKE) $(*F).pdf

.html.tex:
	sed -f html2latex.sed $< > $@

.tex.pdf:
	$(RM) $*.aux $*.log $*.out
	$(LATEX2PDF) $<
	$(LATEX2PDF) $<

HTML_FILES = \
    ack.html \
    array.html \
    bin_io.html \
    caps_nap_menu.html \
    choose_file.html \
    const.html \
    data_type.html \
    date_function.html \
    date_proc.html \
    demo_arith.html \
    demo_constant.html \
    demo_construct.html \
    demo_define_function.html \
    demo_functions.html \
    demo_indexing.html \
    demo_intro.html \
    demo_io.html \
    demo_linear.html \
    demo_ooc.html \
    demo_simple.html \
    demo_stat.html \
    function.html \
    geog.html \
    geog_proc.html \
    grid.html \
    hdf.html \
    indexing.html \
    install.html \
    land_flag.html \
    make_dll.html \
    model.html \
    nao.html \
    nao_ooc.html \
    nap_args.html \
    nap_cmd.html \
    nap_function_lib.html \
    nap_get.html \
    nap_info.html \
    ooc.html \
    ooc_data.html \
    ooc_meta.html \
    ooc_modify.html \
    ooc_write.html \
    op.html \
    overview.html \
    photo.html \
    plot_nao.html \
    projection.html \
    refs.html \
    sample.html \
    scripts.html \
    stat.html \
    syntax.html \
    tcl_log.html \
    term.html \
    typo.html \
    writing_procs.html \

TEX_FILES = ${HTML_FILES:.html=.tex}

all: nap.pdf
	- $(VP) nap.pdf

nap.pdf: nap.tex $(TEX_FILES)
	$(RM) nap.aux nap.log nap.out
	- $(LATEX2PDF) nap.tex
	- $(LATEX2PDF) nap.tex

clean:
	rm -f $(TEX_FILES) $(PDF_FILES)
