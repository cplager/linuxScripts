
alias noRestart="net stop \"automatic updates\""
alias newe="/home/cplager/junk/emacs/emacs/src/emacs.exe"
alias bgm="b;gm; b"
alias bn="backup.py"
alias bnc='bn *.cc *.h *.hh *.C *.c'
alias chdir="\cd"
alias cd-="cd -"
alias cd..="cd .."
alias cgr="cgr.pl"
alias cl="clear"
alias dvipsl="dvips -P pdf -O 0.7in,-0.32in -t landscape"
alias enw="emacs -nw"
alias f="finger" 
alias gm="blankspace; make"
alias gr="grep -i -n"
alias h="history"
alias hgr="history | grep -i "
alias ki="kill -9"
alias kn="kinit -n -l 100d"
alias l="ls -CF"
alias la="ls -aCF"
alias latex="perl ~cplager/scripts/updateTexVersion;latex"
alias llatex="perl ~cplager/scripts/updateTexVersion;c:/Program\ Files/texmf/miktex/bin/latex.exe"
alias latexx="c:/Program\ Files/texmf/miktex/bin/latex.exe"
alias ldir="perl ~cplager/scripts/ldir"
alias ll="ls -lF"
alias lla="ls -alF"
alias tolog="moveFiles.py"
alias lrt="ls -CFrt"
alias llrt="ls -lrtF"
alias mine="~cplager/scripts/minehunt -w30 -h24 -m200 -z18&"
alias mo="less"
alias move="~/bin/moveFiles.py"
alias prnt="prntSGI"
alias pr2="prnt -a2col"
alias pr2c="prnt -a2col -rcpap -col"
alias pr3c="prnt -a3col -rcpap -col"
alias pr2w="prnt -a2colw"
alias pr3="prnt -a3col"
alias purge="rrm *~ *.bak"
alias rl="blankspace; root -l"
alias rlq="blankspace; root -l -b -q"
alias rlqt="blankspace; time root -l -b -q"
alias rm="rm -i"
alias rrm="\rm"
alias startWebServer="~/scripts/WebServer/webserver.py > ~/scripts/WebServer/logfile.log 2>&1&"
alias t2ps="/home/cplager/bin/print/text2ps"
alias traceroute="tracert"
alias tsh="trampstring.pl -hobo"
alias view="cygstart.exe"

function e () {
	/usr/bin/emacs $@ &
}

function gmb () {
	blankspace;make BASE=$@ 
}

function disp () {
	display.exe $@ &
}

function ggr() {
	grGui $@ &
}

function gv () {
	export myvar=`~cplager/scripts/cleanDir $1`
	/mount/programfiles/Ghostview/gsview/gsview32.exe $myvar &
}

##  function acro () {
##  	export myvar=`~cplager/scripts/cleanDir $1`
##  	/mount/programfiles/Adobe/Acrobat\ 5.0/Acrobat/acrobat.exe $myvar &
##  }

function explore () {
	export myvar=`~cplager/scripts/cleanDir $1`
	c:/windows/explorer.exe $myvar &
}

function ss() {
	export temp=$*
	ssh -X `~/scripts/sshCompletion.pl $temp`
	mrxvt_options.pl "Local"
}

function sss() {
	export temp=$*
	`~/scripts/sshCompletion_v2.pl $temp`
	mrxvt_options.pl "Local"
}

function tarcode () {
	tar -czvf $@.tgz  --exclude \*~ --exclude \*.o --exclude \*.exe  --exclude \*.d --exclude \*.dll --exclude \*.root --exclude \*.\*ps --exclude \*.gif --exclude \*.tgz --exclude \*root.\? *
}

. scripts/dirstack/aliases.bash
