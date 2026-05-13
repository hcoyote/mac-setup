
function D {

customer=${1:-all}
day=$2


tmpdirectory=${HOME}/tmp
custdirectory=${tmpdirectory}/${customer}

case $day in
  latest|last)
	date=$(ls -1 ${custdirectory}/ | tail -1)
        ;;
  *)
	date=$(date +%Y-%m-%d)
	;;
esac


datedirectory=${custdirectory}/${date}

if [[ ! -d ${datedirectory} ]] ; then
	mkdir -p ${datedirectory}
fi

cd ${datedirectory}

}

function Dls {
  ls ${HOME}/tmp/${1}
}

function _Dls {
  local -a dirs
  dirs=(${HOME}/tmp/*(N/:t))
  _describe 'directory' dirs
}
compdef _Dls Dls
