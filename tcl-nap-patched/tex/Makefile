# Makefile --
#
# Copyright (c) 2005, CSIRO Australia
#
# Author: Harvey Davies, CSIRO Marine and Atmospheric Research
#
# RCS: @(#) $Id: Makefile,v 1.16 2006/10/27 06:20:48 dav480 Exp $

MAIN = nap_users_guide

VP = vpdf
LATEX2PDF = pdflatex -interaction batchmode
RM = rm -f

COMMON = \
	common.tex \
	env.tex \

NAP_TEX_FILES = \
	ack.tex \
	array.tex \
	bin_io.tex \
	caps_nap_menu.tex \
	choose_file.tex \
	const.tex \
	data_type.tex \
	date_function.tex \
	date_proc.tex \
	demo_arith.tex \
	demo_constant.tex \
	demo_construct.tex \
	demo_define_function.tex \
	demo_functions.tex \
	demo_indexing.tex \
	demo_intro.tex \
	demo_io.tex \
	demo_linear.tex \
	demo_ooc.tex \
	demo_simple.tex \
	demo_stat.tex \
	function.tex \
	geog.tex \
	geog_proc.tex \
	grid.tex \
	gui_intro.tex \
	hdf.tex \
	hdf_netcdf.tex \
	indexing.tex \
	install.tex \
	land_flag.tex \
	lib_function_intro.tex \
	lib_proc_intro.tex \
	make_dll.tex \
	misc_proc.tex \
	model.tex \
	nao.tex \
	nao_ooc.tex \
	nap_args.tex \
	nap_cmd.tex \
	nap_function_lib.tex \
	nap_get.tex \
	nap_info.tex \
	nap_version.tex \
	ooc.tex \
	ooc_data.tex \
	ooc_meta.tex \
	ooc_modify.tex \
	ooc_write.tex \
	op.tex \
	overview.tex \
	photo.tex \
	plot_nao.tex \
	projection.tex \
	refs.tex \
	sample.tex \
	scripts.tex \
	stat.tex \
	syntax.tex \
	tcl_log.tex \
	term.tex \
	title_pages.tex \
	typo.tex \
	writing_procs.tex \
	$(MAIN).tex

.SUFFIXES: .tex .pdf .ps

.tex:
	$(MAKE) $(*F).pdf
	- $(VP) $(*F).pdf

.tex.pdf:
	$(LATEX2PDF) $<
	$(LATEX2PDF) $<

view: $(MAIN).pdf
	- $(VP) $(MAIN).pdf

all: $(MAIN).pdf help_caps_nap_menu.pdf help_choose_file.pdf help_hdf.pdf help_plot_nao.pdf

$(MAIN).pdf: $(NAP_TEX_FILES) $(COMMON) 20050921_CSIRO_logo_RGB_colour_small.png screen.png
	- $(LATEX2PDF) $(MAIN).tex
	- $(LATEX2PDF) $(MAIN).tex

help_caps_nap_menu.pdf: help_caps_nap_menu.tex caps_nap_menu.tex $(COMMON)
	- $(LATEX2PDF) help_caps_nap_menu.tex
	- $(LATEX2PDF) help_caps_nap_menu.tex

help_choose_file.pdf: help_choose_file.tex choose_file.tex $(COMMON)
	- $(LATEX2PDF) help_choose_file.tex
	- $(LATEX2PDF) help_choose_file.tex

help_hdf.pdf: help_hdf.tex hdf.tex $(COMMON)
	- $(LATEX2PDF) help_hdf.tex
	- $(LATEX2PDF) help_hdf.tex

help_plot_nao.pdf: help_plot_nao.tex plot_nao.tex $(COMMON)
	- $(LATEX2PDF) help_plot_nao.tex
	- $(LATEX2PDF) help_plot_nao.tex

clean:
	$(RM) *.aux *.log *.out *.pdf *.toc
