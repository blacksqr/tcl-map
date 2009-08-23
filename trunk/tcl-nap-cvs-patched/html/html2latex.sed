# <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
# <!-- saved from url=(0038)http://www.w3.org/Tools/html2latex.sed -->
# <HTML><HEAD>
# <META http-equiv=Content-Type content="text/html; charset=windows-1252">
# <META content="MSHTML 6.00.2900.2769" name=GENERATOR></HEAD>
# <BODY><PRE>

# delete contents
/^  <h3>Table of Contents<\/h3>/,/^  <\/[uo]l>$/d

# delete trailer
/<table width="100%" border="0"/,$d

/<meta /,/ \/>$/d
s;<!--;% ;g
s;-->;;g
t

# Following can appear within <pre> as well as elsewhere
s?&amp;?\\&?g
s?&quot;?"?g
s?&#39;?'?g

# <pre>, etc.
s;<listing>;<pre>;
s;</listing>;</pre>;
s;<xmp>;<pre>;
s;</xmp>;</pre>;
/<pre>/,/<\/pre>/b pre

# Stuff to ignore
s;<?xml .*?>;;
s;<!DOCTYPE .*">;;
s;<center>;;
s;</center>;;
s;<head>;;
s;</head>;;
s;<html>;;
s;</html>;;
s;<body>;;
s;</body>;;
s;<tbody>;;
s;</tbody>;;
s;<font[^>]*>;;g
s;</font[^>]*>;;g
s;<span[^>]*>;;g
s;</span[^>]*>;;g
s?<isindex>??
s?</address>??g
s?<nextid^>*>??g
s?<colgroup.*/colgroup>??g

# character set translations for LaTex special chars
s?\\?<backslash>?g
s?\$?\\$?g
s?{?\\{?g
s?}?\\}?g
s?%?\\%?g
s?_?\\_?g
s?~?$\\sim$?g
s?\^?\\^?g
s?&lt;?$<$?g
s?&gt;?$>$?g
s?&deg;?$^{\\circ}$?g
s?&#176;?$^{\\circ}$?g
s?°?$^{\\circ}$?g
s?&#160;?\\ ?g
s?&#931;?$\\sum$?g
s?&#960;?$\\pi$?g
s?&#8226;?$\\bullet$?g
s?&#8230;?$\\ldots$?g
s?&#8721;?$\\sum$?g
s?&#8722;?$-$?g
s?&#8730;?$\\sqrt$?g
s?&#8734;?$\\infty$?g
s?&#8800;?$\\neq$?g
s?&#8804;?$\\le$?g
s?&#8805;?$\\ge$?g
s?#?\\#?g
s?&?\\\&?g

# Paragraphs
s?<p>?\n\n?g
s?</p>??g

# Line breaks
s?<nobr>?\\mbox{?g
s?</nobr>?}?g

# Unwanted spaces
s/\[  */[/g

# "text"
s/^"\([<0-9a-zA-Z]\)/`\1/g
s/\([ (]\)"\([<0-9a-zA-Z]\)/\1`\2/g
s/\([>0-9a-zA-Z]\)"$/\1'/g
s/\([>0-9a-zA-Z]\)"\([ ).,:;?!]\)/\1'\2/g

# Headings
s?<title>?% ?g
s?</title>??g
s?<hn>?\\part{?g
s?</hn>?}?g
s?<h1>?\\chapter{?g
s?<h2>?\\section{?g
s?<h3>?\\subsection{?g
s?<h4>?\\subsubsection{?g
s?<h5>?\\subsubsection{?g
s?<h6>?\\paragraph{?g
s?<h7>?\\subparagraph{?g
s?</h[0-9]>?}\n?g

# list
s?<ol>?\\begin{enumerate}?g
s?</ol>?\\end{enumerate}?g
s?<ul>?\\begin{itemize}?g
s?</ul>?\\end{itemize}?g
s?<li>?\\item ?g
s?</li>??g
s?<dl>?\\begin{description}?g
s?</dl>?\\end{description}?g
s?<dt>?\\item[?g
s?</dt>?]?g
s?<dd>??g
s?</dd>??g

# table
s;<table[^>]*>;\\\\ \\par \\begin{tabular}{*{6}{|p{25 mm}}};g
s;</table[^>]*>;\\hline\n\\end{tabular} \\\\ \\par;g
s;<tr.*>;\\hline ;g
s;</tr>;\\\\;g
s;<th[^>]*>;\\textbf{;g
s;</th[^>]*>;} \& ;g
s;<td[^>]*>;;g
s;</td[^>]*>; \& ;g

# Other common SGML markup.  this is ad-hoc

# break (force new line)
s?<br[^>]*>?\\\\?g

# bold
s?<b>?\\textbf{?g
s?</b>?}?g

# italic
s?<i>?\\emph{?g
s?</i>?}?g
s?<em>?\\emph{?g
s?</em>?}?g
s?<cite>?\\emph{?g
s?</cite>?}?g

s?<var>?$?g
s?</var>?$?g

s?<code>?\\texttt{?g
s?</code>?}?g

# subscripts & superscripts
s?<sub>?$_{?g
s?</sub>?}$?g
s?<sup>?$^{?g
s?</sup>?}$?g

# Anchors
/<a name="/s/\\_/-/g
/<a href="/s/\\_/-/g
s?<a name="\([^"]*\)">?\\label{\1}?g
s?<a name="\([^"]*\)".*">?\\label{\1}?g
s?<a href="\\#\([^"]*\)">?\\ref{\1}?g
s?<a href="\([^"]*\)">\(.*\)</a>?\\href{\1}{\2}?g
s?</a>??g

s?<backslash>?$\\backslash$?g

# Finally try using same word
s?<\([a-z]*\)>?\\begin{\1}?g
s?</\([a-z]*\)>?\\end{\1}?g

# delete blank lines
/^ *$/d

# skip rest
b

# This is a subroutine in sed, in case you are not a sed guru
:pre
s?<pre>?\\begin{verbatim}?g
s?</pre>?\\end{verbatim}\n?
s?&gt;?>?g
s?&lt;?<?g
